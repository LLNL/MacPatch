//
//  MPSystemInfo.m
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

#import "MPSystemInfo.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <mach-o/arch.h>

#undef  ql_component
#define ql_component lcl_cMPSystemInfo

@implementation MPSystemInfo

#pragma mark - MacPatch Client Info

+ (NSString *)clientUUID
{
    NSString *cUUID = NULL;
    
	io_struct_inband_t iokit_entry;
	uint32_t bufferSize = 4096; // this signals the longest entry we will take
	io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
	IORegistryEntryGetProperty(ioRegistryRoot, kIOPlatformUUIDKey, iokit_entry, &bufferSize);
	cUUID = [NSString stringWithCString:iokit_entry encoding:NSASCIIStringEncoding];
    
	IOObjectRelease((unsigned int) iokit_entry);
	IOObjectRelease(ioRegistryRoot);
	
	if ([cUUID length] < 35) {
        cUUID = [[NSString stringWithFormat:@"00000000-0000-1000-8000-%@",[MPSystemInfo getMacAddressForInterface:@"en0"]] stringByReplacingOccurrencesOfString:@":" withString:@""];
        qlwarning(@"Host is using old cuuid (%@) format.",cUUID);
    }    
	
	goto done;
	
done:
	return cUUID;
}

#pragma mark - Client Networking Info

+ (NSString *)getActiveInterface
{
    NSString *activeInterface = @"en0";
    SCDynamicStoreRef dynRefForIF = SCDynamicStoreCreate(kCFAllocatorSystemDefault,(CFStringRef)@"GetDynamicStoreForIP", NULL, NULL);
    NSArray *aIfList = [(NSArray *)SCDynamicStoreCopyKeyList(dynRefForIF,CFSTR("State:/Network/Global/IPv4")) autorelease];
    for (NSString *aIf in aIfList) {
        NSDictionary *dict = [(NSDictionary *)SCDynamicStoreCopyValue(dynRefForIF,(CFStringRef)aIf) autorelease];
        if (dict) {
            activeInterface = [NSString stringWithString:[dict objectForKey:@"PrimaryInterface"]];
            break;
        } 
    }
    //CFRelease(dynRefForIF);
    return activeInterface;
}

+ (NSString *)getMacAddressForActiveInterface
{
    return [MPSystemInfo getMacAddressForInterface:[MPSystemInfo getActiveInterface]];
}

+ (NSString *)getMacAddressForInterface:(NSString *)bsdIfName
{
    NSString				*macAddress			= nil;
	NSArray                 *allInterfaces      = (NSArray*)SCNetworkInterfaceCopyAll();
	NSEnumerator            *interfaceWalker	= [allInterfaces objectEnumerator];
	SCNetworkInterfaceRef   curInterface		= nil;
	
	while ((curInterface = (SCNetworkInterfaceRef)[interfaceWalker nextObject]))
	{
		if ( [(NSString*)SCNetworkInterfaceGetBSDName(curInterface) isEqualToString:bsdIfName])
		{
			macAddress = [NSString stringWithString:(NSString*)SCNetworkInterfaceGetHardwareAddressString(curInterface)];
			break;
		}
	}
	[allInterfaces release];
	return macAddress;
}

+ (NSString *)getIPAddress
{
    return [MPSystemInfo getIPAddressForInterface:[MPSystemInfo getActiveInterface]];
}

+ (NSString *)getIPAddressForInterface:(NSString *)bsdIfName
{
    NSString *ipResult = @"NA";
    
    SCDynamicStoreRef dynRef=SCDynamicStoreCreate(kCFAllocatorSystemDefault,(CFStringRef)@"", NULL, NULL);
    NSArray *interfaceList=[(NSArray *)SCDynamicStoreCopyKeyList(dynRef,(CFStringRef)@"State:/Network/Interface/.*/IPv4") autorelease];
    qldebug(@"interfaceList: %@",interfaceList);
    for (NSString *interface in interfaceList) 
    {
        if ([interface rangeOfString:bsdIfName].location != NSNotFound && [interface rangeOfString:@"lo0"].location == NSNotFound)
        {
            qldebug(@"interface: %@",interface);
            NSDictionary *interfaceDict = [(NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)interface) autorelease];
            NSArray *iList = nil;
            iList = [NSArray arrayWithArray:[interfaceDict objectForKey:@"Addresses"]];
            if (iList) {
                if ([iList count] >= 1) {
                    ipResult = [iList objectAtIndex:0];
                    break;
                }
            }
        }
    }
    return ipResult;
}

#pragma mark - System Version Info

+ (NSDictionary *)consoleUserData
{
    NSMutableDictionary *uData = [[[NSMutableDictionary alloc] init] autorelease];
	[uData setObject:@"NA" forKey:@"consoleUser"];
	[uData setObject:@"NA" forKey:@"consoleUserUID"];
	[uData setObject:@"NA" forKey:@"consoleUserGID"];
    
    // Get Current User Info
	NSString *consoleUserName;
	uid_t	uid;
	gid_t	gid;
    
    consoleUserName = (NSString *)SCDynamicStoreCopyConsoleUser(NULL, &uid, &gid);
	if ([consoleUserName length] >= 1) {
		[uData setObject:(NSString *)consoleUserName forKey:@"consoleUser"];
		[uData setObject:[NSString stringWithFormat:@"%i",uid] forKey:@"consoleUserUID"];
		[uData setObject:[NSString stringWithFormat:@"%i",gid] forKey:@"consoleUserGID"];
	}
    [consoleUserName release];
    
    NSDictionary *consoleUser = [NSDictionary dictionaryWithDictionary:uData];
    return consoleUser;
}

