//
//  main.m
//  MPAgent
/*
 Copyright (c) 2021, Lawrence Livermore National Security, LLC.
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
#import <SystemConfiguration/SystemConfiguration.h>
#import "AgentController.h"
#import "SoftwareController.h"
#import "MPAgentRegister.h"
#import "MPInv.h"
#import "MPOSUpgrade.h"
#import "AgentData.h"
#import "MPAgent.h"
#import "MPProvision.h"
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <unistd.h>

#define APPVERSION	@"3.6.5.1"
#define APPNAME		@"MPAgent"
// This Define will be modified durning MPClientBuild script
#define APPBUILD	@"[BUILD]"


void usage(void);
const char * consoleUser(void);

typedef enum {
    kCheckIn = 1,
    kPatchScan = 3,
    kPatchUpdate = 4,
    kPatchUpdateFilter = 5,
    kPatchUpdateForBundle = 6,
    kAgentUpdater = 7,
    kMandatorySoftwareScan = 8,
    kOSProfiles = 9,
    kOSUpgradeState = 10,
    kInventory = 12,
    kSoftwareInstallGroup = 13,
    kSoftwareInstallSID = 14,
    kSoftwareInstallPlist = 15,
    kAgentRegister = 16,
    kAgentRegistrationInfo = 17,
    kAgentRegistrationEcho = 18,
    kAgentInstall = 19,
    kProvisioning = 20,
    kMandatorySoftwareInstall = 21,
    kProvisionConfig = 22,
    kMDMUnenrollDevice = 23,
    kShowInstalledApps = 24,
    kFileVaultCheck = 25,
    kDaemonMode = 99
} MAINARGS;

int main (int argc, char * argv[])
{
	@autoreleasepool
    {
		int a_Type              = kDaemonMode;
		BOOL echoToConsole      = NO;
		BOOL debugLogging       = NO;
		BOOL traceLogging       = NO;
		BOOL verboseLogging     = NO;
		BOOL isILoadMode 		= NO;
		BOOL forceRun			= NO;
        
        // Registration
        BOOL doRegistration     = NO;
        BOOL readRegInfo        = NO;
        NSString *regKeyArg     = @"999999999";
        NSString *regKeyHash    = @"999999999";
        
        // Inventory
        NSString *invArg        = NULL;
		
		// Patching
		MPPatchContentType updateType = kAllPatches;
		NSString 	   *updateBundle = nil;
		
		// Software
		NSString *swArg			= NULL;
		
        // OS Migration
        BOOL osMigration        = NO;
        NSString *osMigAction   = NULL;
        NSString *osMigLabel    = @"";
        NSString *osMigID       = @"auto";
        
        // MDM Stuff
        NSString *mdmKey        = @"NA";
		
		// Setup argument processing
		int c;
		while (1)
		{
			static struct option long_options[] =
			{
				// Stdout & Logging
				{"Echo"					,no_argument		,0, 'e'},
				{"Debug"				,no_argument	    ,0, 'D'},
				{"Trace"				,no_argument	    ,0, 'T'},
				{"Verbose"				,no_argument		,0, 'V'},
				
				// Client Check-in
				{"CheckIn"				,no_argument	    ,0, 'c'},
				
				// iload or iLoad, will echo to stdout and run scan & patch
				{"iload"				,no_argument	    ,0, 'i'},
				{"iLoad"				,no_argument	    ,0, 'I'},
                {"iLoadEcho"            ,no_argument        ,0, 'Y'},
				
				// Patching
				{"Scan"					,no_argument	    ,0, 's'},
				{"Update"				,no_argument	    ,0, 'u'},
				{"Critial"				,no_argument	    ,0, 'x'},
				
				// Patching Filters
				{"UpdateFilter"			,required_argument	,0, 'f'},
				{"UpdateBundle"			,required_argument	,0, 'B'},
				{"FORCERUN"				,no_argument		,0, 'F'},
				
				// Inventory
				{"type"             	,required_argument	,0, 't'},
				{"Audit"            	,no_argument		,0, 'A'},
				{"cuuid"            	,no_argument		,0, 'C'},
				
				
				// Agent Updater
				{"AgentUpdater"			,no_argument	    ,0, 'G'},
				
				// Mandatory Software Tasks for Client group
                {"SWScanUpdate" 		,no_argument	    ,0, 'S'},
                {"mandatorySoftware"    ,no_argument        ,0, 'M'},
				
				// Software Dist
				{"installSWUsingGRP"    ,required_argument	,0, 'g'},
				{"installSWUsingSID"    ,required_argument	,0, 'd'},
				{"installSWUsingPLIST"  ,required_argument	,0, 'P'},
                
                // Provisioning
                {"provision"            ,no_argument        ,0, 'L'},
                {"provisionConfig"      ,no_argument        ,0, 'z'},
				
				// Profiles
                {"Profile"          	,no_argument	    ,0, 'p'},

				// Client Registration
				{"register"		    	,optional_argument	,0,    'r'},
				{"regInfo"		    	,optional_argument  ,NULL, 'R'},
				{"echoReg"		    	,required_argument  ,0,	   'X'},
				
				// OS Migration
				{"OSUpgrade"        	,required_argument	,0, 'k'},
				{"OSLabel"          	,required_argument	,0, 'l'},
				{"OSUpgradeID"      	,required_argument	,0, 'm'},
				
				// Agent Install
				{"agentInstall"        	,no_argument		,0, 'K'},
				
				// Version Info
				{"version"				,no_argument		,0, 'v'},
				{"build"				,no_argument		,0, 'b'},
				{"help"					,no_argument		,0, 'h'},
                
                // FV Check
                {"fvCheck"              ,no_argument        ,0, 'Z'},
                
                // Test DB
                {"installedApps"        ,no_argument        ,0, 'E'},
                
                // MDM
                {"mdmUnenroll"          ,required_argument  ,0, 'W'},
                
                // Test
                {"inventory"            ,no_argument  ,0, 'y'},
                
				{0, 0, 0, 0}
			};
			// getopt_long stores the option index here.
            // H, I, J, N, O, Q
            // j, n, o, q, w,
            // Used = y
			int option_index = 0;
			c = getopt_long (argc, argv, "eDTVciIYsuxfB:Ft:ACGSMg:d:P:Lzpr::R::X:k:l:m:Kvbh:ZEW:y", long_options, &option_index);
			
			// Detect the end of the options.
			if (c == -1)
				break;
			
			switch (c)
			{
				case 'e':
					echoToConsole = YES;
					break;
				case 'D':
					debugLogging = YES;
					break;
				case 'T':
					traceLogging = YES;
					break;
				case 'V':
					verboseLogging = YES;
					break;
				case 'c':
					a_Type = kCheckIn;
					break;
				case 'i':
					isILoadMode = YES;
					a_Type = kPatchUpdate;
					break;
				case 'I':
					isILoadMode = YES;
					a_Type = kPatchUpdate;
					break;
                case 'Y':
                    isILoadMode = YES;
                    break;
				case 's':
					a_Type = kPatchScan;
					break;
				case 'u':
					a_Type = kPatchUpdate;
					break;
				case 'x':
					a_Type = kPatchUpdate;
					break;
				case 'f':
					a_Type = kPatchUpdateFilter;
					if ([[[NSString stringWithUTF8String:optarg] lowercaseString] isEqualTo:@"apple"]) {
						updateType = kApplePatches;
					} else if ([[[NSString stringWithUTF8String:optarg] lowercaseString] isEqualTo:@"custom"] || [[[NSString stringWithUTF8String:optarg] lowercaseString] isEqualTo:@"third"]) {
						updateType = kCustomPatches;
					} else if ([[[NSString stringWithUTF8String:optarg] lowercaseString] isEqualTo:@"critical"]) {
						updateType = kCriticalPatches;
					}
					break;
				case 'B':
					a_Type = kPatchUpdateForBundle;
					updateBundle = [NSString stringWithUTF8String:optarg];
					break;
				case 'F':
					forceRun = YES;
					break;
				case 't':
					invArg = [NSString stringWithUTF8String:optarg];
					a_Type = kInventory;
					break;
				case 'A':
					invArg = @"Custom";
					a_Type = kInventory;
					break;
				case 'C':
					printf("%s\n",[[MPSystemInfo clientUUID] UTF8String]);
					return 0;
				case 'G':
					a_Type = kAgentUpdater;
					break;
				case 'S':
					a_Type = kMandatorySoftwareScan;
					break;
                case 'M':
                    a_Type = kMandatorySoftwareInstall;
                    break;
				case 'g':
					swArg = [NSString stringWithUTF8String:optarg];
					a_Type = kSoftwareInstallGroup;
					break;
				case 'd':
					swArg = [NSString stringWithUTF8String:optarg];
					a_Type = kSoftwareInstallSID;
					break;
                case 'P':
					swArg = [NSString stringWithUTF8String:optarg];
					a_Type = kSoftwareInstallPlist;
					break;
                case 'L':
                    a_Type = kProvisioning;
                    break;
                case 'z':
                    a_Type = kProvisionConfig;
                    break;
                case 'p':
					a_Type = kOSProfiles;
					break;
				case 'r':
					a_Type = kAgentRegister;
					doRegistration = YES;
					if (optarg) {
						regKeyArg = [NSString stringWithUTF8String:optarg];
					}
					break;
				case 'R':
					a_Type = kAgentRegistrationInfo;
					readRegInfo = YES;
					if (optarg) {
						regKeyHash = [NSString stringWithUTF8String:optarg];
					}
					break;
				case 'X':
					a_Type = kAgentRegistrationEcho;
					if (optarg) {
						// re-use variable, this is the client key
						regKeyHash = [NSString stringWithUTF8String:optarg];
					}
					break;
                case 'k':
					a_Type = kOSUpgradeState;
                    if ([[[NSString stringWithUTF8String:optarg] lowercaseString] isEqualTo:@"start"]) {
                        osMigAction = @"start";
                        osMigration = YES;
                    } else if ([[[NSString stringWithUTF8String:optarg] lowercaseString] isEqualTo:@"stop"]) {
                        osMigAction = @"stop";
                        osMigration = YES;
                    } else {
                        osMigAction = @"ERR";
                        printf("Error, \"OSUpgrade\" state must be either start or stop.\n");
                        return 1;
                    }
                    break;
                case 'l':
                    osMigLabel = [NSString stringWithUTF8String:optarg];
                    break;
                case 'm':
                    osMigID = [NSString stringWithUTF8String:optarg];
                    break;
				case 'K':
					a_Type = kAgentInstall;
					break;
				case 'v':
					printf("%s\n",[APPVERSION UTF8String]);
					return 0;
				case 'b':
					printf("%s\n",[APPBUILD UTF8String]);
					return 0;
                case 'Z':
                    a_Type = kFileVaultCheck;
                    break;
                case 'E':
                    a_Type = kShowInstalledApps;
                    break;
                case 'W':
                    a_Type = kMDMUnenrollDevice;
                    mdmKey = [NSString stringWithUTF8String:optarg];
                    break;
                    
                // Test
                case 'y':
                    invArg = @"V2";
                    a_Type = kInventory;
                    break;
                    
				case 'h':
				case '?':
				default:
					usage();
			}
		}

        if (optind < argc)
		{
            while (optind < argc) {
                printf ("Invalid argument %s ", argv[optind++]);
            }
            usage();
            exit(0);
        }

		// Make sure the user is root or is using sudo
		if (getuid())
		{
			printf("You must be root to run this app. Try using sudo.\n");
#if DEBUG
			printf("Running as debug...\n");
#else
			exit(0);
#endif
		}

    
        [[MPAgent sharedInstance] setG_agentVer:APPVERSION];
        [[MPAgent sharedInstance] setG_agentPid:[NSString stringWithFormat:@"%d",[[NSProcessInfo processInfo] processIdentifier]]];
		
        // Setup Logging
		NSString *_logFile = @"/Library/Logs/MPAgent.log";
		[MPLog setupLogging:_logFile level:lcl_vInfo];
		
		if (verboseLogging || debugLogging) {
			lcl_configure_by_name("*", lcl_vDebug);
			if (verboseLogging || echoToConsole) {
				[LCLLogFile setMirrorsToStdErr:YES];
			}
			logit(lcl_vInfo,@"***** %@ v.%@ started -- Debug Enabled *****", APPNAME, APPVERSION);
		} else if (traceLogging) {
			lcl_configure_by_name("*", lcl_vTrace);
			if (verboseLogging || echoToConsole) {
				[LCLLogFile setMirrorsToStdErr:YES];
			}
			logit(lcl_vInfo,@"***** %@ v.%@ started -- Trace Enabled *****", APPNAME, APPVERSION);
		} else {
			lcl_configure_by_name("*", lcl_vInfo);
			if (echoToConsole) {
				[LCLLogFile setMirrorsToStdErr:YES];
			}
			if (a_Type == kDaemonMode) {
				logit(lcl_vInfo,@"***** %@ v.%@ (Daemon)started *****", APPNAME, APPVERSION);
			} else {
				logit(lcl_vInfo,@"***** %@ v.%@ started *****", APPNAME, APPVERSION);
			}
			
		}
        
		MPInv *inv;
		AgentController *mpac;
		SoftwareController *swc;
		NSString *uID;
		MPOSUpgrade *mposu;
		NSError *err = nil;
		MPAgentRegister *mpar;
		AgentData *mpad;
		MPAgent *mpAgent;
        MPProvision *mpProv;
        NSArray *hist;
        MPClientDB *cdb;
		int result = 1;
		
        switch (a_Type)
        {
            case kCheckIn:
                // Client Checkin
                mpac = [[AgentController alloc] init];
                [mpac runWithType:kCheckIn];
                return 0;
                break;
            case kPatchScan:
                // Patch Scan
                mpac = [[AgentController alloc] init];
                [mpac setILoadMode:isILoadMode];
                [mpac runPatchScan:updateType forceRun:forceRun];
                return 0;
                break;
            case kPatchUpdate:
                // Patch Updates
                mpac = [[AgentController alloc] init];
                [mpac setILoadMode:isILoadMode];
                [mpac setForceRun:forceRun];
                [mpac runPatchScanAndUpdate:updateType bundleID:updateBundle];
                return 0;
                break;
            case kPatchUpdateFilter:
                break;
            case kPatchUpdateForBundle:
                break;
            case kAgentUpdater:
                // Update MPUpdate
                mpac = [[AgentController alloc] init];
                [mpac runWithType:kAgentUpdater];
                return 0;
                break;
            case kMandatorySoftwareScan:
                // Mandatory Software Tasks for Client group
                mpac = [[AgentController alloc] init];
                [mpac runWithType:kMandatorySoftwareScan];
                return 0;
                break;
            case kOSProfiles:
                // Scan and install Mac OS Profiles
                mpac = [[AgentController alloc] init];
                [mpac runWithType:kOSProfiles];
                return 0;
                break;
            case kOSUpgradeState:
                // OS Migration
                mposu = [[MPOSUpgrade alloc] init];
                if ([[osMigID lowercaseString] isEqualTo:@"auto"]) {
                    if ([[osMigAction lowercaseString] isEqualTo:@"stop"]) {
                        uID = [mposu  migrationIDFromFile:OS_MIGRATION_STATUS];
                    } else {
                        uID = [[NSUUID UUID] UUIDString];
                    }
                } else {
                    uID = osMigID;
                }
                err = nil;
                result = [mposu postOSUpgradeStatus:osMigAction label:osMigLabel upgradeID:uID error:&err];
                if (err) {
                    logit(lcl_vError,@"%@",err.localizedDescription);
                    fprintf(stderr, "%s\n", [err.localizedDescription UTF8String]);
                    exit(1);
                }
                if (result != 0) {
                    fprintf(stderr, "Post OS Upgrade status failed.\n");
                    exit(1);
                }
                return 0;
                break;
            case kInventory:
                // Inventory
                inv = [[MPInv alloc] init];
                if (invArg != NULL)
                {
                    if ([invArg isEqual:@"Custom"]) {
                        result = [inv collectAuditTypeData];
                    } else if ([invArg isEqual:@"All"]) {
                        result = [inv collectInventoryData];
                    } else if ([invArg isEqual:@"V2"]) {
                        result = [inv collectInventoryDataV2];
                    } else {
                        result = [inv collectInventoryDataForType:invArg];
                    }
                }
                return result;
                break;
            case kSoftwareInstallGroup:
                // Software - Install Group
                swc = [SoftwareController new];
                [swc setILoadMode:isILoadMode];
                result = [swc installSoftwareTasksForGroup:swArg];
                return result;
                break;
            case kSoftwareInstallSID:
                // Software - Install SW Task
                // Arg is SW Task ID
                swc = [SoftwareController new];
                [swc setILoadMode:isILoadMode];
                result = [swc installSoftwareTask:swArg];
                return result;
                break;
            case kSoftwareInstallPlist:
                // Software - Install SW Using Plist
                swc = [SoftwareController new];
                [swc setILoadMode:isILoadMode];
                result = [swc installSoftwareTasksUsingPLIST:swArg];
                return result;
                break;
            case kAgentRegister:
                // Register
                mpar = [[MPAgentRegister alloc] init];
                if (![regKeyArg isEqualToString:@"999999999"]) {
                    result = [mpar registerClient:regKeyArg error:&err];
                } else {
                    result = [mpar registerClient:&err];
                }
                
                if (err) {
                    NSLog(@"%@",err.localizedDescription);
                }
                
                if (result == 0) {
                    printf("\nAgent has been registered.\n");
                } else {
                    fprintf(stderr, "Agent registration has failed.\n");
                    exit(1);
                }
                
                exit(0);
                break;
            case kAgentRegistrationInfo:
                // Check Registration
                mpar = [[MPAgentRegister alloc] init];
                if (![regKeyHash isEqualToString:@"999999999"]) {
                    if ([mpar clientIsRegistered]) {
                        printf("\nAgent is registered.\n");
                        exit(0);
                    } else {
                        printf("Warning: Agent is not registered.\n");
                        exit(1);
                    }
                } else {
                    // Will add additional check
                    if ([mpar clientIsRegistered]) {
                        printf("\nAgent is registered.\n");
                        exit(0);
                    } else {
                        printf("Warning: Agent is not registered.\n");
                        exit(1);
                    }
                }
                break;
            case kAgentRegistrationEcho:
                // Check Registration
                mpad = [[AgentData alloc] init];
                [mpad setAgentDataKey:regKeyHash];
                [mpad echoAgentData];
                exit(0);
                break;
            case kAgentInstall:
                // Post Agent Install
                mpAgent = [MPAgent new];
                [mpAgent postAgentHasBeenInstalled];
                exit(0);
                break;
            case kProvisioning:
                // Provison Host
                mpProv = [MPProvision new];
                [mpProv provisionHost];
                exit(0);
                break;
            case kMandatorySoftwareInstall:
                // Mandatory Software
                swc = [SoftwareController new];
                result = [swc installMandatorySoftware];
                return result;
                break;
            case kProvisionConfig:
                // Download Provisioning Config
                mpac = [[AgentController alloc] init];
                result = [mpac provisionSetupAndConfig];
                exit(result);
                break;
            case kShowInstalledApps:
                // Test
                cdb = [[MPClientDB alloc] init];
                hist = [cdb retrieveInstalledSoftwareTasksDict];
                qlinfo(@"%@",hist);
                return 0;
                break;
            case kMDMUnenrollDevice:
                if (![mdmKey isEqualToString:@"NA"] && ![mdmKey isEqualToString:@""]) {
                    mpac = [[AgentController alloc] init];
                    [mpac unenrollFromMDM:mdmKey];
                    return 0;
                    break;
                } else {
                    printf(@"MDM Key Name can not be left blank.\n");
                }
                return 1;
            case kFileVaultCheck:
                mpac = [[AgentController alloc] init];
                [mpac runWithType:kFileVaultCheck];
                return 0;
                break;
            
            case kDaemonMode:
                // DEFAULT Daemon Mode
                mpac = [[AgentController alloc] init];
                [mpac runWithType:kDaemonMode];
                [[NSRunLoop currentRunLoop] run];
                break;
            default:
                printf("Unknown arg type. Now exiting.\n");
                return 0;
        }
    }
    return 0;
}

void usage(void)
{
	printf("%s: MacPatch Agent\n",[APPNAME UTF8String]);
	printf("Version %s\n\n",[APPVERSION UTF8String]);
	printf("Usage: %s [OPTIONS]\n\n",[APPNAME UTF8String]);
	printf(" -c \t --CheckIn \t\tRun client checkin.\n\n");
	// Agent Registration
	printf("Agent Registration \n");
	printf(" -r \t --register \tRegister Agent [ RegKey (Optional) ] based on configuration.\n");
	printf(" -R \t --regInfo \tDisplays if client is registered.\n\n");
	// Scan & Update
	printf("Patching \n");
	printf(" -s \t --Scan \tScan for patches.\n");
	printf(" -u \t --Update \tScan & Update approved patches.\n\n");
    printf(" -Z \t --fvCheck \tCheck if file valut authrestart is set.\n\n");
	// printf(" -x \tScan & Update critical patches only.\n");
	
	// Software Dist
	printf("Software \n");
	printf(" -g \t[Software Group Name] Install Software in group.\n");
	printf(" -d \tInstall software using TaskID\n");
	printf(" -P \t[Software Plist] Install software using plist.\n\n");
	printf(" -S \tInstall client group mandatory software.\n\n");
	
	// Mac OS Profiles
    printf("OS Profiles \n");
    printf(" -p \t --Profile \tScan & Install macOS profiles.\n\n");
	// Agent Updater
	printf("Agent Updater \n");
    printf(" -G \t --AgentUpdater \tUpdate the MacPatch agent updater agent.\n\n");
	// OS Migration - iLoad etc.
	printf("OS Provisioning - iLoad \n");
	printf(" -i \t --iLoad \tiLoad flag for provisioning output.\n\n");
	
	printf("OS Migration \n");
    printf(" -k \t --OSUpgrade \tOS Migration/Upgrade action state (Start/Stop)\n");
    printf(" -l \t --OSLabel \tOS Migration/Upgrade label\n");
    printf(" -m \t --OSUpgradeID \tA Unique Migration/Upgrade ID (Optional Will Auto Gen by default)\n\n");
	// Anti-Virus
	printf("Antivirus (Symantec) \n");
	printf(" -a \t --AVScan \tCollects Antivirus data installed on system.\n");
	printf(" -U \t --AVUpdate \tUpdates antivirus defs.\n\n");
	// Inventory
    printf("Inventory \n");
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
	printf(" \t\tSPExtensionsDataType\n");
    printf(" \t\tDirectoryServices\n");
    printf(" \t\tInternetPlugins\n");
    printf(" \t\tAppUsage\n");
    printf(" \t\tClientTasks\n");
    printf(" \t\tDiskInfo\n");
    printf(" \t\tUsers\n");
    printf(" \t\tGroups\n");
	printf(" \t\tLocalAdminAccounts\n");
    printf(" \t\tFileVault\n");
    printf(" \t\tPowerManagment\n");
    printf(" \t\tBatteryInfo\n");
    printf(" \t\tConfigProfiles\n");
    printf(" \t\tAppStoreApps\n");
    printf(" \t\tMPServerList\n");
    printf(" \t\tPlugins\n");
    printf(" \t\tFirmwarePasswordInfo\n");
    printf(" -A \tCollect Audit data.\n\n");
    printf(" -C \tDisplay client ID.\n");
	printf(" -e \t --Echo \t\t\tEcho logging data to console.\n");
	printf(" -V \tVerbose logging.\n");
	printf("\n -v \tDisplay version info. \n");
	printf("\n");
    exit(0);
}

const char * consoleUser(void)
{
    NSString *result;
    SCDynamicStoreRef   store;
    CFStringRef         consoleUserName;
    
    store = SCDynamicStoreCreate(NULL, (CFStringRef)@"GetCurrentConsoleUser", NULL, NULL);
    consoleUserName = SCDynamicStoreCopyConsoleUser(store, NULL, NULL);
    
    NSString *nsString = (__bridge NSString*)consoleUserName;

    if (nsString) {
        result = nsString;
    } else {
        result = @"null";
    }

    if (consoleUserName)
        CFRelease(consoleUserName);
    
    return [result UTF8String];
}
