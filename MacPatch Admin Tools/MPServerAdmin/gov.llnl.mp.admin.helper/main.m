//
//  main.m
//  gov.llnl.mp.admin.helper
//
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

#import <Foundation/Foundation.h>

#import "HelperTool.h"

int main(int argc, char **argv)
{
    // We just create and start an instance of the main helper tool object and then
    // have it run the run loop forever.
    
    @autoreleasepool
    {
        HelperTool *  m;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSLocalDomainMask, YES );
        NSString *logFile = [[paths firstObject] stringByAppendingPathComponent:@"Logs/MPServerAdmin.log"];
        [LCLLogFile setPath:logFile];
        lcl_configure_by_name("*", lcl_vDebug);
        [LCLLogFile setAppendsToExistingLogFile:YES];
        [LCLLogFile setMirrorsToStdErr:YES];
        
        m = [[HelperTool alloc] init];
        [m run];                // This never comes back...
    }
    
    return EXIT_FAILURE;        // ... so this should never be hit.
}