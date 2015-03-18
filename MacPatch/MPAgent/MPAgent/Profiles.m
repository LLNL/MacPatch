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
#import "MacPatch.h"

static NSString *kMPProfilesData = @"Data/gov.llnl.mp.custom.profiles.plist";

@interface Profiles (Private)

- (void)scanAndInstallPofiles;
- (NSArray *)retrieveProfileIDData:(NSError **)aErr;
- (NSArray *)readLocalProfileData;
- (NSArray *)readMPInstalledProfiles;
- (NSArray *)readMPInstalledProfileData;
- (NSString *)writeProfileToDisk:(NSString *)aData;
- (BOOL)installProfile:(NSString *)aProfilePath;
- (BOOL)removeProfile:(NSString *)aProfileIdentifier;
- (void)recordProfileInstallToDisk:(NSDictionary *)aProfile;
- (BOOL)profileIsInstalledOnDisk:(NSString *)profileID installedProfiles:(NSArray *)localProfiles;

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

- (BOOL)isConcurrent
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
	//@try {
		[self scanAndInstallPofiles];
	//}
	//@catch (NSException * e) {
	//	logit(lcl_vError,@"[NSException]: %@",e);
	//}
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
        } else {
            qldebug(@"MP Profiles:%@",profiles);
        }
        NSMutableArray *profileIdentities = [[NSMutableArray alloc] init];
        NSMutableArray *profilesToRemove = [[NSMutableArray alloc] init];
        NSArray *installedProfiles = [self readMPInstalledProfileData]; // returns an array of recorded installed profile id's
        NSArray *installedProfilesRaw = [self readMPInstalledProfiles]; // returns and array of complete install profile dicts
        NSArray *localProfiles = [self readLocalProfileData];

        // Install Profiles
        for (NSDictionary *p in profiles)
        {
            if ([p objectForKey:@"profileIdentifier"] == (id)[NSNull null] || [[p objectForKey:@"profileIdentifier"] length] == 0 ) {
                NSString *pName = @"NA";
                if ([p objectForKey:@"id"]) {
                    pName = [p objectForKey:@"id"];
                }
                qlerror(@"profileIdentifier is null. Skipping %@",pName);
                qldebug(@"%@",p);
                continue;
            }
            
            if ([self profileIsInstalledOnDisk:[p objectForKey:@"profileIdentifier"] installedProfiles:localProfiles])
            {
                BOOL needsInstall = NO;
                BOOL foundInMPInstalledArray = NO;
                // Check the rev if it needs updating
                if (installedProfilesRaw) {
                    for (NSDictionary *installedProfile in installedProfilesRaw) {
                        if ([[installedProfile objectForKey:@"profileIdentifier"] isEqualToString:[p objectForKey:@"profileIdentifier"]]) {
                            int currentProfileRev = [[installedProfile objectForKey:@"rev"] intValue];
                            int wsProfileRev = [[p objectForKey:@"rev"] intValue];
                            qldebug(@"%d -- %d",currentProfileRev,wsProfileRev);
                            if (currentProfileRev != wsProfileRev) {
                                needsInstall = YES;
                            }
                            foundInMPInstalledArray = YES;
                            break;
                        }
                    }
                }

                // No need to install profile again...
                if (needsInstall == NO) {
                    if (foundInMPInstalledArray == NO) {
                        [self recordProfileInstallToDisk:p];
                    }
                    qldebug(@"continue");
                    continue;
                }
            }
            if ([p objectForKey:@"data"]) {
                NSString *profileOnDisk = [self writeProfileToDisk:[p objectForKey:@"data"]];
                if (!profileOnDisk) {
                    qlerror(@"Error, unable to install profile %@",[p objectForKey:@"profileIdentifier"]);
                }
                if ([self installProfile:profileOnDisk] == NO) {
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
        
        // Remove Old Profiles
        if (profilesToRemove.count >= 1)
        {
            qldebug(@"Profiles to remove %@",profilesToRemove);
            for (NSString *profileID in profilesToRemove)
            {
                if ([self removeProfile:profileID]) {
                    qlinfo(@"Profile %@ was removed.",profileID);
                } else {
                    qlerror(@"Error, profile %@ was not removed.",profileID);
                }
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
        qlerror(@"Could not find/read profile data from %@",filePath);
        return nil;
    } else {
        qldebug(@"Reading profiles file %@",filePath);
    }

    NSDictionary *profileDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    NSMutableArray *profileIDs = [[NSMutableArray alloc] init];

    if ([profileDict objectForKey:@"_computerlevel"])
    {
        for (NSDictionary *p in [profileDict objectForKey:@"_computerlevel"])
        {
            qldebug(@"Adding:\n%@",p);
            [profileIDs addObject:[p objectForKey:@"ProfileIdentifier"]];
        }
    } else {
        qlinfo(@"No computerlevel profiles.");
        return nil;
    }
    // Quick Clean Up
    //[fm removeItemAtPath:filePath error:NULL];
    qldebug(@"ProfileID: %@",profileIDs);
    return [NSArray arrayWithArray:[profileIDs copy]];
}

- (NSArray *)readMPInstalledProfiles
{
    NSString *filePath = [MP_ROOT_CLIENT stringByAppendingPathComponent:kMPProfilesData];
    NSDictionary *mpProfileDict = [NSDictionary dictionaryWithContentsOfFile:filePath];

    if ([mpProfileDict objectForKey:@"installed"])
    {
        return [mpProfileDict objectForKey:@"installed"];
    }

    return nil;
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
    // Fix Bug, on 10.8 systems. initWithBase64EncodedString on 10.9 and higher
    // NSData *pData = [[NSData alloc] initWithBase64EncodedString:aData options:0];
    NSData *pData = [NSData dataFromBase64String:aData];
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
    NSString *pID = nil;
    if ([aProfile objectForKey:@"id"])
    {
        pID = [aProfile objectForKey:@"id"];
    }

    NSMutableArray *installedProfiles = [[NSMutableArray alloc] init];
    NSString *filePath = [MP_ROOT_CLIENT stringByAppendingPathComponent:kMPProfilesData];
    qlinfo(@"Recording profile install for %@",[aProfile objectForKey:@"profileIdentifier"]);
    NSMutableDictionary *profileData = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    if (!profileData) {
        profileData = [NSMutableDictionary dictionary];
    }

    // Check to see if ID already exists
    if ([profileData objectForKey:@"installed"])
    {
        for (NSDictionary *ip in [profileData objectForKey:@"installed"])
        {
            // Found it ...
            if ([[[ip objectForKey:@"id"] uppercaseString] isEqualToString:[pID uppercaseString]])
            {
                [installedProfiles addObject:aProfile];
            } else {
                [installedProfiles addObject:ip];
            }
        }
    } else {
        [installedProfiles addObject:aProfile];
    }

    [profileData setObject:(NSArray *)installedProfiles forKey:@"installed"];
    [(NSDictionary *)profileData writeToFile:filePath atomically:YES];
    if (![fm fileExistsAtPath:filePath])
    {
        qlerror(@"%@ file was not found.",filePath);
    }
}

- (BOOL)profileIsInstalledOnDisk:(NSString *)profileID installedProfiles:(NSArray *)localProfiles
{
    if (profileID == (id)[NSNull null] || profileID.length == 0 ) {
        qlerror(@"profileID is null. ");
        return NO;
    }
    
    BOOL result = NO;
    for (NSString *pID in localProfiles)
    {
        if (pID == (id)[NSNull null] || pID.length == 0 ) {
            // We have a NULL, somehow
            continue;
        }
        
        if ([[pID uppercaseString] isEqualToString:[profileID uppercaseString]]) {
            result = YES;
            break;
        }
    }
    
    return result;
}

@end
