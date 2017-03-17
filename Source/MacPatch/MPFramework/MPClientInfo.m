//
//  MPClientInfo.m
//  MPLibrary
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

#import "MPClientInfo.h"
#import "MPDefaults.h"

#undef  ql_component
#define ql_component lcl_cMPClientInfo

@implementation MPClientInfo

+ (NSString *)patchGroupRev
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:PATCH_GROUP_PATCHES_PLIST])
    {
        MPDefaults *defaults = [[MPDefaults alloc] init];
        NSString *pGroup = [[defaults defaults] objectForKey:@"PatchGroup"];
        NSDictionary *_dict = [NSDictionary dictionaryWithContentsOfFile:PATCH_GROUP_PATCHES_PLIST];
        NSDictionary *patchGroupDict;
        if ([_dict objectForKey:pGroup])
        {
            patchGroupDict = [_dict objectForKey:pGroup];
            if ([patchGroupDict objectForKey:@"rev"]) {
                qldebug(@"Patch Group Rev ID is %@",[patchGroupDict objectForKey:@"rev"]);
                return [patchGroupDict objectForKey:@"rev"];
            } else {
                qlerror(@"Patch Group Patches file did not contain the rev key.");
            }
        }
    }
    
    return @"-1";
}

@end
