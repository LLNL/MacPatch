//
//  MPAgentExecController.m
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

#import "MPAgentExecController.h"
#import "MacPatch.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "MPAntiVirus.h"
#include <sys/reboot.h>

@interface MPAgentExecController (Private)

@property (nonatomic, readwrite, assign) int errorCode;
@property (nonatomic, readwrite, retain) NSString *errorMsg;

@end

@implementation MPAgentExecController

@synthesize errorCode;
@synthesize errorMsg;

@synthesize _defaults;
@synthesize _cuuid;
@synthesize _appPid;
@synthesize iLoadMode;
@synthesize forceRun;
@synthesize approvedPatches;

- (id)init
{
    self = [super init];
    if (self) {
        fm = [NSFileManager defaultManager];
        mpServerConnection = [[MPServerConnection alloc] init];
        [self set_defaults:mpServerConnection.mpDefaults];
		[self set_cuuid:[MPSystemInfo clientUUID]];
        mpAsus = [[MPAsus alloc] initWithServerConnection:mpServerConnection];
        mpDataMgr = [[MPDataMgr alloc] init];
		[self setILoadMode:NO];
		[self setForceRun:NO];
		
		// Add Debug Output
		if ([_defaults hasKey:@"MPAgentExecDebug"]) {
			if ([[_defaults objectForKey:@"MPAgentExecDebug"] isEqualTo:@"1"]) {
				lcl_configure_by_name("*", lcl_vDebug);
			}
		}
    }
    return self;
}

- (id)initForBundleUpdate
{
    self = [super init];
    if (self) {
        fm = [NSFileManager defaultManager];
        mpServerConnection = [[MPServerConnection alloc] init];
        [self set_defaults:mpServerConnection.mpDefaults];
		[self set_cuuid:[MPSystemInfo clientUUID]];
        mpAsus = [[MPAsus alloc] initWithServerConnection:mpServerConnection];
        mpDataMgr = [[MPDataMgr alloc] init];
		[self setILoadMode:NO];
		[self setForceRun:NO];
        [self setErrorCode:-1];
        [self setErrorMsg:@""];
    }
    return self;
}

- (void)dealloc
{
    [mpAsus release];
    [mpDataMgr release];
    [super dealloc];
}

-(void)overRideDefaults:(NSDictionary *)aDict
{
	NSMutableDictionary *_d = [NSMutableDictionary dictionaryWithDictionary:_defaults];
	for (id key in [aDict allKeys]) {
		[_d setObject:[aDict objectForKey:key] forKey:key];
	}
	[self set_defaults:(NSDictionary *)_d];
}

- (void)scanForPatches
{
	[self scanForPatchesWithFilter:0 byPassRunning:NO];
}

- (void)scanForPatchesWithFilter:(int)aFilter
{
    [self scanForPatchesWithFilter:aFilter byPassRunning:NO];
}

- (void)scanForPatchesWithFilter:(int)aFilter byPassRunning:(BOOL)aByPass
{
    [self scanForPatchesWithFilterWaitAndForce:aFilter byPassRunning:aByPass];
}

