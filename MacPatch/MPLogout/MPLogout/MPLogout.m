//
//  MPLogout.m
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

#import "MPLogout.h"

static MPLogout *_instance;

@implementation MPLogout

+ (id)sharedManager
{
	@synchronized(self) {
        if (_instance == nil) {
            _instance = [[super allocWithZone:NULL] init];
            [_instance setG_InstallStatusStr:@"MPLogout started...\n"];
        }
    }
    return _instance;
}

#pragma mark -
- (NSString *)g_InstallStatusStr
{
    return [[g_InstallStatusStr retain] autorelease];
}
- (void)setG_InstallStatusStr:(NSString *)aG_InstallStatusStr
{
    if (g_InstallStatusStr != aG_InstallStatusStr) {
        [g_InstallStatusStr release];
        g_InstallStatusStr = [aG_InstallStatusStr retain];
    }
}

- (void)appendStatusString:(NSString *)aStr
{
	NSMutableString *t_String = [[NSMutableString alloc] init];
	[t_String setString:[self g_InstallStatusStr]];
	[t_String appendString:aStr];
	[self setG_InstallStatusStr:t_String];
	[t_String release];
}

#pragma mark -
#pragma mark Singleton Methods

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedManager] retain];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned long)retainCount
{
    return LONG_MAX; //NSIntegerMax;  //denotes an object that cannot be released
}

- (id)autorelease
{
    return self;
}
@end
