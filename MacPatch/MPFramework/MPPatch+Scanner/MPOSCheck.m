//
//  MPOSCheck.m
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

#import <Cocoa/Cocoa.h>
#import "MPOSCheck.h"

#undef  ql_component
#define ql_component lcl_cMPOSCheck


@interface NSApplication (SystemVersion)

- (void)getSystemVersionMajor:(unsigned *)major minor:(unsigned *)minor bugFix:(unsigned *)bugFix;

@end

@implementation NSApplication (SystemVersion)

- (void)getSystemVersionMajor:(unsigned *)major minor:(unsigned *)minor bugFix:(unsigned *)bugFix
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) goto fail;
    if (systemVersion < 0x1040)
    {
        if (major) *major = ((systemVersion & 0xF000) >> 12) * 10 + ((systemVersion & 0x0F00) >> 8);
        if (minor) *minor = (systemVersion & 0x00F0) >> 4;
        if (bugFix) *bugFix = (systemVersion & 0x000F);
    }
    else
    {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) goto fail;
        if (major) *major = versionMajor;
        if (minor) *minor = versionMinor;
        if (bugFix) *bugFix = versionBugFix;
    }
    
    return;
    
fail:
    qlerror(@"Unable to obtain system version: %ld", (long)err);
    if (major) *major = 10;
    if (minor) *minor = 0;
    if (bugFix) *bugFix = 0;
}

@end


@implementation MPOSCheck


- (NSArray *)curOSVerArray
{
    return curOSVerArray; 
}
- (void)setCurOSVerArray:(NSArray *)aCurOSVerArray
{
    if (curOSVerArray != aCurOSVerArray) {
        [aCurOSVerArray retain];
        [curOSVerArray release];
        curOSVerArray = aCurOSVerArray;
    }
}