- (void)scanForPatchesWithFilterWaitAndForce:(int)aFilter byPassRunning:(BOOL)aByPass
{
    // Filter - 0 = All,  1 = Apple, 2 = Third
    if (forceRun == NO) {
        if (aByPass == YES) {
            int w = 0;
            while ([self isTaskRunning:kMPPatchSCAN] == YES) {
                if (w == 60) {
                    [self removeTaskRunning:kMPPatchSCAN];
                    break;
                }
                w++;
                sleep(1);
            }
        } else {
            if ([self isTaskRunning:kMPPatchSCAN]) {
                logit(lcl_vInfo,@"Scanning for patches is already running. Now exiting.");
                return;
            } else {
                [self writeTaskRunning:kMPPatchSCAN];
            }
        }
    }
    
    
    NSString            *_approvedPatchesFile = [NSString stringWithFormat:@"%@/Data/.approvedPatches.plist",MP_ROOT_CLIENT];
	NSMutableArray      *approvedUpdatesArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpDict;
	
	// Get Patch Group Patches
    MPWebServices *mpws = [[[MPWebServices alloc] init] autorelease];
    NSError *wsErr = nil;
    NSDictionary *patchGroupPatches = [mpws getPatchGroupContent:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"%@",wsErr.localizedDescription);
        goto done;
    }

	if (!patchGroupPatches) {
		logit(lcl_vError,@"There was a issue getting the approved patches for the patch group, scan will exit.");
		goto done;
	}
    NSArray *approvedApplePatches = nil;
    NSArray *approvedCustomPatches = nil;
    if ((aFilter == 0) || (aFilter == 1)) {
        approvedApplePatches  = [patchGroupPatches objectForKey:@"AppleUpdates"];
    }
    if ((aFilter == 0) || (aFilter == 2)) {
        approvedCustomPatches = [patchGroupPatches objectForKey:@"CustomUpdates"];
    }
	
	// Scan for Apple Patches
    if ((aFilter == 0) || (aFilter == 1))
    {
        logit(lcl_vInfo,@"Setting Apple softwareupdate catalog.");
        MPASUSCatalogs *mpCatalog = [[[MPASUSCatalogs alloc] init] autorelease];
        if (![mpCatalog checkAndSetCatalogURL]) {
            logit(lcl_vError,@"There was a issue setting the CatalogURL, Apple updates will not occur.");
        }
        
        logit(lcl_vInfo,@"Scanning for Apple software updates.");
        
        // New way, using the helper daemon
        NSArray *applePatchesArray = nil;
        applePatchesArray = [mpAsus scanForAppleUpdates];
        
        // post patches to web service
        NSString *dataMgrXML;
        dataMgrXML = [mpDataMgr GenXMLForDataMgr:applePatchesArray
                                         dbTable:@"client_patches_apple"
                                   dbTablePrefix:@"mp_"
                                   dbFieldPrefix:@""
                                    updateFields:@"cuuid,patch"
                                       deleteCol:@"cuuid"
                                  deleteColValue:[MPSystemInfo clientUUID]];
        
        
        // Encode to base64 and send to web service
        NSString *xmlBase64String = [[dataMgrXML dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
        MPWebServices *mpws = [[[MPWebServices alloc] init] autorelease];
        NSError *wsErr = nil;
        [mpws postDataMgrXML:xmlBase64String error:&wsErr];
        if (wsErr) {
            logit(lcl_vError,@"Scan results posted to webservice returned false.");
            logit(lcl_vError,@"%@",wsErr.localizedDescription);
        } else {
            logit(lcl_vInfo,@"Scan results posted to webservice.");
        }

        // Process patches
        if (!applePatchesArray) {
            logit(lcl_vInfo,@"The scan results for ASUS scan were nil.");
        } else {
            // If no items in array, lets bail...
            if ([applePatchesArray count] == 0 ) {
                logit(lcl_vInfo,@"No Apple updates found.");
                sleep(1);
            } else {
                // We have Apple patches, now add them to the array of approved patches
                
                // If no items in array, lets bail...
                if ([approvedApplePatches count] == 0 ) {
                    logit(lcl_vInfo,@"No apple updates found for \"%@\" patch group.",[_defaults objectForKey:@"PatchGroup"]);
                } else {
                    // Build Approved Patches
                    logit(lcl_vInfo,@"Building approved patch list...");
                    
                    for (int i=0; i<[applePatchesArray count]; i++) {
                        for (int x=0;x < [approvedApplePatches count]; x++) {
                            if ([[[approvedApplePatches objectAtIndex:x] objectForKey:@"name"] isEqualTo:[[applePatchesArray objectAtIndex:i] objectForKey:@"patch"]]) {
                                logit(lcl_vInfo,@"Approved update %@",[[applePatchesArray objectAtIndex:i] objectForKey:@"patch"]);
                                logit(lcl_vDebug,@"Approved: %@",[approvedApplePatches objectAtIndex:x]);
                                tmpDict = [[NSMutableDictionary alloc] init];
                                [tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"patch"] forKey:@"patch"];
                                [tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"description"] forKey:@"description"];
                                [tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"restart"] forKey:@"restart"];
                                [tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"version"] forKey:@"version"];
                                
                                if ([[approvedApplePatches objectAtIndex:x] objectForKey:@"hasCriteria"]) {
                                    
                                    [tmpDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"hasCriteria"] forKey:@"hasCriteria"];
                                    if ([[[approvedApplePatches objectAtIndex:x] objectForKey:@"hasCriteria"] boolValue] == YES) {
                                        if ([[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] && [[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] count] > 0) {
                                            [tmpDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] forKey:@"criteria_pre"];
                                        }
                                        if ([[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] && [[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] count] > 0) {
                                            [tmpDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] forKey:@"criteria_post"];
                                        }
                                    }
                                }
                                [tmpDict setObject:@"Apple" forKey:@"type"];
                                [tmpDict setObject:[[approvedApplePatches objectAtIndex:i] objectForKey:@"patch_install_weight"] forKey:@"patch_install_weight"];
                                logit(lcl_vDebug,@"Apple Patch Dictionary Added: %@",tmpDict);
                                [approvedUpdatesArray addObject:tmpDict];
                                [tmpDict release];
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
	// Scan for Custom Patches to see what is relevant for the system
	if ((aFilter == 0) || (aFilter == 2))
    {
        logit(lcl_vInfo,@"Scanning for custom patch vulnerabilities...");
        NSMutableArray *customPatchesArray = (NSMutableArray *)[mpAsus scanForCustomUpdates];
        
        logit(lcl_vDebug,@"Custom Patches Needed: %@",customPatchesArray);
        logit(lcl_vDebug,@"Approved Custom Patches: %@",approvedCustomPatches);
        
        // Filter List of Patches containing only the approved patches
        NSDictionary *customPatch, *approvedPatch;
        logit(lcl_vInfo,@"Building approved patch list...");
        for (int i=0; i<[customPatchesArray count]; i++) {
            customPatch	= [customPatchesArray objectAtIndex:i];
            for (int x=0;x < [approvedCustomPatches count]; x++) {
                approvedPatch	= [approvedCustomPatches objectAtIndex:x];
                if ([[customPatch objectForKey:@"patch_id"] isEqualTo:[approvedPatch objectForKey:@"patch_id"]])
                {
                    logit(lcl_vInfo,@"Patch %@ approved for update.",[customPatch objectForKey:@"description"]);
                    logit(lcl_vDebug,@"Approved [customPatch]: %@",customPatch);
                    logit(lcl_vDebug,@"Approved [approvedPatch]: %@",approvedPatch);
                    tmpDict = [[NSMutableDictionary alloc] init];
                    [tmpDict setObject:[customPatch objectForKey:@"patch"] forKey:@"patch"];
                    [tmpDict setObject:[customPatch objectForKey:@"description"] forKey:@"description"];
                    [tmpDict setObject:[customPatch objectForKey:@"restart"] forKey:@"restart"];
                    [tmpDict setObject:[customPatch objectForKey:@"version"] forKey:@"version"];
                    [tmpDict setObject:approvedPatch forKey:@"patches"];
                    [tmpDict setObject:[customPatch objectForKey:@"patch_id"] forKey:@"patch_id"];
                    [tmpDict setObject:@"Third" forKey:@"type"];
                    [tmpDict setObject:[customPatch objectForKey:@"bundleID"] forKey:@"bundleID"];
                    [tmpDict setObject:[approvedPatch objectForKey:@"patch_install_weight"] forKey:@"patch_install_weight"];
                    
                    logit(lcl_vDebug,@"Custom Patch Dictionary Added: %@",tmpDict);
                    [approvedUpdatesArray addObject:tmpDict];
                    [tmpDict release];
                    tmpDict = nil;
                    break;
                }
            }
        }
	}
    
    logit(lcl_vDebug,@"Approved patches to install: %@",approvedUpdatesArray);
    
done:
	[fm createFileAtPath:[CLIENT_PATCH_STATUS_FILE stringByExpandingTildeInPath]
                contents:[@"update" dataUsingEncoding:NSASCIIStringEncoding]
              attributes:nil];
    
    if ([fm isWritableFileAtPath:[_approvedPatchesFile stringByDeletingLastPathComponent]]) {
        logit(lcl_vDebug,@"Writing approved patches to %@",_approvedPatchesFile);
        [NSKeyedArchiver archiveRootObject:approvedUpdatesArray toFile:[NSString stringWithFormat:@"%@/Data/.approvedPatches.plist",MP_ROOT_CLIENT]];
    } else {
        logit(lcl_vError,@"Unable to write approved patches file %@. Patch file will not be used.",_approvedPatchesFile);
    }
	
	[self setApprovedPatches:[NSArray arrayWithArray:approvedUpdatesArray]];
    [approvedUpdatesArray release];
	[self removeTaskRunning:kMPPatchSCAN];
    logit(lcl_vInfo,@"Patch Scan Completed.");
}

- (void)scanForPatchUsingBundleID:(NSString *)aBundleID
{
	NSMutableArray      *approvedUpdatesArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpDict;


    // Get Patch Group Patches
    MPWebServices *mpws = [[[MPWebServices alloc] init] autorelease];
    NSError *wsErr = nil;
    NSDictionary *patchGroupPatches = [mpws getPatchGroupContent:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"%@",wsErr.localizedDescription);
        [approvedUpdatesArray release];
		return;
    }

	if (!patchGroupPatches) {
		logit(lcl_vError,@"There was a issue getting the approved patches for the patch group, scan will exit.");
        [approvedUpdatesArray release];
		return;
	}

    NSArray *approvedCustomPatches = nil;
    approvedCustomPatches = [patchGroupPatches objectForKey:@"CustomUpdates"];
    
    logit(lcl_vInfo,@"Scanning for custom patch vulnerabilities...");
    logit(lcl_vInfo,@"Scanning for custom patch vulnerabilities for %@", aBundleID);
    NSMutableArray *customPatchesArray = (NSMutableArray *)[mpAsus scanForCustomUpdateUsingBundleID:aBundleID];
    
    logit(lcl_vDebug,@"Custom Patches Needed: %@",customPatchesArray);
    //logit(lcl_vDebug,@"Approved Custom Patches: %@",approvedCustomPatches);
    
    // Filter List of Patches containing only the approved patches
    NSDictionary *customPatch, *approvedPatch;
    logit(lcl_vInfo,@"Building approved patch list...");
    for (int i=0; i<[customPatchesArray count]; i++) {
        customPatch	= [customPatchesArray objectAtIndex:i];
        for (int x=0;x < [approvedCustomPatches count]; x++) {
            approvedPatch	= [approvedCustomPatches objectAtIndex:x];
            if ([[customPatch objectForKey:@"patch_id"] isEqualTo:[approvedPatch objectForKey:@"patch_id"]]) {
                logit(lcl_vInfo,@"Patch %@ approved for update.",[customPatch objectForKey:@"description"]);
                tmpDict = [[NSMutableDictionary alloc] init];
                [tmpDict setObject:[customPatch objectForKey:@"patch"] forKey:@"patch"];
                [tmpDict setObject:[customPatch objectForKey:@"description"] forKey:@"description"];
                [tmpDict setObject:[customPatch objectForKey:@"restart"] forKey:@"restart"];
                [tmpDict setObject:[customPatch objectForKey:@"version"] forKey:@"version"];
                [tmpDict setObject:approvedPatch forKey:@"patches"];
                [tmpDict setObject:[customPatch objectForKey:@"patch_id"] forKey:@"patch_id"];
                [tmpDict setObject:@"Third" forKey:@"type"];
                [tmpDict setObject:[customPatch objectForKey:@"bundleID"] forKey:@"bundleID"];
                
                logit(lcl_vDebug,@"Custom Patch Dictionary Added: %@",tmpDict);
                [approvedUpdatesArray addObject:tmpDict];
                [tmpDict release];
                tmpDict = nil;
                break;
            }
        }
    }
    
    [self setApprovedPatches:[NSArray arrayWithArray:approvedUpdatesArray]];
    [approvedUpdatesArray release];
    logit(lcl_vInfo,@"Patch Scan Completed.");
}

-(void)scanForPatchesAndUpdate
{
	[self scanForPatchesAndUpdateWithFilter:0];
}

-(void)scanForPatchesAndUpdateWithFilter:(int)aFilter;
{
	if ([self isTaskRunning:kMPPatchUPDATE]) {
		logit(lcl_vInfo,@"Scan and update patches is already running. Now exiting.");
		return;
	} else {
		[self writeTaskRunning:kMPPatchUPDATE];
	}
	
	// Filter - 0 = All,  1 = Apple, 2 = Third
	NSArray *updatesArray = nil;
    NSString *updateFilePath = [NSString stringWithFormat:@"%@/Data/.approvedPatches.plist",MP_ROOT_CLIENT];
    
    // Check to see if we have a patch scan file within the last 15 minutes.
    // If we do, then use the contents of that file and no need to re-scan.
    if ([fm fileExistsAtPath:updateFilePath]) {
        NSError *attributesRetrievalError = nil;
        NSDictionary *attributes = [fm attributesOfItemAtPath:updateFilePath error:&attributesRetrievalError];
        
        if (!attributes) {
            logit(lcl_vError,@"Error for file at %@: %@", updateFilePath, attributesRetrievalError);
        }
        NSDate *fmDate = [attributes fileModificationDate];
        // File was created within 15 minutes of last scan...
        if (([[NSDate date] timeIntervalSinceDate:fmDate] / 60) < 16) {
            logit(lcl_vDebug, @"Within 15 Minutes. Using scan file.");
            //updatesArray = [NSArray arrayWithContentsOfFile:updateFilePath];
            updatesArray = [NSKeyedUnarchiver unarchiveObjectWithFile:updateFilePath];
        } else {
            logit(lcl_vDebug, @"Older than 15 Minutes, rescanning.");
            [self scanForPatchesWithFilterWaitAndForce:0 byPassRunning:YES];
			updatesArray = [NSArray arrayWithArray:approvedPatches];
        }
    } else {
        // Scan for Patches
        [self scanForPatchesWithFilterWaitAndForce:0 byPassRunning:YES];
		updatesArray = [NSArray arrayWithArray:approvedPatches];
    }

    // Sort Array
    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"patch_install_weight" ascending:YES];
    updatesArray = [updatesArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];

    // Populate Array with Patch Results
	if (!updatesArray) {
		logit(lcl_vInfo,@"Updates array is nil");
		goto done;
	}
    if ([updatesArray count] <= 0) {
        logit(lcl_vInfo, @"No approved patches to install.");
        logit(lcl_vDebug,@"updatesArray=%@",updatesArray);
		goto done;
    }
    
	// Check to see if client os type is allowed to perform updates.
	logit(lcl_vInfo, @"Validating client install status.");
	NSString *_osType = nil;
	_osType = [[MPSystemInfo osVersionInfo] objectForKey:@"ProductName"];
    logit(lcl_vInfo, @"OS Full Info: (%@)",[MPSystemInfo osVersionInfo]);
    logit(lcl_vInfo, @"OS Info: (%@)",_osType);
	if ([_osType isEqualToString:@"Mac OS X"]) {
		if ([_defaults objectForKey:@"allowClient"]) {
			if (![[_defaults objectForKey:@"allowClient"] isEqualToString:@"1"]) {
				logit(lcl_vInfo,@"Host is a Mac OS X Client and allowClient property is set to false. No updates will be applied.");
				goto done;
			}
		}
	}
    
	logit(lcl_vInfo, @"Validating server install status.");
	if ([_osType isEqualToString:@"Mac OS X Server"]) {
		if ([_defaults objectForKey:@"allowServer"]) {
			if (![[_defaults objectForKey:@"allowServer"] isEqualToString:@"1"]) {
				logit(lcl_vInfo,@"Host is a Mac OS X Server and allowServer property is set to false. No updates will be applied.");
				goto done;
			}
		} else {
			logit(lcl_vInfo,@"Host is a Mac OS X Server and allowServer property is not defined. No updates will be applied.");
			goto done;
		}
	}
    
	if (iLoadMode == YES) {
		printf("Updates to install: %d\n", (int)[updatesArray count]);
	}
    
    // Begin Patching Process
	MPCrypto			*_crypto;
    MPInstaller         *mpInstaller = nil;
    MPScript            *mpScript = nil;
    NSDictionary		*patch;
	NSDictionary		*currPatchToInstallDict;
	NSArray				*patchPatchesArray;
	NSString			*downloadURL;
	NSError				*err;
    
	int i;
	int installResult = 1;
	int	launchRebootWindow = 0;
	int installedPatchesNeedingReboot = 0;
    
    // Check for console user
	logit(lcl_vInfo, @"Checking for any logged in users.");
    BOOL hasConsoleUserLoggedIn = TRUE;
	@try {
		hasConsoleUserLoggedIn = [self isLocalUserLoggedIn];
	}
	@catch (NSException * e) {
		logit(lcl_vInfo, @"Error getting console user status. %@",e);
	}
	
	logit(lcl_vInfo, @"Begin installing patches.");
    for (i = 0; i < [updatesArray count]; i++) {
		// Create/Get Dictionary of Patch to install
		patch = nil;
		patch = [NSDictionary dictionaryWithDictionary:[updatesArray objectAtIndex:i]];
        
		if (hasConsoleUserLoggedIn == YES) {
            // Check if patch needs a reboot
            if ([[patch objectForKey:@"restart"] stringToBoolValue] == YES) {
                logit(lcl_vInfo,@"%@(%@) requires a reboot, this patch will be installed on logout.",[patch objectForKey:@"patch"],[patch objectForKey:@"version"]);
                launchRebootWindow++;
                continue;
            }
        }
        /* Not completed ...
        if ([self checkPatchPreAndPostForRebootRequired:patchPatchesArray]) {
            logit(lcl_vInfo,@"One or more of the pre & post installs requires a reboot, this patch will be installed on logout.");
            continue;
        }
        */
        // Now proceed to the download and install
        installResult = -1;
        
        if ([[patch objectForKey:@"type"] isEqualTo:@"Third"] && (aFilter == 0 || aFilter == 2)) {
            logit(lcl_vInfo,@"Starting install for %@",[patch objectForKey:@"patch"]);
			
			if (iLoadMode == YES) {
				printf("Begin: %s\n", [[patch objectForKey:@"patch"] cString]);
			}
            
            // Get all of the patches, main and subs
            // This is messed up, not sure why I have an array right within an array, needs to be fixed ...later :-)
            patchPatchesArray = [NSArray arrayWithArray:[[patch objectForKey:@"patches"] objectForKey:@"patches"]];
            logit(lcl_vDebug,@"Current patch has total patches associated with it %ld", ([patchPatchesArray count]-1));
            
            NSString *dlPatchLoc; //Download location Path
            int patchIndex = 0;
            for (patchIndex=0; patchIndex < [patchPatchesArray count]; patchIndex++)
			{
                // Make sure we only process the dictionaries in the NSArray
                if ([[patchPatchesArray objectAtIndex:patchIndex] isKindOfClass:[NSDictionary class]]) {
                    currPatchToInstallDict = [NSDictionary dictionaryWithDictionary:[patchPatchesArray objectAtIndex:patchIndex]];
                } else {
                    logit(lcl_vInfo,@"Object found was not of dictionary type; could be a problem. %@",[patchPatchesArray objectAtIndex:patchIndex]);
                    continue;
                }
                
                // We have a currPatchToInstallDict to work with
                logit(lcl_vInfo,@"Start install for patch %@ from %@",[currPatchToInstallDict objectForKey:@"url"],[patch objectForKey:@"patch"]);
                
                // First we need to download the update
                @try {
                    logit(lcl_vInfo,@"Start download for patch from %@",[currPatchToInstallDict objectForKey:@"url"]);
                    //Pre Proxy Config
                    downloadURL = [NSString stringWithFormat:@"http://%@/mp-content%@",mpServerConnection.HTTP_HOST,[currPatchToInstallDict objectForKey:@"url"]];
                    logit(lcl_vInfo,@"Download patch from: %@",downloadURL);
                    err = nil;
                    dlPatchLoc = [mpAsus downloadUpdate:downloadURL error:&err];
                    if (err) {
                        logit(lcl_vError,@"Error downloading a patch, skipping %@. Err Message: %@",[patch objectForKey:@"patch"],[err localizedDescription]);
                        break;
                    }
                    logit(lcl_vInfo,@"File downloaded to %@",dlPatchLoc);
                }
                @catch (NSException *e) {
                    logit(lcl_vError,@"%@", e);
                    break;
                }
                
                // *****************************
                // Validate hash, before install
                logit(lcl_vInfo,@"Validating downloaded patch.");
				_crypto = [[MPCrypto alloc] init];
                NSString *fileHash = [_crypto md5HashForFile:dlPatchLoc];
				[_crypto release];
				_crypto = nil;
                logit(lcl_vInfo,@"Downloaded file hash: %@ (%@)",fileHash,[currPatchToInstallDict objectForKey:@"hash"]);
                if ([[[currPatchToInstallDict objectForKey:@"hash"] uppercaseString] isEqualTo:[fileHash uppercaseString]] == NO) {
                    logit(lcl_vError,@"The downloaded file did not pass the file hash validation. No install will occur.");
                    continue;
                }
                
                // *****************************
                // Now we need to unzip
                logit(lcl_vInfo,@"Uncompressing patch, to begin install.");
                logit(lcl_vInfo,@"Begin decompression of file, %@",dlPatchLoc);
                err = nil;
                [mpAsus unzip:dlPatchLoc error:&err];
                if (err) {
                    logit(lcl_vError,@"Error decompressing a patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
                    break;
                }
                logit(lcl_vInfo,@"Patch has been decompressed.");
                
                // *****************************
                // Run PreInstall Script
                if ([[currPatchToInstallDict objectForKey:@"preinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"preinst"] isEqualTo:@"NA"] == NO) {
                    logit(lcl_vInfo,@"Begin pre install script.");
                    NSString *preInstScript = [[currPatchToInstallDict objectForKey:@"preinst"] decodeBase64WithNewLinesReturnString:NO];
                    logit(lcl_vDebug,@"preInstScript=%@",preInstScript);
                    
                    mpScript = [[MPScript alloc] init];
                    if ([mpScript runScript:preInstScript] == NO)
                    {
                        logit(lcl_vError,@"Error[%d] running pre-install script.",installResult);
                        [mpScript release];
                        mpScript = nil;
                        break;
                    }
                    [mpScript release];
                    mpScript = nil;
                }
                
                // *****************************
                // Install the update
                BOOL hadErr = NO;
                @try
				{
                    NSString *pkgPath;
                    NSString *pkgBaseDir = [dlPatchLoc stringByDeletingLastPathComponent];
                    NSPredicate *pkgPredicate = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
                    NSArray *pkgList = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[dlPatchLoc stringByDeletingLastPathComponent] error:NULL] filteredArrayUsingPredicate:pkgPredicate];
                    installResult = -1;
                    
                    // Install pkg(s)
                    for (int ii = 0; ii < [pkgList count]; ii++) {
                        pkgPath = [NSString stringWithFormat:@"%@/%@",pkgBaseDir,[pkgList objectAtIndex:ii]];
                        logit(lcl_vInfo,@"Installing %@",[pkgPath lastPathComponent]);
                        logit(lcl_vInfo,@"Start install of %@",pkgPath);
                        mpInstaller = [[MPInstaller alloc] init];
                        installResult = [mpInstaller installPkg:pkgPath target:@"/" env:[currPatchToInstallDict objectForKey:@"env"]];
                        if (installResult != 0) {
                            logit(lcl_vError,@"Error installing package, error code %d.",installResult);
                            hadErr = YES;
                            break;
                        } else {
                            logit(lcl_vInfo,@"%@ was installed successfully.",pkgPath);
                        }
                    } // End Loop
					
					
					// If the Patch we just installed needed a reboot ...
                    if ([[patch objectForKey:@"restart"] stringToBoolValue] == YES) {
						installedPatchesNeedingReboot++;
					}
                }
                @catch (NSException *e) {
                    logit(lcl_vError,@"%@", e);
                    logit(lcl_vError,@"Error attempting to install patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
                    break;
                }
                if (hadErr) {
                    // We had an error, try the next one.
                    continue;
                }
                
                // *****************************
                // Run PostInstall Script
                if ([[currPatchToInstallDict objectForKey:@"postinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"postinst"] isEqualTo:@"NA"] == NO) {
                    logit(lcl_vInfo,@"Begin post install script.");
                    NSString *postInstScript = [[currPatchToInstallDict objectForKey:@"postinst"] decodeBase64WithNewLinesReturnString:NO];
                    logit(lcl_vDebug,@"postInstScript=%@",postInstScript);
                    
                    mpScript = [[MPScript alloc] init];
                    if ([mpScript runScript:postInstScript] == NO)
                    {
                        logit(lcl_vError,@"Error[%d] running post-install script.",installResult);
                        [mpScript release];
                        mpScript = nil;
                        break;
                    }
                    [mpScript release];
                    mpScript = nil;
                }
                
                // *****************************
                // Instal is complete, post result to web service
                
                @try {
                    MPWebServices *mpws = [[[MPWebServices alloc] init] autorelease];
                    NSError *wsErr = nil;
                    [mpws postPatchInstallResultsToWebService:[patch objectForKey:@"patch_id"] patchType:@"third" error:&wsErr];
                    logit(lcl_vInfo,@"Posting patch (%@) install to web service.",[patch objectForKey:@"patch_id"]);
                    if (wsErr) {
                        logit(lcl_vError,@"%@", wsErr.localizedDescription);
                    }
                }
                @catch (NSException *e) {
                    logit(lcl_vError,@"%@", e);
                }
				
				if (iLoadMode == YES) {
					fprintf(stdout, "Completed: %s\n", [[patch objectForKey:@"patch"] cString]);
				}
				[self removeInstalledPatchFromCacheFile:[patch objectForKey:@"patch"]];
                logit(lcl_vInfo,@"Patch install completed.");
                
            } // End patchArray To install
            // ***************************************************************************************
            // Process Apple Type Patches
        } else if ([[patch objectForKey:@"type"] isEqualTo:@"Apple"] && (aFilter == 0 || aFilter == 1)) {
            //
            // ***************************************************************************************
            
            logit(lcl_vInfo,@"Starting install for %@",[patch objectForKey:@"patch"]);
            logit(lcl_vDebug,@"Apple Dict:%@",patch);
			
			if (iLoadMode == YES) {
				fprintf(stdout, "Begin: %s\n", [[patch objectForKey:@"patch"] cString]);
			}
            
            if ([[patch objectForKey:@"hasCriteria"] boolValue] == NO || ![patch objectForKey:@"hasCriteria"]) {
                
                mpInstaller = [[MPInstaller alloc] init];
                installResult = [mpInstaller installAppleSoftwareUpdate:[patch objectForKey:@"patch"]];
                [mpInstaller release];
                mpInstaller = nil;
                
            } else {
                logit(lcl_vInfo,@"%@ has install criteria assigned to it.",[patch objectForKey:@"patch"]);
                
                NSDictionary *criteriaDictPre, *criteriaDictPost;
                NSData *scriptData;
                NSString *scriptText;
                
                int i = 0;
                // PreInstall First
                if ([patch objectForKey:@"criteria_pre"]) {
                    logit(lcl_vInfo,@"Processing pre-install criteria.");
                    for (i=0;i<[[patch objectForKey:@"criteria_pre"] count];i++)
                    {
                        criteriaDictPre = [[patch objectForKey:@"criteria_pre"] objectAtIndex:i];
                        scriptData = [[criteriaDictPre objectForKey:@"data"] decodeBase64WithNewlines:NO];
                        scriptText = [[[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding] autorelease];
                        
                        mpScript = [[MPScript alloc] init];
                        if ([mpScript runScript:scriptText] == NO) {
                            installResult = 1;
                            logit(lcl_vError,@"Pre-install script returned false for %@. No install will occur.",[patch objectForKey:@"patch"]);
                            [mpScript release];
                            mpScript = nil;
                            goto instResult;
                        } else {
                            logit(lcl_vInfo,@"Pre-install script returned true.");
                        }
                        [mpScript release];
                        mpScript = nil;
                        criteriaDictPre = nil;
                    }
                }
                // Run the patch install, now that the install has occured.
                mpInstaller = [[MPInstaller alloc] init];
                installResult = [mpInstaller installAppleSoftwareUpdate:[patch objectForKey:@"patch"]];
                [mpInstaller release];
                mpInstaller = nil;
				
				// If the Patch Installed Required a Reboot, flag it
                if ([[patch objectForKey:@"restart"] stringToBoolValue] == YES) {
					installedPatchesNeedingReboot++;
				}
                
                // If Install retuened anything but 0, the dont run post criteria
                if (installResult != 0) {
                    logit(lcl_vError,@"The install for %@ returned an error.",[patch objectForKey:@"patch"]);
                    goto instResult;
                }
                
                if ([patch objectForKey:@"criteria_post"]) {
                    logit(lcl_vInfo,@"Processing post-install criteria.");
                    for (i=0;i<[[patch objectForKey:@"criteria_post"] count];i++)
                    {
                        criteriaDictPost = [[patch objectForKey:@"criteria_post"] objectAtIndex:i];
                        
                        scriptData = [[criteriaDictPost objectForKey:@"data"] decodeBase64WithNewlines:NO];
                        scriptText = [[[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding] autorelease];
                        
                        mpScript = [[MPScript alloc] init];
                        if ([mpScript runScript:scriptText] == NO) {
                            installResult = 1;
                            logit(lcl_vError,@"Post-install script returned false for %@. No install will occur.",[patch objectForKey:@"patch"]);
                            [mpScript release];
                            mpScript = nil;
                            goto instResult;
                        } else {
                            logit(lcl_vInfo,@"Post-install script returned true.");
                        }
                        [mpScript release];
                        mpScript = nil;
                        criteriaDictPost = nil;
                    }
                }
            }
            
        instResult:
            if (installResult != 0) {
                logit(lcl_vError,@"Error installing update, error code %d.",installResult);
                continue;
            } else {
                logit(lcl_vInfo,@"%@ was installed successfully.",[patch objectForKey:@"patch"]);
            }
            
            // Post the results to web service
            @try {
                MPWebServices *mpws = [[[MPWebServices alloc] init] autorelease];
                NSError *wsErr = nil;
                [mpws postPatchInstallResultsToWebService:[patch objectForKey:@"patch"] patchType:@"apple" error:&wsErr];
                logit(lcl_vInfo,@"Posting patch (%@) install to web service.",[patch objectForKey:@"patch"]);
                if (wsErr) {
                    logit(lcl_vError,@"%@", wsErr.localizedDescription);
                }
            }
            @catch (NSException *e) {
                logit(lcl_vError,@"%@", e);
            }
			
			if (iLoadMode == YES) {
				fprintf(stdout, "Completed: %s\n", [[patch objectForKey:@"patch"] cString]);
			}
            logit(lcl_vInfo,@"Patch install completed.");
        } else {
            continue;
        }
	} //End patchesToInstallArray For Loop
	
	// Update GUI to reflect new installs
	[[NSFileManager defaultManager] createFileAtPath:[CLIENT_PATCH_STATUS_FILE stringByExpandingTildeInPath]
											contents:[@"update" dataUsingEncoding:NSASCIIStringEncoding]
										  attributes:nil];
	
	// Open the Reboot App
    mpInstaller = [[[MPInstaller alloc] init] autorelease];
	
	// If any patches that were installed needed a reboot
	if (installedPatchesNeedingReboot > 0) {
        if (iLoadMode == YES) {
			logit(lcl_vInfo,@"Patches have been installed that require a reboot. Please reboot the systems as soon as possible.");
			goto done;
		}
		if (hasConsoleUserLoggedIn == NO) {
			if ([_defaults objectForKey:@"Reboot"]) {
				if ([[_defaults objectForKey:@"Reboot"] isEqualTo:@"1"]) {
					logit(lcl_vInfo,@"Patches have been installed that require a reboot. Rebooting system now.");
					int rb = 0;
					rb = reboot(RB_AUTOBOOT);
				} else {
					logit(lcl_vInfo,@"Patches have been installed that require a reboot. Please reboot the systems as soon as possible.");
					goto done;
				}
				
			}
		}
	}
	
	if (launchRebootWindow > 0) {
		logit(lcl_vInfo,@"Patches that require reboot need to be installed. Opening reboot dialog now.");
        // 10.9
        NSString *_atFile = @"/private/tmp/.MPAuthRun";
        NSString *_rbFile = @"/private/tmp/.MPRebootRun.plist";
		NSString *_rbText = @"reboot";
        // Mac OS X 10.9 Support, now using /private/tmp/.MPAuthRun
        NSDictionary *rebootPlist = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"reboot"];
        [rebootPlist writeToFile:_rbFile atomically:YES];
        [_rbText writeToFile:_atFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        NSDictionary *_fileAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:0777],@"NSFilePosixPermissions",nil];
		[fm setAttributes:_fileAttr ofItemAtPath:_rbFile error:NULL];
        [fm setAttributes:_fileAttr ofItemAtPath:_atFile error:NULL];
	}
    
done:
	[self removeTaskRunning:kMPPatchUPDATE];
}

-(void)scanAndUpdateCustomWithPatchBundleID:(NSString *)aPatchBundleID
{
    qldebug(@"scanAndUpdateCustomWithPatchBundleID:%@",aPatchBundleID);
    
	// Filter - 0 = All,  1 = Apple, 2 = Third
	NSArray *updatesArray = nil;
    NSArray *updatesArrayRaw = nil;
    
    // Scan for Patches
    //[self scanForPatchesWithFilter:2];
    [self scanForPatchUsingBundleID:aPatchBundleID];
    updatesArrayRaw = [NSArray arrayWithArray:approvedPatches];
    // Filter on bundle ID
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(bundleID == %@)", aPatchBundleID];
	updatesArray = [updatesArrayRaw filteredArrayUsingPredicate:p];
    
	if (!updatesArray) {
		logit(lcl_vInfo,@"Updates array is nil");
        [self removeTaskRunning:kMPPatchUPDATE];
        [self setErrorCode:0];
        return;
	}
    if ([updatesArray count] <= 0) {
        logit(lcl_vInfo, @"No approved patches to install.");
        logit(lcl_vDebug,@"updatesArray=%@",updatesArray);
		[self removeTaskRunning:kMPPatchUPDATE];
        [self setErrorCode:0];
        return;
    }
    
	// Check to see if client os type is allowed to perform updates.
	logit(lcl_vInfo, @"Validating client install status.");
	NSString *_osType = nil;
	_osType = [[MPSystemInfo osVersionInfo] objectForKey:@"ProductName"];
	if ([_osType isEqualToString:@"Mac OS X"]) {
		if ([_defaults objectForKey:@"allowClient"]) {
			if (![[_defaults objectForKey:@"allowClient"] isEqualToString:@"1"]) {
				logit(lcl_vInfo,@"Host is a Mac OS X Client and allowClient property is set to false. No updates will be applied.");
				[self removeTaskRunning:kMPPatchUPDATE];
                [self setErrorCode:0];
                return;
			}
		}
	}
    
	logit(lcl_vInfo, @"Validating server install status.");
	if ([_osType isEqualToString:@"Mac OS X Server"]) {
		if ([_defaults objectForKey:@"allowServer"]) {
			if (![[_defaults objectForKey:@"allowServer"] isEqualToString:@"1"]) {
				logit(lcl_vInfo,@"Host is a Mac OS X Server and allowServer property is set to false. No updates will be applied.");
				[self removeTaskRunning:kMPPatchUPDATE];
                [self setErrorCode:0];
                return;
			}
		} else {
			logit(lcl_vInfo,@"Host is a Mac OS X Server and allowServer property is not defined. No updates will be applied.");
			[self removeTaskRunning:kMPPatchUPDATE];
            [self setErrorCode:0];
            return;
		}
	}
    
    // Begin Patching Process
    int                 hadError = 0;
	MPCrypto			*_crypto;
    MPInstaller         *mpInstaller = nil;
    MPScript            *mpScript = nil;
    NSDictionary		*patch;
	NSDictionary		*currPatchToInstallDict;
	NSArray				*patchPatchesArray;
	NSString			*downloadURL;
	NSError				*err;
    
	int i;
	int installResult = 1;
	int	launchRebootWindow = 0;
	int installedPatchesNeedingReboot = 0;
    
    // Check for console user
	logit(lcl_vInfo, @"Checking for any logged in users.");
    BOOL hasConsoleUserLoggedIn = TRUE;
	@try {
		hasConsoleUserLoggedIn = [self isLocalUserLoggedIn];
	}
	@catch (NSException * e) {
		logit(lcl_vInfo, @"Error getting console user status. %@",e);
	}
	
	logit(lcl_vInfo, @"Begin installing patches.");
    for (i = 0; i < [updatesArray count]; i++) {
		// Create/Get Dictionary of Patch to install
		patch = nil;
		patch = [NSDictionary dictionaryWithDictionary:[updatesArray objectAtIndex:i]];
        
		if (hasConsoleUserLoggedIn == YES) {
            // Check if patch needs a reboot
            if ([[patch objectForKey:@"restart"] stringToBoolValue] == YES) {
                logit(lcl_vInfo,@"%@(%@) requires a reboot, this patch will be installed on logout.",[patch objectForKey:@"patch"],[patch objectForKey:@"version"]);
                launchRebootWindow++;
                continue;
            }
        }
        
        // Now proceed to the download and install
        installResult = -1;
        
        if ([[patch objectForKey:@"type"] isEqualTo:@"Third"]) {
            logit(lcl_vInfo,@"Starting install for %@",[patch objectForKey:@"patch"]);
			[self postNotificationTo:@"MPPatchStatusNotification" info:[NSString stringWithFormat:@"Begin patching %@",[patch objectForKey:@"patch"]] isGlobal:YES];
			if (iLoadMode == YES) {
				printf("Begin: %s\n", [[patch objectForKey:@"patch"] cString]);
			}
            
            // Get all of the patches, main and subs
            // This is messed up, not sure why I have an array right within an array, needs to be fixed ...later :-)
            patchPatchesArray = [NSArray arrayWithArray:[[patch objectForKey:@"patches"] objectForKey:@"patches"]];
            logit(lcl_vDebug,@"Current patch has total patches associated with it %ld", ([patchPatchesArray count]-1));
            
            NSString *dlPatchLoc; //Download location Path
            int patchIndex = 0;
            for (patchIndex=0; patchIndex < [patchPatchesArray count]; patchIndex++)
			{
                // Make sure we only process the dictionaries in the NSArray
                if ([[patchPatchesArray objectAtIndex:patchIndex] isKindOfClass:[NSDictionary class]]) {
                    currPatchToInstallDict = [NSDictionary dictionaryWithDictionary:[patchPatchesArray objectAtIndex:patchIndex]];
                } else {
                    logit(lcl_vInfo,@"Object found was not of dictionary type; could be a problem. %@",[patchPatchesArray objectAtIndex:patchIndex]);
                    continue;
                }
                // We have a currPatchToInstallDict to work with
                logit(lcl_vInfo,@"Start install for patch %@ from %@",[currPatchToInstallDict objectForKey:@"url"],[patch objectForKey:@"patch"]);
                
                // First we need to download the update
                @try {
                    logit(lcl_vInfo,@"Start download for patch from %@",[currPatchToInstallDict objectForKey:@"url"]);
                    [self postNotificationTo:@"MPPatchStatusNotification" info:[NSString stringWithFormat:@"Downloading patch %@",[patch objectForKey:@"patch"]] isGlobal:YES];
                    //Pre Proxy Config
                    downloadURL = [NSString stringWithFormat:@"http://%@/mp-content%@",mpServerConnection.HTTP_HOST,[currPatchToInstallDict objectForKey:@"url"]];
                    logit(lcl_vInfo,@"Download patch from: %@",downloadURL);
                    err = nil;
                    dlPatchLoc = [mpAsus downloadUpdate:downloadURL error:&err];
                    if (err) {
                        logit(lcl_vError,@"Error downloading a patch, skipping %@. Err Message: %@",[patch objectForKey:@"patch"],[err localizedDescription]);
                        break;
                    }
                    logit(lcl_vInfo,@"File downloaded to %@",dlPatchLoc);
                }
                @catch (NSException *e) {
                    logit(lcl_vError,@"%@", e);
                    hadError++;
                    break;
                }
                // *****************************
                // Validate hash, before install
                logit(lcl_vInfo,@"Validating downloaded patch.");
				_crypto = [[MPCrypto alloc] init];
                NSString *fileHash = [_crypto md5HashForFile:dlPatchLoc];
				[_crypto release];
				_crypto = nil;
                logit(lcl_vInfo,@"Downloaded file hash: %@ (%@)",fileHash,[currPatchToInstallDict objectForKey:@"hash"]);
                if ([[[currPatchToInstallDict objectForKey:@"hash"] uppercaseString] isEqualTo:[fileHash uppercaseString]] == NO) {
                    logit(lcl_vError,@"The downloaded file did not pass the file hash validation. No install will occur.");
                    hadError++;
                    continue;
                }
                // *****************************
                // Now we need to unzip
                logit(lcl_vInfo,@"Uncompressing patch, to begin install.");
                logit(lcl_vInfo,@"Begin decompression of file, %@",dlPatchLoc);
                err = nil;
                [mpAsus unzip:dlPatchLoc error:&err];
                if (err) {
                    logit(lcl_vError,@"Error decompressing a patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
                    hadError++;
                    break;
                }
                logit(lcl_vInfo,@"Patch has been decompressed.");
                // *****************************
                // Run PreInstall Script
                if ([[currPatchToInstallDict objectForKey:@"preinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"preinst"] isEqualTo:@"NA"] == NO) {
                    logit(lcl_vInfo,@"Begin pre install script.");
                    NSString *preInstScript = [[currPatchToInstallDict objectForKey:@"preinst"] decodeBase64WithNewLinesReturnString:NO];
                    logit(lcl_vDebug,@"preInstScript=%@",preInstScript);
                    
                    mpScript = [[MPScript alloc] init];
                    if ([mpScript runScript:preInstScript] == NO)
                    {
                        logit(lcl_vError,@"Error[%d] running pre-install script.",installResult);
                        [mpScript release];
                        mpScript = nil;
                        hadError++;
                        break;
                    }
                    [mpScript release];
                    mpScript = nil;
                }
                // *****************************
                // Install the update
                BOOL hadErr = NO;
                @try
				{
                    NSString *pkgPath;
                    NSString *pkgBaseDir = [dlPatchLoc stringByDeletingLastPathComponent];
                    NSPredicate *pkgPredicate = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
                    NSArray *pkgList = [[fm contentsOfDirectoryAtPath:[dlPatchLoc stringByDeletingLastPathComponent] error:NULL] filteredArrayUsingPredicate:pkgPredicate];
                    installResult = -1;
                    
                    // Install pkg(s)
                    for (int ii = 0; ii < [pkgList count]; ii++) {
                        pkgPath = [NSString stringWithFormat:@"%@/%@",pkgBaseDir,[pkgList objectAtIndex:ii]];
                        [self postNotificationTo:@"MPPatchStatusNotification" info:[NSString stringWithFormat:@"Installing patch %@",[pkgPath lastPathComponent]] isGlobal:YES];
                        logit(lcl_vInfo,@"Installing %@",[pkgPath lastPathComponent]);
                        logit(lcl_vInfo,@"Start install of %@",pkgPath);
                        mpInstaller = [[MPInstaller alloc] init];
                        installResult = [mpInstaller installPkg:pkgPath target:@"/" env:[currPatchToInstallDict objectForKey:@"env"]];
                        if (installResult != 0) {
                            logit(lcl_vError,@"Error installing package, error code %d.",installResult);
                            hadErr = YES;
                            hadError++;
                            break;
                        } else {
                            logit(lcl_vInfo,@"%@ was installed successfully.",pkgPath);
                        }
                    } // End Loop
					
					
					// If the Patch we just installed needed a reboot ...
					if ([[patch objectForKey:@"restart"] stringToBoolValue] == YES) {
						installedPatchesNeedingReboot++;
					}
                }
                @catch (NSException *e) {
                    logit(lcl_vError,@"%@", e);
                    logit(lcl_vError,@"Error attempting to install patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
                    hadError++;
                    break;
                }
                if (hadErr) {
                    // We had an error, try the next one.
                    continue;
                }
                // *****************************
                // Run PostInstall Script
                if ([[currPatchToInstallDict objectForKey:@"postinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"postinst"] isEqualTo:@"NA"] == NO) {
                    logit(lcl_vInfo,@"Begin post install script.");
                    NSString *postInstScript = [[currPatchToInstallDict objectForKey:@"postinst"] decodeBase64WithNewLinesReturnString:NO];
                    logit(lcl_vDebug,@"postInstScript=%@",postInstScript);
                    
                    mpScript = [[MPScript alloc] init];
                    if ([mpScript runScript:postInstScript] == NO)
                    {
                        logit(lcl_vError,@"Error[%d] running post-install script.",installResult);
                        [mpScript release];
                        mpScript = nil;
                        break;
                    }
                    [mpScript release];
                    mpScript = nil;
                }
                // *****************************
                // Instal is complete, post result to web service
                @try {
                    MPWebServices *mpws = [[[MPWebServices alloc] init] autorelease];
                    NSError *wsErr = nil;
                    logit(lcl_vInfo,@"Posting patch (%@) install to web service.",[patch objectForKey:@"patch_id"]);
                    [mpws postPatchInstallResultsToWebService:[patch objectForKey:@"patch_id"] patchType:@"third" error:&wsErr];
                    if (wsErr) {
                        logit(lcl_vError,@"%@", wsErr.localizedDescription);
                    }
                }
                @catch (NSException *e) {
                    logit(lcl_vError,@"%@", e);
                }
				
				if (iLoadMode == YES) {
					fprintf(stdout, "Completed: %s\n", [[patch objectForKey:@"patch"] cString]);
				}
				[self removeInstalledPatchFromCacheFile:[patch objectForKey:@"patch"]];
                [self postNotificationTo:@"MPPatchStatusNotification" info:@"Patch install completed." isGlobal:YES];
                logit(lcl_vInfo,@"Patch install completed.");
                
            } // End patchArray To install
        }
	} //End patchesToInstallArray For Loop
	
	// Update GUI to reflect new installs
	[fm createFileAtPath:[CLIENT_PATCH_STATUS_FILE stringByExpandingTildeInPath]
                contents:[@"update" dataUsingEncoding:NSASCIIStringEncoding]
              attributes:nil];
	
	// Open the Reboot App
    
	
	// If any patches that were installed needed a reboot
	if (installedPatchesNeedingReboot > 0) {
		if (hasConsoleUserLoggedIn == NO) {
			if ([_defaults objectForKey:@"Reboot"]) {
				if ([[_defaults objectForKey:@"Reboot"] isEqualTo:@"1"]) {
					logit(lcl_vInfo,@"Patches have been installed that require a reboot. Rebooting system now.");
					int rb = 0;
					rb = reboot(RB_AUTOBOOT);
				} else {
					logit(lcl_vInfo,@"Patches have been installed that require a reboot. Please reboot the systems as soon as possible.");
					goto done;
				}
				
			}
		}
	}
	
	if (launchRebootWindow > 0)
    {
		logit(lcl_vInfo,@"Patches that require reboot need to be installed. Opening reboot dialog now.");
        // 10.9 support
        NSString *_atFile = @"/private/tmp/.MPAuthRun";
        NSString *_rbFile = @"/private/tmp/.MPRebootRun.plist";
		NSString *_rbText = @"reboot";
        // Mac OS X 10.9 Support, now using /private/tmp/.MPAuthRun
        NSDictionary *rebootPlist = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"reboot"];
        [rebootPlist writeToFile:_rbFile atomically:YES];
        [_rbText writeToFile:_atFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        NSDictionary *_fileAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:0777],@"NSFilePosixPermissions",nil];
		[fm setAttributes:_fileAttr ofItemAtPath:_rbFile error:NULL];
        [fm setAttributes:_fileAttr ofItemAtPath:_atFile error:NULL];
	}
    
done:
    [self setErrorCode:hadError];
	[self removeTaskRunning:kMPPatchUPDATE];
}

-(BOOL)checkPatchPreAndPostForRebootRequired:(NSArray *)aDictArray
{
	BOOL result = NO;
	int x = 0;
	// Look for reboots in other patches attached
	for (x = 0; x < [aDictArray count];x++) {
		if ([[[aDictArray objectAtIndex:x] objectForKey:@"reboot"] isEqualTo:@"Yes"]) {
			result = YES;
			break;
		}
	}
	
	return result;
}

- (void)removeInstalledPatchFromCacheFile:(NSString *)aPatchName
{
	NSString *_approvedPatchesFile = [NSString stringWithFormat:@"%@/Data/.approvedPatches.plist",MP_ROOT_CLIENT];
	if ([fm fileExistsAtPath:_approvedPatchesFile] == NO) {
		// No file, nothing todo.
		return;
	}
    
	NSMutableArray *_patchesArray = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:_approvedPatchesFile]];
	if ([_patchesArray count] <= 0) {
		// No Items in the Array, delete the file
		[fm removeItemAtPath:_approvedPatchesFile error:NULL];
		return;
	}
	
	NSDictionary *_patchDict;
	for (int i = 0; i < [_patchesArray count]; i++)
	{
		_patchDict = [NSDictionary dictionaryWithDictionary:[_patchesArray objectAtIndex:i]];
		if ([[_patchDict objectForKey:@"patch"] isEqualToString:aPatchName]) {
			[_patchesArray removeObjectAtIndex:i];
			break;
		}
	}
    
	if ([_patchesArray count] <= 0) {
		// No Items in the Array, delete the file
		[fm removeItemAtPath:_approvedPatchesFile error:NULL];
		return;
	} else {
        [NSKeyedArchiver archiveRootObject:_patchesArray toFile:_approvedPatchesFile];
	}
	
	return;
}

-(void)scanForAVDefs
{
	if ([self isTaskRunning:kMPAVUpdate]) {
		logit(lcl_vInfo,@"Scanning for av defs is already running. Now exiting.");
		return;
	} else {
		[self writeTaskRunning:kMPAVUpdate];
	}
	
	logit(lcl_vInfo,@"Begin scan for AV defs.");
	MPAntiVirus *mpav = [[MPAntiVirus alloc] initWithServerConnection:mpServerConnection];
	[mpav scanDefs];
	[mpav release];
	mpav = nil;
	logit(lcl_vInfo,@"Scan for AV defs complete.");
	[self removeTaskRunning:kMPAVUpdate];
}

-(void)scanForAVDefsAndUpdate
{
	if ([self isTaskRunning:kMPAVUpdate]) {
		logit(lcl_vInfo,@"Updating av defs is already running. Now exiting.");
		return;
	} else {
		[self writeTaskRunning:kMPAVUpdate];
	}
	
	logit(lcl_vInfo,@"Begin scan and update for AV defs.");
	MPAntiVirus *mpav = [[MPAntiVirus alloc] initWithServerConnection:mpServerConnection];
	[mpav scanAndUpdateDefs];
	[mpav release];
	mpav = nil;
	logit(lcl_vInfo,@"Scan and update for AV defs complete.");
	[self removeTaskRunning:kMPAVUpdate];
}

-(void)scanAndUpdateAgentUpdater
{
	logit(lcl_vInfo,@"Begin checking for agent updates.");
	NSDictionary *updateDataRaw = [self getAgentUpdaterInfo];
	if (!updateDataRaw) {
		logit(lcl_vError,@"Unable to get update data needed.");
		return;
	}

    // Check to make sure the object is the right type
    // This needs to be fixed in the next version.
    if (![updateDataRaw isKindOfClass:[NSDictionary class]])
    {
        logit(lcl_vError,@"Agent updater info is not available.");
        return;
    }

    // Check if update needed
	if (![updateDataRaw objectForKey:@"updateAvailable"] || [[updateDataRaw objectForKey:@"updateAvailable"] boolValue] == NO) {
		logit(lcl_vInfo,@"No update needed.");
		return;
	}
	
	if (![updateDataRaw objectForKey:@"SelfUpdate"]) {
		logit(lcl_vError,@"No update data found.");
		return;
	}
	
	NSDictionary *updateData = [NSDictionary dictionaryWithDictionary:[updateDataRaw objectForKey:@"SelfUpdate"]];
	
	NSError *err = nil;
	NSString *downloadURL;
	NSString *downloadFileLoc;
	
	// *****************************
	// First we need to download the update
	@try {
		logit(lcl_vInfo,@"Start download for patch from %@",[updateData objectForKey:@"pkg_Url"]);
		//Pre Proxy Config
		downloadURL = [NSString stringWithFormat:@"http://%@%@",mpServerConnection.HTTP_HOST,[updateData objectForKey:@"pkg_Url"]];
		logit(lcl_vInfo,@"Download patch from: %@",downloadURL);
		err = nil;
		downloadFileLoc = [mpAsus downloadUpdate:downloadURL error:&err];
		if (err) {
			logit(lcl_vError,@"Error downloading update %@. Err Message: %@",[downloadURL lastPathComponent],[err localizedDescription]);
			return;
		}
		logit(lcl_vInfo,@"File downloaded to %@",downloadFileLoc);
	}
	@catch (NSException *e) {
		logit(lcl_vError,@"%@", e);
		return;
	}
	
	// *****************************
	// Validate hash, before install
	logit(lcl_vInfo,@"Validating downloaded patch.");
	MPCrypto *_crypto = [[MPCrypto alloc] init];
	NSString *fileHash = [_crypto sha1HashForFile:downloadFileLoc];
	[_crypto release];
	_crypto = nil;
	logit(lcl_vInfo,@"Validating download file.");
	logit(lcl_vDebug,@"Downloaded file hash: (%@) (%@)",fileHash,[updateData objectForKey:@"pkg_Hash"]);
	logit(lcl_vDebug,@"%@",updateData);
	if ([[[updateData objectForKey:@"pkg_Hash"] uppercaseString] isEqualToString:[fileHash uppercaseString]] == NO) {
		logit(lcl_vError,@"The downloaded file did not pass the file hash validation. No install will occur.");
		return;
	}
	
	// *****************************
	// Now we need to unzip
	logit(lcl_vInfo,@"Uncompressing patch, to begin install.");
	logit(lcl_vInfo,@"Begin decompression of file, %@",downloadFileLoc);
	err = nil;
	[mpAsus unzip:downloadFileLoc error:&err];
	if (err) {
		logit(lcl_vError,@"Error decompressing a update %@. Err Message:%@",[downloadURL lastPathComponent],[err localizedDescription]);
		return;
	}
	logit(lcl_vInfo,@"Update has been decompressed.");
	
	// *****************************
	// Install the update
	BOOL hadErr = NO;
	@try
	{
		NSString *pkgPath;
		NSString *pkgBaseDir = [downloadFileLoc stringByDeletingLastPathComponent];
		NSPredicate *pkgPredicate = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
		NSArray *pkgList = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[downloadFileLoc stringByDeletingLastPathComponent] error:NULL] filteredArrayUsingPredicate:pkgPredicate];
		int installResult = -1;
		MPInstaller *mpInstaller;
		
		// Install pkg(s)
		for (int ii = 0; ii < [pkgList count]; ii++) {
			pkgPath = [NSString stringWithFormat:@"%@/%@",pkgBaseDir,[pkgList objectAtIndex:ii]];
			logit(lcl_vInfo,@"Installing %@",[pkgPath lastPathComponent]);
			logit(lcl_vInfo,@"Start install of %@",pkgPath);
			mpInstaller = [[MPInstaller alloc] init];
			installResult = [mpInstaller installPkgToRoot:pkgPath];
			if (installResult != 0) {
				logit(lcl_vError,@"Error installing package, error code %d.",installResult);
				hadErr = YES;
				[mpInstaller release];
				break;
			} else {
				logit(lcl_vInfo,@"%@ was installed successfully.",pkgPath);
				[mpInstaller release];
			}
		} // End Loop
	}
	@catch (NSException *e) {
		logit(lcl_vError,@"%@", e);
		logit(lcl_vError,@"Error attempting to install update %@. Err Message:%@",[downloadURL lastPathComponent],[err localizedDescription]);
	}
	
	logit(lcl_vInfo,@"Checking for agent updates completed.");
	return;
}

- (NSDictionary *)getAgentUpdaterInfo
{
	NSString *updateAppPath = [MP_ROOT stringByAppendingPathComponent:@"Updater/MPAgentUp2Date"];
	
	NSError *error = nil;
	NSString *verString = @"0";
	MPNSTask *mpr = [[MPNSTask alloc] init];
	
	// If no or valid MP signature, replace and install
	if ([MPCodeSign checkSignature:updateAppPath]) {
		verString = [mpr runTask:updateAppPath binArgs:[NSArray arrayWithObjects:@"-v", nil] error:&error];
		if (error) {
			logit(lcl_vError,@"%@",[error description]);
			verString = @"0";
		}
	}
	
	// Check for updates
    MPWebServices *mpws = [[[MPWebServices alloc] init] autorelease];
    NSError *wsErr = nil;
    NSDictionary *result = [mpws getAgentUpdaterUpdates:verString error:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"%@",wsErr);
        return nil;
    }
    [mpr release];
    return result;
}

- (BOOL)isTaskRunning:(NSString *)aTaskName
{
	if (forceRun == YES) {
		return NO;
	}
	
	if ([aTaskName isEqualToString:@".mpScanRunning"]) {
		if ([fm fileExistsAtPath:@"/tmp/.mpScanRunning"]) {
			return YES;
		}
	}
	if ([aTaskName isEqualToString:@".mpUpdateRunning"]) {
		if ([fm fileExistsAtPath:@"/tmp/.mpUpdateRunning"]) {
			return YES;
		}
	}
	if ([aTaskName isEqualToString:@".mpInventoryRunning"]) {
		if ([fm fileExistsAtPath:@"/tmp/.mpInventoryRunning"]) {
			return YES;
		}
	}
	if ([aTaskName isEqualToString:@".mpAVUpdateRunning"]) {
		if ([fm fileExistsAtPath:@"/tmp/.mpAVUpdateRunning"]) {
			return YES;
		}
	}
	
	return NO;
}

-(void)writeTaskRunning:(NSString *)aTaskName
{
	if (forceRun == NO) {
		NSString *_id = [[NSProcessInfo processInfo] globallyUniqueString];
		[_id writeToFile:[@"/tmp" stringByAppendingPathComponent:aTaskName] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	}
}

-(void)removeTaskRunning:(NSString *)aTaskName
{
	logit(lcl_vInfo,@"Remove Task Running file for %@.",aTaskName);
	if ([fm fileExistsAtPath:[@"/tmp" stringByAppendingPathComponent:aTaskName]]) {
		logit(lcl_vInfo,@"File exists %@",aTaskName);
		logit(lcl_vDebug,@"File exists %@",[@"/tmp" stringByAppendingPathComponent:aTaskName]);
		if (forceRun == NO) {
			logit(lcl_vInfo,@"File remove %@",aTaskName);
			logit(lcl_vDebug,@"File remove %@",[@"/tmp" stringByAppendingPathComponent:aTaskName]);
			NSError *err = nil;
			[fm removeItemAtPath:[@"/tmp" stringByAppendingPathComponent:aTaskName] error:&err];
			if (err) {
				logit(lcl_vError,@"File remove %@\nError=%@",[@"/tmp" stringByAppendingPathComponent:aTaskName],[err description]);
			}
		} else {
			logit(lcl_vInfo,@"Force run is set to true for %@. No file will be removed.",aTaskName);
		}
	}
}

- (BOOL)isLocalUserLoggedIn
{
	BOOL result = YES;
	
	SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, NULL, NULL, NULL);
	CFStringRef consoleUserName;
    consoleUserName = SCDynamicStoreCopyConsoleUser(store, NULL, NULL);
	
    if (consoleUserName != NULL)
    {
		logit(lcl_vInfo,@"%@ is currently logged in.",(NSString *)consoleUserName);
        CFRelease(consoleUserName);
    } else {
		result = NO;
	}
    
    return result;
}

-(void)postNotificationTo:(NSString *)aName info:(NSString *)info isGlobal:(BOOL)glb;
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:info, @"status", nil];
	if (glb) {
		qldebug(@"sendNotificationTo(G): %@ with %@",aName,options);
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:aName object:nil userInfo:options options:NSNotificationPostToAllSessions];
	} else {
        qldebug(@"sendNotificationTo: %@ with %@",aName,options);
		[[NSNotificationCenter defaultCenter] postNotificationName:aName object:nil userInfo:options];
	}
}

@end
