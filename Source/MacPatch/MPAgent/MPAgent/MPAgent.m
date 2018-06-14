//
//  MPAgent.m
/*
 Copyright (c) 2018, Lawrence Livermore National Security, LLC.
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

#import "MPAgent.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <IOKit/IOKitLib.h>
#import "MacPatch.h"

static MPAgent *_instance;

@implementation MPAgent

@synthesize g_OSVers;
@synthesize g_cuuid;
@synthesize g_serialNo;
@synthesize g_agentVer;
@synthesize g_AppHashes;
@synthesize g_agentPid;
@synthesize g_hostName;

// SWDist
@synthesize g_SWDistTasks;
@synthesize g_SWDistTasksHash;
@synthesize g_SWDistTasksJSONHash;

+ (MPAgent *)sharedInstance
{
	@synchronized(self) {
		
        if (_instance == nil) {
            _instance = [[super allocWithZone:NULL] init];
			[_instance setG_OSVers:[_instance systemVersionDictionary]];
			[_instance setG_cuuid:[_instance collectCUUIDFromHost]];
			[_instance setG_serialNo:[_instance getHostSerialNumber]];
			[_instance setG_agentVer:@"0"];
			[_instance setG_AppHashes:[NSMutableDictionary dictionary]];
            [_instance setG_agentPid:NULL];
            [_instance setG_SWDistTasksHash:@"NA"];
            [_instance setG_SWDistTasksJSONHash:@"NA"];
            NSString *localHostName = (__bridge NSString *)SCDynamicStoreCopyLocalHostName(NULL);
            [_instance setG_hostName:localHostName];
        }
    }
    return _instance;
}

#pragma mark Singleton Methods

+ (id)allocWithZone:(NSZone *)zone
{
	return [self sharedInstance];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark -
#pragma mark OS/Client Info
- (NSString *)collectCUUIDFromHost
{
	NSString *result = NULL;
	io_struct_inband_t iokit_entry;
	uint32_t bufferSize = 4096; // this signals the longest entry we will take
	io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
	IORegistryEntryGetProperty(ioRegistryRoot, kIOPlatformUUIDKey, iokit_entry, &bufferSize);
	result = [NSString stringWithCString:iokit_entry encoding:NSASCIIStringEncoding];
	
	IOObjectRelease((unsigned int) iokit_entry);
	IOObjectRelease(ioRegistryRoot);
    
	return result;
}

- (NSDictionary *)systemVersionDictionary
{
	NSDictionary *sysVer;
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_10) {
        NSOperatingSystemVersion os = [[NSProcessInfo processInfo] operatingSystemVersion];
        sysVer = @{@"major":[NSNumber numberWithInt:(int)os.majorVersion],@"minor":[NSNumber numberWithInt:(int)os.minorVersion],@"revision":[NSNumber numberWithInt:(int)os.patchVersion]};
    } else {
        SInt32 OSmajor, OSminor, OSrevision;
        OSErr err1 = Gestalt(gestaltSystemVersionMajor, &OSmajor);
        OSErr err2 = Gestalt(gestaltSystemVersionMinor, &OSminor);
        OSErr err3 = Gestalt(gestaltSystemVersionBugFix, &OSrevision);
        if (!err1 && !err2 && !err3)
        {
            sysVer = @{@"major":[NSNumber numberWithInt:OSmajor],@"minor":[NSNumber numberWithInt:OSminor],@"revision":[NSNumber numberWithInt:OSrevision]};
        }
    }
	return sysVer;
}

- (NSString *)getHostSerialNumber
{
	NSString *result = nil;
    
	io_registry_entry_t rootEntry = IORegistryEntryFromPath( kIOMasterPortDefault, "IOService:/" );
	CFTypeRef serialAsCFString = NULL;
    
	serialAsCFString = IORegistryEntryCreateCFProperty( rootEntry,
													   CFSTR(kIOPlatformSerialNumberKey),
													   kCFAllocatorDefault,
													   0);
    
	IOObjectRelease( rootEntry );
	if (serialAsCFString == NULL) {
		result = @"NA";
	} else {
		result = [NSString stringWithFormat:@"%@",(__bridge NSString *)serialAsCFString];
		CFRelease(serialAsCFString);
	}
	
	return result;
}

- (NSDictionary *)getOSInfo
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *results = nil;
	NSString *clientVerPath = @"/System/Library/CoreServices/SystemVersion.plist";
	NSString *serverVerPath = @"/System/Library/CoreServices/ServerVersion.plist";
	
	if ([fm fileExistsAtPath:serverVerPath] == TRUE) {
		results = [NSDictionary dictionaryWithContentsOfFile:serverVerPath];
	} else {
		if ([fm fileExistsAtPath:clientVerPath] == TRUE) {
			results = [NSDictionary dictionaryWithContentsOfFile:clientVerPath];
		}
	}
	
	return results;
}

- (NSString *)clientKey
{
    NSError *err = nil;
    MPSimpleKeychain *skc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_KEYCHAIN_FILE];
    MPKeyItem *keyItem = [skc retrieveKeyItemForService:kMPClientService error:&err];
    if (err) {
        logit(lcl_vWarning,@"getClientKey: %@",err.localizedDescription);
        return @"NA";
    }
    
    return keyItem.secret;
}

@end
