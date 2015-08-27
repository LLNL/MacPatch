//
//  main.m
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
#import "MPAgentExecController.h"
#import "MacPatch.h"
#import "MPInv.h"
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <unistd.h>

#define APPVERSION	@"2.1.0.0"
#define APPNAME		@"MPAgentExec"

void usage(void);

int main (int argc, char * argv[])
{
    @autoreleasepool {

        int a_Type = 0;
        BOOL echoToConsole = NO;
        BOOL verboseLogging = NO;
        BOOL isILoadMode = NO;
        BOOL forceRunTask = NO;
        int _UpdateType = 0; // 0 All, 1 = Apple, 2 = Third
        NSString *_updateBundle = nil;
        NSDictionary *_defaultsOverride = nil;

        // Inventory
        NSString *argType = NULL;

        // Setup argument processing
        int c;
        while (1)
        {
            static struct option long_options[] =
            {
                {"Debug"				,no_argument	    ,0, 'D'},
                {"Scan"					,no_argument	    ,0, 's'},
                {"Update"				,no_argument	    ,0, 'u'},
                {"UpdateFilter"			,required_argument	,0, 'f'},
                {"UpdateBundle"			,required_argument	,0, 'B'},
                {"AVInfo"				,no_argument	    ,0, 'a'},
                {"AVUpdate"				,no_argument	    ,0, 'U'},
                {"AgentUpdate"			,no_argument		,0, 'G'},
                {"AllowClient"			,no_argument	    ,0, 'C'},
                {"AllowServer"			,no_argument	    ,0, 'S'},
                {"iload"				,no_argument	    ,0, 'i'},
                {"FORCERUN"				,no_argument		,0, 'F'},
                // Inventory
                {"type"                 ,required_argument	,0, 't'},
                {"Audit"                ,no_argument		,0, 'A'},
                {"cuuid"                ,no_argument		,0, 'c'},
                // Software Dist
                {"installSWUsingGRP"    ,required_argument	,0, 'g'},
                {"installSWUsingSID"    ,required_argument	,0, 'd'},
                {"installSWUsingPLIST"  ,required_argument	,0, 'P'},
                // Output
                {"Echo"					,no_argument		,0, 'e'},
                {"Verbose"				,no_argument		,0, 'V'},
                {"version"				,no_argument		,0, 'v'},
                {"help"					,no_argument		,0, 'h'},
                {0, 0, 0, 0}
            };
            // getopt_long stores the option index here.
            int option_index = 0;
            c = getopt_long (argc, argv, "Dsuf:B:aUGCSiFt:Acg:d:P:eVvh", long_options, &option_index);

            // Detect the end of the options.
            if (c == -1) {
                break;
            }
            switch (c)
            {
                    case 's':
                        a_Type = 1;
                        break;
                    case 'u':
                        a_Type = 2;
                        break;
                    case 'f':
                        if ([[NSString stringWithUTF8String:optarg] isEqualTo:@"Apple"]) {
                            _UpdateType = 1;
                        } else if ([[NSString stringWithUTF8String:optarg] isEqualTo:@"Custom"] || [[NSString stringWithUTF8String:optarg] isEqualTo:@"Third"]) {
                            _UpdateType = 2;
                        }
                        break;
                    case 'B':
                        a_Type = 2;
                        _updateBundle = [NSString stringWithUTF8String:optarg];
                        break;
                    case 'a':
                        a_Type = 3;
                        break;
                    case 'U':
                        a_Type = 4;
                        break;
                    case 'G':
                        a_Type = 5;
                        break;
                    case 'C':
                        _defaultsOverride = [NSDictionary dictionaryWithObject:@"1" forKey:@"AllowClient"];
                        break;
                    case 'S':
                        _defaultsOverride = [NSDictionary dictionaryWithObject:@"1" forKey:@"AllowServer"];
                        break;
                    case 't':
                    /*
                        argType = [NSString stringWithUTF8String:optarg];
                        a_Type = 6;
                     */
                        printf("Inventory has been moved to MPAgent.");
                        return 0;
                        break;
                    case 'A':
                    /*
                        argType = @"Custom";
                        a_Type = 6;
                     */
                        printf("Inventory has been moved to MPAgent.");
                        return 0;
                        break;
                    case 'c':
                        printf("%s\n",[[MPSystemInfo clientUUID] UTF8String]);
                        return 0;
                    case 'V':
                        verboseLogging = YES;
                        break;
                    case 'D':
                        verboseLogging = YES;
                        break;
                    case 'i':
                        isILoadMode = YES;
                        a_Type = 2;
                        _UpdateType = 0;
                        break;
                    case 'g':
                        argType = [NSString stringWithUTF8String:optarg];
                        a_Type = 7;
                        break;
                    case 'd':
                        argType = [NSString stringWithUTF8String:optarg];
                        a_Type = 8;
                        break;
                    case 'P':
                        argType = [NSString stringWithUTF8String:optarg];
                        a_Type = 9;
                        break;
                    case 'F':
                        forceRunTask = YES;
                        break;
                    case 'e':
                        echoToConsole = YES;
                        break;
                    case 'v':
                        printf("%s\n",[APPVERSION UTF8String]);
                        return 0;
                    case 'h':
                        usage();
                        return 0;
                    case '?':
                        usage();
                        return 0;
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

        // Make sure the user is root or is using sudo
        if (getuid()) {
            printf("You must be root to run this app. Try using sudo.\n");
#ifdef DEBUG
            printf("Debug mode.\n");
#else
            exit(0);
#endif
        }

        // Setup Logging
        NSString *_logFile = [NSString stringWithFormat:@"%@/Logs/MPAgentExec.log",MP_ROOT_CLIENT];
        [MPLog setupLogging:_logFile level:lcl_vDebug];
        if (verboseLogging) {
            lcl_configure_by_name("*", lcl_vDebug);
            [LCLLogFile setMirrorsToStdErr:YES];
            logit(lcl_vInfo,@"***** %@ v.%@ started -- Debug Enabled *****", APPNAME, APPVERSION);
        } else {
            lcl_configure_by_name("*", lcl_vInfo);
            if (echoToConsole) {
                [LCLLogFile setMirrorsToStdErr:YES];
            }
            logit(lcl_vInfo,@"***** %@ v.%@ started *****", APPNAME, APPVERSION);
        }

        // Run Functions
        MPAgentExecController *controller = [[MPAgentExecController alloc] init];
        if (_defaultsOverride) {
            [controller overRideDefaults:_defaultsOverride];
        }
        if (forceRunTask == YES) {
            [controller setForceRun:YES];
        }

        MPInv *i = [[MPInv alloc] init];
        int result = NO;

        switch (a_Type) {
            case 1:
                [controller scanForPatches];
                break;
            case 2:
                if (isILoadMode == YES) {
                    [controller setILoadMode:YES];
                }
                if (_updateBundle) {
                    [controller scanAndUpdateCustomWithPatchBundleID:_updateBundle];
                } else {
                    [controller scanForPatchesAndUpdateWithFilter:_UpdateType];
                }
                break;
            case 3:
                [controller scanForAVDefs];
                break;
            case 4:
                [controller scanForAVDefsAndUpdate];
                break;
            case 5:
                [controller scanAndUpdateAgentUpdater];
                break;
            case 6:
                if ([argType isEqual:@"Custom"]) {
                    int x = 0;
                    x = [i collectAuditTypeData];
                } else if ([argType isEqual:@"All"]) {
                    result = [i collectInventoryData];
                } else {
                    result = [i collectInventoryDataForType:argType];
                }
                break;
            case 7:
                // Install Using SW Group Name ID
                result = [controller installSoftwareTasksForGroup:argType];
                break;
            case 8:
                // Install Using SW Task ID
                result = [controller installSoftwareTasks:argType];
                break;
            case 9:
                // Install Using PLIST of SW Task ID's
                result = [controller installSoftwareTasksUsingPLIST:argType];
                break;
            default:
                i = nil;
                logit(lcl_vError, @"should never have gotten here!");
                break;
        }

        controller = nil;
    }
    return 0;
}

void usage(void) {
    
	printf("%s\n",[APPNAME UTF8String]);
	printf("Version: %s\n\n",[APPVERSION UTF8String]);
	printf("Usage: %s [OPTION]\n\n",[APPNAME UTF8String]);
	printf(" -s \tScan for patches.\n");
	printf(" -u \tScan & Update approved patches.\n");
	printf(" -a \tScan for AV info.\n");
	printf(" -U \tScan for AV info and update outdated AV defs.\n");
    printf(" -G \tScan for Agent updates and update if needed.\n");
	printf(" -i \tScan & Update approved patches in iLoad output mode.\n");
    printf("\nInventory\n");
    printf("Option: -t [ALL] or [SPType]\n\n");
    printf(" -t\tInventory type, All is default.\n");
	printf(" \tSupported types:\n");
    printf(" \t\tAll\n");
	printf(" \t\tSPHardwareDataType\n");
	printf(" \t\tSPSoftwareDataType\n");
	printf(" \t\tSPNetworkDataType (Depricated)\n");
    printf(" \t\tSINetworkInfo\n");
	printf(" \t\tSPApplicationsDataType\n");
	printf(" \t\tSPFrameworksDataType\n");
	printf(" \t\tDirectoryServices\n");
	printf(" \t\tInternetPlugins\n");
	printf(" \t\tAppUsage\n");
	printf(" \t\tClientTasks\n");
    printf(" \t\tDiskInfo\n");
    printf(" \t\tUsers\n");
    printf(" \t\tGroups\n");
    printf(" \t\tFileVault\n");
    printf(" \t\tPowerManagment\n");
    printf(" \t\tBatteryInfo\n");
    printf(" \t\tConfigProfiles\n");
    printf(" \t\tAppStoreApps\n");
    printf(" \t\tMPServerList\n");
    printf(" -A \tCollect Audit data.\n\n");
    printf(" -g \t[Software Group Name] Install Software in group.\n");
    printf(" -d \tInstall software using TaskID\n");
    printf(" -P \t[Software Plist] Install software using plist.\n");
	printf(" -e \tEcho logging data to console.\n");
	printf(" -V \tVerbose logging.\n");
	printf(" -v \tDisplay version info. \n");
	printf("\n");
    exit(0);
}