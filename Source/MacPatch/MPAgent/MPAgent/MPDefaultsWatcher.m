//
//  MPDefaultsWatcher.m
/*
 Copyright (c) 2017, Lawrence Livermore National Security, LLC.
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

#import "MPDefaultsWatcher.h"
#import "MPAgent.h"

#define MP_SCAN_INTERVAL	30

@implementation MPDefaultsWatcher
@synthesize confHash;

-(id)init
{
    if (self = [super init])
    {
        si = [MPAgent sharedInstance];
        if ([[NSFileManager defaultManager] fileExistsAtPath:AGENT_PREFS_PLIST]) {
            [self setConfHash:[self hashForFile:AGENT_PREFS_PLIST digest:@"MD5"]];
		}	
    }
    return self;
}

-(id)initForHash
{
	self = [super init];
    if (self)
    {
        si = [MPAgent sharedInstance];
    }
    return self;
}


#pragma mark -
#pragma mark Class Methods

- (void)checkConfig
{
	if ([confHash isEqualToString:@"ERROR"]) {
		[self setConfHash:[self hashForFile:AGENT_PREFS_PLIST digest:@"MD5"]];
	}
	
	if ([self checkFileHash:AGENT_PREFS_PLIST fileHash:confHash] == NO)
	{
		logit(lcl_vInfo,@"File Hash has changed, re-read defaults.");
        [si setG_Defaults:[self readConfigPlist]];
		[self setConfHash:[self hashForFile:AGENT_PREFS_PLIST digest:@"MD5"]];
		logit(lcl_vInfo,@"New Defaults:\n%@",[si g_Defaults]);
	}
}

- (void)checkConfigThread
{
	@autoreleasepool {
		BOOL isRunning = YES;
		while (isRunning)
		{
			[self checkConfig];
			[NSThread sleepForTimeInterval:MP_SCAN_INTERVAL];
		}
	}
}
         
#pragma mark Plist Methods
- (NSDictionary *)readConfigPlist
{
    NSDictionary *result = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    // See if the plist exists
    if ([fm fileExistsAtPath:AGENT_PREFS_PLIST] == NO)
    {
        logit(lcl_vError,@"Error plist file '%@' does not exist.",AGENT_PREFS_PLIST);
        return result;
    }

    // Read the plist
    NSString *error;
    NSPropertyListFormat format;
    NSData *data = [NSData dataWithContentsOfFile:AGENT_PREFS_PLIST];
    NSMutableDictionary *thePlist = [NSPropertyListSerialization propertyListFromData:data 
                                                                     mutabilityOption:NSPropertyListImmutable 
                                                                               format:&format 
                                                                     errorDescription:&error];
    if (!thePlist) {
        logit(lcl_vError,@"Error reading plist from file '%@', error = '%@'",AGENT_PREFS_PLIST,error);
        return result;
    } 

    result = [NSDictionary dictionaryWithDictionary:thePlist];
    return result;
}

#pragma mark Crypto Methods

-(BOOL)checkFileHash:(NSString *)localFilePath fileHash:(NSString *)hash
{
	return [self checkFileHash:localFilePath fileHash:hash digest:@"MD5"];
}

-(BOOL)checkFileHash:(NSString *)localFilePath fileHash:(NSString *)hash digest:(NSString *)type
{
	BOOL hashResult = FALSE;
	MPCrypto *crypto;

	if (![[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
		logit(lcl_vError,@"Unable to get hash for file %@. File is missing.",localFilePath);	
		return FALSE;
	}

	crypto = [[MPCrypto alloc] init];
	
	if ([type isEqualToString:@"MD5"]) {
		if ([[[crypto md5HashForFile:localFilePath] uppercaseString] isEqualToString:[hash uppercaseString]])
		{
			hashResult = TRUE;
		}
	} 
	else if ([type isEqualToString:@"SHA1"])
	{
		if ([[[crypto sha1HashForFile:localFilePath] uppercaseString] isEqualToString:[hash uppercaseString]])
		{
			hashResult = TRUE;
		}
	}
	
	
	return hashResult;
}

-(NSString *)hashForFile:(NSString *)aFilePath digest:(NSString *)aDigest
{
	MPCrypto *crypto;
	crypto = [[MPCrypto alloc] init];
	if ([[aDigest uppercaseString] isEqualToString:@"MD5"]) {
		return [crypto md5HashForFile:aFilePath];
	} else if ([[aDigest uppercaseString] isEqualToString:@"SHA1"]) {
		return [crypto sha1HashForFile:aFilePath];
	} else {
		logit(lcl_vError,@"Hash digest format %@, is not supported.",aDigest);
		return @"ERROR";
	}

}

@end
