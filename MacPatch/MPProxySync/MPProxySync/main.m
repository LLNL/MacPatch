//
//  main.m
//  MPProxySync
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
#import "MPProxySyncController.h"

#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>

#define APPNAME         @"MPProxySync"
#define APPVERSION      "1.1.0"
#define SUPPORT_PATH    @"/Library/Application Support/MPProxySync"

void usage(void);

int main(int argc, char * argv[])
{

    @autoreleasepool {
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *argPlist = [SUPPORT_PATH stringByAppendingPathComponent:@"gov.llnl.MPProxySync.plist"];

        BOOL verboseLogging = NO;
        BOOL echoToConsole = NO;
        BOOL softwareOnly = NO;
        BOOL patchOnly = NO;

        // Setup argument processing
        int c;
        while (1)
        {
            static struct option long_options[] =
            {
                {"plist"			,required_argument	,0, 'p'},
                {"swOnly"			,no_argument		,0, 'S'},
                {"patchOnly"		,no_argument		,0, 'P'},
                {"Echo"				,no_argument		,0, 'e'},
                {"Verbose"			,no_argument		,0, 'V'},
                {"version"			,no_argument		,0, 'v'},
                {"help"				,no_argument		,0, 'h'},
                {0, 0, 0, 0}
            };
            // getopt_long stores the option index here.
            int option_index = 0;
            c = getopt_long (argc, argv, "p:SPeVvh", long_options, &option_index);

            // Detect the end of the options.
            if (c == -1)
                break;

            switch (c)
            {
                case 'p':
                    argPlist = [NSString stringWithUTF8String:optarg];
                    break;
                case 'S':
                    softwareOnly = YES;
                    patchOnly = NO;
                    break;
                case 'P':
                    softwareOnly = NO;
                    patchOnly = YES;
                    break;
                case 'V':
                    verboseLogging = YES;
                    break;
                case 'e':
                    echoToConsole = YES;
                    break;
                case 'v':
                    printf("%s\n",APPVERSION);
                    return 0;
                case 'h':
                case '?':
                default:
                    printf("Silly Rabbit, Trix are for Kids!\n");
                    usage();
            }
        }
        if (optind < argc) {
            while (optind < argc) {
                printf ("Invalid argument %s ", argv[optind++]);
            }
            usage();
            exit(0);
        }

        NSString *_logFile = [NSString stringWithFormat:@"%@/Logs/MPProxySync.log",MP_ROOT_SERVER];
        [MPLog setupLogging:_logFile level:lcl_vDebug];

        if (verboseLogging) {
            // enable logging for all components up to level Debug
            lcl_configure_by_name("*", lcl_vDebug);
            [LCLLogFile setMirrorsToStdErr:1];
            logit(lcl_vInfo,@"***** %@ started -- Debug Enabled *****", APPNAME);
        } else {
            // enable logging for all components up to level Info
            lcl_configure_by_name("*", lcl_vInfo);
            if (echoToConsole) {
                [LCLLogFile setMirrorsToStdErr:1];
            } else {
                [LCLLogFile setMirrorsToStdErr:0];
            }
            
            logit(lcl_vInfo,@"***** %@ started *****",APPNAME);
        }
        
        logit(lcl_vInfo,@"MPProxySync v.%s",APPVERSION);
        
        if ([fm fileExistsAtPath:argPlist] == NO) {
            logit(lcl_vError,@"Configuration property list (%@) was not found. Tool can not run.",argPlist);
            exit(1);
        }
        NSDictionary *l_prefs = [NSDictionary dictionaryWithContentsOfFile:argPlist];
        
        MPProxySyncController *mpx = [[MPProxySyncController alloc] initWithDefaults:l_prefs];
        if (patchOnly == YES || (patchOnly == NO && softwareOnly == NO)) {
            [mpx syncContent];
        }
        if (softwareOnly == YES || (patchOnly == NO && softwareOnly == NO)) {
            [mpx syncSWContent];
        }
    }
    return 0;
}

void usage(void) {
    printf("%s: MacPatch Proxy Server Content Sync Tool.\n",[APPNAME UTF8String]);
    printf("Version %s\n\n",APPVERSION);
    printf("Usage: %s -p [PATH TO PLIST] [-V] [-v] \n\n",[APPNAME UTF8String]);
    printf(" -p\t\tPlist for app defaults.\n");
	printf(" -V \t\tVerbose logging.\n");
	printf(" -v \t\tDisplay version info. \n");
	printf("\n");
    exit(0);
}