- (id)init;
{
    self = [super init];
	if (!self)
		return nil;
	
	unsigned major, minor, bugFix;
    [[NSApplication sharedApplication] getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	curOSVerArray = [NSArray arrayWithObjects:[NSNumber numberWithInteger:major],[NSNumber numberWithInteger:minor],[NSNumber numberWithInteger:bugFix],nil];
	
	return self;
}

-(BOOL)checkOSArch:(NSString *)osArchString
{
	BOOL result = NO;
	
#if defined __i386__ || defined __x86_64__
	NSString *procType = @"X86";
#elif defined __ppc__ || defined __ppc64__
	NSString *procType = @"PPC";
#elif defined __arm__
	NSString *procType = @"ARM";
#else
	NSString *procType = @"Unknown Architecture";
#endif
	
	NSArray *reqOSArchArray = [osArchString componentsSeparatedByString:@","];
	for (int i = 0;i < [reqOSArchArray count]; i++) {
		if ([[[[reqOSArchArray objectAtIndex:i] uppercaseString] trim] isEqualToString:procType] == TRUE) 
		{
			result = TRUE;
			goto done;
		}
	}
	
done:	
	return result;
}

-(BOOL)checkOSType:(NSString *)osTypeString
{
	BOOL osTypePass	= FALSE;
	NSDictionary *sysInfo = [self getSWVers];
	NSString *osTypeVal = [sysInfo objectForKey:@"ProductName"];
	// 					   
	NSArray *reqOSTypeArray = [osTypeString componentsSeparatedByString:@","];
	for (int i = 0;i < [reqOSTypeArray count]; i++) {
		if ([[[reqOSTypeArray objectAtIndex:i] trim] isEqualToString:osTypeVal] == TRUE) 
		{
			osTypePass = TRUE;
			goto done;
		}
	}
	
done:	
	return osTypePass;
}

-(BOOL)checkOSVer:(NSString *)osVersString
{
	BOOL osTypePass	= FALSE;
	
	// if it's just * then pass, it's a wildcard for all
	if ([osVersString isEqualToString:@"*"] == TRUE)
	{
		osTypePass = TRUE; 
		goto done;
	}
	
	// else, lets create out array
	NSArray *reqOSVerArray = [osVersString componentsSeparatedByString:@","];
	if ([reqOSVerArray count] <= 0) {
		qlerror(@"Error: Required OS Version String Check was malformed. Unable to parse.");
		osTypePass = FALSE; 
		goto done;
	}
	
	NSArray *allowOSOctets = NULL;
	int osMatchCount = 0;
	
	for(int i = 0; i<[reqOSVerArray count];i++)
	{
		if ([[reqOSVerArray objectAtIndex:i] isEqualToString:[curOSVerArray componentsJoinedByString:@"."]] == TRUE)
		{	
			osTypePass = TRUE; 
			goto done;
		}
        // Test for +, which means greater than 
        if ([[reqOSVerArray objectAtIndex:i] containsString:@"+"] == TRUE) 
        {
			allowOSOctets = [[NSArray alloc] initWithArray:[[reqOSVerArray objectAtIndex:i] componentsSeparatedByString:@"."]];
            // If the Major OS Version is greater than just pass it...
            if ([[curOSVerArray objectAtIndex:0] containsString:@"+"] == TRUE) {
                if ([[curOSVerArray objectAtIndex:0] intValue] >= [[allowOSOctets objectAtIndex:0] intValue]) {
                    osTypePass = TRUE;
                    goto done;
                }
            }
            if ([[curOSVerArray objectAtIndex:1] containsString:@"+"] == TRUE) {
                if ([[curOSVerArray objectAtIndex:0] intValue] >= [[allowOSOctets objectAtIndex:0] intValue]) {
                    if ([[curOSVerArray objectAtIndex:1] intValue] >= [[allowOSOctets objectAtIndex:1] intValue]) {
                        osTypePass = TRUE;
                        goto done;
                    }
                }
            }
            if ([[curOSVerArray objectAtIndex:2] containsString:@"+"] == TRUE) {
                if ([[curOSVerArray objectAtIndex:0] intValue] >= [[allowOSOctets objectAtIndex:0] intValue]) {
                    if ([[curOSVerArray objectAtIndex:1] intValue] >= [[allowOSOctets objectAtIndex:1] intValue]) {
                        if ([[curOSVerArray objectAtIndex:2] intValue] >= [[allowOSOctets objectAtIndex:2] intValue]) {
                            osTypePass = TRUE;
                            goto done;
                        }
                    }
                }
            }
        }
		if ([[reqOSVerArray objectAtIndex:i] containsString:@"*"] == TRUE)
		{	
			osMatchCount = 0;
			allowOSOctets = [[NSArray alloc] initWithArray:[[reqOSVerArray objectAtIndex:i] componentsSeparatedByString:@"."]];
			
			for (int x=0;x<[allowOSOctets count]; x++)
			{	
				if ([[curOSVerArray objectAtIndex:x] intValue] == [[allowOSOctets objectAtIndex:x] intValue] || [[allowOSOctets objectAtIndex:x] isEqualToString:@"*"] == TRUE)
				{	
					osMatchCount++;		
				}
			}
			int octets = (int)[allowOSOctets count];
			[allowOSOctets release];
			if (osMatchCount == octets)
			{		
				osTypePass = TRUE;
				goto done;				
			} else {
				qldebug(@"OS octets is %d and matched octets is %d. They must match to pass.",octets,osMatchCount);
			}
			
			
		}
	}
	
done:
	return osTypePass;
}

-(NSDictionary *)getSWVers
{
	NSDictionary *results = NULL;
	NSString *clientVerPath = @"/System/Library/CoreServices/SystemVersion.plist";
	NSString *serverVerPath = @"/System/Library/CoreServices/ServerVersion.plist";
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:serverVerPath] == TRUE) {
		results = [NSDictionary dictionaryWithContentsOfFile:serverVerPath];
	} else {
		if ([[NSFileManager defaultManager] fileExistsAtPath:clientVerPath] == TRUE) {
			results = [NSDictionary dictionaryWithContentsOfFile:clientVerPath];
		}
	}
	
	return results;
}

@end