+ (NSDictionary *)hostAndComputerNames
{
    NSMutableDictionary *localInfo = [[[NSMutableDictionary alloc] init] autorelease];
	
	[localInfo setObject:@"NA" forKey:@"localComputerName"];
	[localInfo setObject:@"NA" forKey:@"localHostName"];
    
    // Get Local Computer Name
	CFStringRef localComputerName = SCDynamicStoreCopyLocalHostName(NULL);
	if (localComputerName && CFStringGetLength(localComputerName)!=0) {
		[localInfo setObject:(NSString *)localComputerName forKey:@"localComputerName"];
        CFRelease(localComputerName);
	}
    
	// Get Local Host Name
	NSHost *localHost = [NSHost currentHost];
	[localInfo setObject:[localHost name] forKey:@"localHostName"];
	
    NSDictionary *chNames = [NSDictionary dictionaryWithDictionary:localInfo];
	return chNames;
}

+ (NSDictionary *)osVersionInfo
{
    NSFileManager *fm = [NSFileManager defaultManager]; 
    NSMutableDictionary *osVers = [[[NSMutableDictionary alloc] init] autorelease];
	
    NSString *serverAppPath = @"/Applications/Server.app";
	NSString *clientVerPath = @"/System/Library/CoreServices/SystemVersion.plist";
	NSString *serverVerPath = @"/System/Library/CoreServices/ServerVersion.plist";
	
    if ([fm fileExistsAtPath:clientVerPath]) {
        osVers = [NSMutableDictionary dictionaryWithContentsOfFile:clientVerPath];
    } else if ([fm fileExistsAtPath:serverVerPath]) {
        osVers = [NSMutableDictionary dictionaryWithContentsOfFile:serverVerPath];
    } else {
        //Error
        [osVers setObject:@"NA" forKey:@"ProductBuildVersion"];
        [osVers setObject:@"NA" forKey:@"ProductBuildVersion"];
        [osVers setObject:@"NA" forKey:@"ProductCopyright"];
        [osVers setObject:@"NA" forKey:@"ProductName"];
        [osVers setObject:@"NA" forKey:@"ProductUserVisibleVersion"];
        [osVers setObject:@"NA" forKey:@"ProductVersion"];
    }
    
    if ([fm fileExistsAtPath:serverAppPath]) {
        // 10.7 and above
        [osVers setObject:@"Mac OS X Server" forKey:@"ProductName"];
    }
    
    NSDictionary *results = [NSDictionary dictionaryWithDictionary:osVers];
	return results;
}

+ (NSDictionary *)osVersionOctets
{
    NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
    [result setObject:[NSNumber numberWithInt:10] forKey:@"major"];
    [result setObject:[NSNumber numberWithInt:0] forKey:@"minor"];
    [result setObject:[NSNumber numberWithInt:0] forKey:@"revision"];
    
    NSDictionary *d = [NSDictionary dictionaryWithDictionary:[MPSystemInfo osVersionInfo]];
    NSString *osVerString = [d objectForKey:@"ProductVersion"];
    NSArray *osVerArray = [osVerString componentsSeparatedByString:@"."];
    if ([osVerArray count] >= 3) {
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        [result setObject:[f numberFromString:[osVerArray objectAtIndex:0]] forKey:@"major"];
        [result setObject:[f numberFromString:[osVerArray objectAtIndex:1]] forKey:@"minor"];
        [result setObject:[f numberFromString:[osVerArray objectAtIndex:2]] forKey:@"revision"];
        [f release];
    }
    
    NSDictionary *octets = [NSDictionary dictionaryWithDictionary:result];
    return octets;
}

+ (NSString *)hostArchitectureType
{
    const NXArchInfo *info = NXGetLocalArchInfo();
	
	switch (info->cputype) {
		case CPU_TYPE_POWERPC:
			return @"ppc";
			break;
		case CPU_TYPE_I386:
			return @"i386";
			break;
		case CPU_TYPE_POWERPC64:
			return @"ppc";
			break;
		case CPU_TYPE_X86_64:
			return @"i386";
			break;
		default:
			return @"na";
			break;
	}
}

+ (BOOL)hostNeedsReboot
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/tmp/.NeedsReboot"] == TRUE) {
		return YES;
	} else {
        return NO;
    }
}

+ (NSDictionary *)getMPApplicationVersions
{
    NSDictionary *result;
    
    NSFileManager *fm = [NSFileManager defaultManager]; 
    NSString *file = nil;
    NSString *taskResult = nil;
    
    
    NSMutableArray *files = [[[NSMutableArray alloc] initWithArray:[fm directoryContentsAtPath:MP_ROOT_CLIENT]] autorelease];
    [files addObject:@"/Library/Frameworks/MPFramework.framework"];
    
    NSMutableDictionary *apps = [[NSMutableDictionary alloc] init];
    NSError *err = nil;
    MPNSTask *task = [[MPNSTask alloc] init];
    for (NSString *item in files) {
        file = [MP_ROOT_CLIENT stringByAppendingPathComponent:item];
        if ([file containsString:@".app"] || [file containsString:@".framework"]) {
            [apps setObject:[NSString versionStringForApplication:file] forKey:item];
        } else {
            err = nil;
            taskResult = [task runTask:[MP_ROOT_CLIENT stringByAppendingPathComponent:item] binArgs:[NSArray arrayWithObject:@"-v"] error:&err];
            if ([taskResult isEqualToString:@"Error"] == NO && [taskResult containsString:@"Error" ignoringCase:YES] == NO) 
            {
                [apps setObject:taskResult forKey:item];	
            }
        }
    }
    
    result = [NSDictionary dictionaryWithDictionary:apps];
    [apps release];
    [task release];
    return result;
}

@end
