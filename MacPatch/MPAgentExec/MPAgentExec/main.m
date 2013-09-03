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

#define APPVERSION	@"1.5.0"
#define APPNAME		@"MPAgentExec"

void usage(void);

int main (int argc, char * argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
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
			{"allowClient"			,no_argument	    ,0, 'C'},
			{"allowServer"			,no_argument	    ,0, 'S'},
			{"iload"				,no_argument	    ,0, 'i'},
			{"FORCERUN"				,no_argument		,0, 'F'},
            // Inventory
            {"type"                 ,required_argument	,0, 't'},
			{"Audit"                ,no_argument		,0, 'A'},
			{"cuuid"                ,no_argument		,0, 'c'},
            // Output
			{"Echo"					,no_argument		,0, 'e'},
			{"Verbose"				,no_argument		,0, 'V'},
			{"version"				,no_argument		,0, 'v'},
			{"help"					,no_argument		,0, 'h'},
			{0, 0, 0, 0}
		};
		// getopt_long stores the option index here.
		int option_index = 0;
		c = getopt_long (argc, argv, "Dsuf:B:aUgGCSiFt:AceVvh", long_options, &option_index);
		
		// Detect the end of the options.
		if (c == -1)
			break;
		
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
				_defaultsOverride = [NSDictionary dictionaryWithObject:@"1" forKey:@"allowClient"];
				break;
			case 'S':
				_defaultsOverride = [NSDictionary dictionaryWithObject:@"1" forKey:@"allowServer"];
				break;
            case 't':
				argType = [NSString stringWithUTF8String:optarg];
                a_Type = 6;
				break;
			case 'A':
                argType = @"Custom";
                a_Type = 6;
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
    if (a_Type == 1) {
        [controller scanForPatches];
    } else if (a_Type == 2) {
		if (isILoadMode == YES) {
			[controller setILoadMode:YES];
		}
        if (_updateBundle) {
            [controller scanAndUpdateCustomWithPatchBundleID:_updateBundle];
        } else {
            [controller scanForPatchesAndUpdateWithFilter:_UpdateType];
        }
	} else if (a_Type == 3) {
		[controller scanForAVDefs];
	} else if (a_Type == 4) {
		[controller scanForAVDefsAndUpdate];
	} else if (a_Type == 5) {
		[controller scanAndUpdateAgentUpdater];
    } else if (a_Type == 6) {
		int result = NO;
        MPInv *i = [[[MPInv alloc] init] autorelease];
        if ([argType isEqual:@"Custom"]) {
            int x = 0;
            x = [i collectAuditTypeData];
        } else if ([argType isEqual:@"All"]) {
            result = [i collectInventoryData];
        } else {
            result = [i collectInventoryDataForType:argType];
        }
	} else {
		logit(lcl_vError, @"should never have gotten here!");
	}
    
    
    [controller release];
	controller = nil;
	
    [pool drain];
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
	printf(" \t\tSPNetworkDataType\n");
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
    printf(" -A \tCollect Audit data.\n\n");
	printf(" -e \tEcho logging data to console.\n");
	printf(" -V \tVerbose logging.\n");
	printf(" -v \tDisplay version info. \n");
	printf("\n");
    exit(0);
}