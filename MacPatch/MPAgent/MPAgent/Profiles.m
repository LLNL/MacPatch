//
//  Profiles.m
/*
 Copyright (c) 2013, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.

 This file is part of MacPatch, a program for installing and patching
 software.

 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.

 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.

 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import "Profiles.h"
#import "MPAgent.h"
#import "MPDefaultsWatcher.h"

static NSString *kMPProfilesData = @"Data/gov.llnl.mp.custom.profiles.plist";

@interface Profiles (Private)

- (void)scanAndInstallPofiles;
- (NSArray *)retrieveProfileIDData:(NSError **)aErr;
- (NSArray *)readLocalProfileData;
- (NSArray *)readMPInstalledProfileData;
- (NSString *)writeProfileToDisk:(NSString *)aData;
- (BOOL)installProfile:(NSString *)aProfilePath;
- (BOOL)removeProfile:(NSString *)aProfileIdentifier;
- (void)recordProfileInstallToDisk:(NSDictionary *)aProfile;

@end


@implementation Profiles

@synthesize isExecuting;
@synthesize isFinished;

- (id)init
{
	if ((self = [super init])) {
		isExecuting = NO;
        isFinished  = NO;
		si	= [MPAgent sharedInstance];
		fm	= [NSFileManager defaultManager];
	}

	return self;
}


- (BOOL) isConcurrent
{
    return YES;
}

- (void)cancel
{
    [self finish];
}

- (void)finish
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start
{
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
    } else {
        [self willChangeValueForKey:@"isExecuting"];
		[self performSelectorInBackground:@selector(main) withObject:nil];
        isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)main
{
	@try {
		[self scanAndInstallPofiles];
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"[NSException]: %@",e);
	}
	[self finish];
}

- (void)scanAndInstallPofiles
{
	@autoreleasepool
    {
        NSError *err = nil;
        NSArray *profiles = [self retrieveProfileIDData:&err];
        if (err) {
            qlerror(@"Error: %@",err.localizedDescription);
            return;
        }
        if (!profiles) {
            qlinfo(@"No profile data.");
            return;
        }
        NSMutableArray *profileIdentities = [[NSMutableArray alloc] init];
        NSMutableArray *profilesToRemove = [[NSMutableArray alloc] init];
        NSArray *installedProfiles = [self readMPInstalledProfileData];

        // Install Profiles
        for (NSDictionary *p in profiles)
        {
            if ([p objectForKey:@"data"]) {
                NSString *profileOnDisk = [self writeProfileToDisk:[p objectForKey:@"data"]];
                if (!profileOnDisk) {
                    qlerror(@"Error, unable to install profile %@",[p objectForKey:@"profileIdentifier"]);
                }
                if ([self installProfile:profileOnDisk]) {
                    qlerror(@"Error, install profile %@ failed.",[p objectForKey:@"profileIdentifier"]);
                } else {
                    qlinfo(@"Profile, %@ was installed.",[p objectForKey:@"profileIdentifier"]);
                    [fm removeItemAtPath:profileOnDisk error:NULL];
                    [self recordProfileInstallToDisk:p];
                }
            }
        }
        // Build Profiles to Remove Array
        for (NSDictionary *rp in profiles)
        {
            if ([rp objectForKey:@"profileIdentifier"]) {
                [profileIdentities addObject:[rp objectForKey:@"profileIdentifier"]];
            }
        }
        [profilesToRemove addObjectsFromArray:installedProfiles];
        [profilesToRemove removeObjectsInArray:profileIdentities];
        qldebug(@"Profiles to remove %@",profilesToRemove);

        // Remove Old Profiles
        for (NSString *profileID in profilesToRemove)
        {
            if ([self removeProfile:profileID]) {
                qlinfo(@"Profile %@ was removed.",profileID);
            } else {
                qlerror(@"Error, profile %@ was not removed.",profileID);
            }
        }
        // Refresh MCX
        NSArray *cmdArgs = [NSArray arrayWithObjects:@"-n",@"root", nil];
        [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/mcxrefresh" arguments:cmdArgs] waitUntilExit];
    }
}

- (NSArray *)retrieveProfileIDData:(NSError **)err
{
    NSArray *result = nil;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    NSError *error = nil;
    result = [mpws getProfileIDDataForClient:&error];
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (NSArray *)readLocalProfileData
{
    NSString *fileName = [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"plist"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];

    // Write Profile Data To Plist
    NSArray *cmdArgs = [NSArray arrayWithObjects:@"-P",@"-o",filePath, nil];
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/profiles" arguments:cmdArgs] waitUntilExit];

    if (![fm fileExistsAtPath:filePath]) {
        return nil;
    }

    NSDictionary *profileDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    NSMutableArray *profileIDs = [[NSMutableArray alloc] init];

    if ([profileDict objectForKey:@"_computerlevel"])
    {
        for (NSDictionary *p in [profileDict objectForKey:@"_computerlevel"])
        {
            [profileIDs addObject:[p objectForKey:@"ProfileIdentifier"]];
        }
    } else {
        return nil;
    }
    // Quick Clean Up
    [fm removeItemAtPath:filePath error:NULL];
    return [NSArray arrayWithArray:profileIDs];
}

- (NSArray *)readMPInstalledProfileData
{
    NSString *filePath = [MP_ROOT_CLIENT stringByAppendingPathComponent:kMPProfilesData];
    NSDictionary *mpProfileDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    NSMutableArray *profileIDs = [[NSMutableArray alloc] init];

    if ([mpProfileDict objectForKey:@"installed"])
    {
        for (NSDictionary *p in [mpProfileDict objectForKey:@"installed"])
        {
            if ([p objectForKey:@"remove"]) {
                if ([[p objectForKey:@"remove"] integerValue] != 1) {
                    continue;
                }
            }
            [profileIDs addObject:[p objectForKey:@"profileIdentifier"]];
        }
    } else {
        return nil;
    }

    // Quick Clean Up
    return [NSArray arrayWithArray:profileIDs];
}

- (NSString *)writeProfileToDisk:(NSString *)aData
{
    NSString *fileName = [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mobileconfig"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSData *pData = [[NSData alloc] initWithBase64EncodedString:aData options:0];
    NSError *err = nil;
    [pData writeToFile:filePath options:NSDataWritingAtomic error:&err];
    if (err) {
        qlerror(@"Error, %@",err.localizedDescription);
        return nil;
    }

    return filePath;
}

- (BOOL)installProfile:(NSString *)aProfilePath
{
    // Write Profile Data To Plist
    NSArray *cmdArgs = [NSArray arrayWithObjects:@"-I",@"-F",aProfilePath, nil];
    NSTask *task = nil;
    task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/profiles" arguments:cmdArgs];
    [task waitUntilExit];

    int result = [task terminationStatus];
    if (result == 0) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)removeProfile:(NSString *)aProfileIdentifier
{
    // Write Profile Data To Plist
    NSArray *cmdArgs = [NSArray arrayWithObjects:@"-R",@"-p",aProfileIdentifier, nil];
    NSTask *task = nil;
    task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/profiles" arguments:cmdArgs];
    [task waitUntilExit];

    int result = [task terminationStatus];
    if (result == 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)recordProfileInstallToDisk:(NSDictionary *)aProfile
{
    NSMutableArray *installedProfiles;
    NSString *filePath = [MP_ROOT_CLIENT stringByAppendingPathComponent:kMPProfilesData];
    NSMutableDictionary *profileData = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    if ([profileData objectForKey:@"installed"]) {
        installedProfiles = [NSMutableArray arrayWithArray:[profileData objectForKey:@"installed"]];
    } else {
        installedProfiles = [[NSMutableArray alloc] init];
    }
    [installedProfiles addObject:aProfile];
    [profileData setObject:installedProfiles forKey:@"installed"];
    [profileData writeToFile:filePath atomically:NO];
}

@end
