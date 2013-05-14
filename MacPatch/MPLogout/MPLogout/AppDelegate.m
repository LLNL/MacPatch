//
//  MPLogoutAppDelegate.m
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

#import "AppDelegate.h"
#import "EventToSend.h"
#import "MacPatch.h"
#import "MPInstallTask.h"
#import "MPLogout.h"

#include <stdlib.h>
#include <unistd.h>
#include <sys/reboot.h>


#define	MPLOGOUT_LOG		@"/Library/MacPatch/Client/Logs/MPLogout.log"


@implementation AppDelegate

@synthesize installStatusText;
@synthesize installStatusOutput;
@synthesize numberOfUpdatesNeeded;
@synthesize numberOfUpdatesInstalled;
@synthesize secondsTilReboot;
@synthesize installTaskIsRunning;
@synthesize tableView;
@synthesize arrayController;

- (void)dealloc 
{
	[catObj release];
	[mps release];
	
	[installStatusText autorelease];
    [installStatusOutput autorelease];
    [tableView autorelease];
    [arrayController autorelease];
	
	[super dealloc];
}


#pragma mark -

- (void)awakeFromNib
{
	// This prevents Self Patch from auto relaunching after reboot/logout
	if (floor(NSAppKitVersionNumber) > 1038 /* 10.6 */) {
        @try {
            NSApplication *a = [NSApplication sharedApplication];
            [a disableRelaunchOnLogin];
        }
        @catch (NSException * e) {
            // Nothing
        }
    }
    
	mpServerConnection = [[MPServerConnection alloc] init];
	[window center];
	[self setupDrawer];
	
	// Display version number
	NSString *vAppVer = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	[appVerText setStringValue:[NSString stringWithFormat:@"MPLogout v.%@",vAppVer]];
	
	// Bring the application to the front most app
	ProcessSerialNumber myPSN;
	GetCurrentProcess(&myPSN);
	SetFrontProcess(&myPSN);
	
	[progressWheel startAnimation:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{	
	BOOL enableDebug = NO;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *appPrefsPath = @"/Library/Preferences/gov.llnl.mplogout.plist";
	if ([fileManager fileExistsAtPath:appPrefsPath] == YES) {		
		NSDictionary *appPrefs = [NSDictionary dictionaryWithContentsOfFile:appPrefsPath];
		BOOL containsKey = ([appPrefs objectForKey:@"DeBug"] != nil);
		if (containsKey) {
			enableDebug = [[appPrefs objectForKey:@"DeBug"] boolValue];
		}	
	}
    
    // Setup logging
    NSString *_logFile = [NSString stringWithFormat:@"%@/Logs/MPLogout.log",MP_ROOT_CLIENT];
	[MPLog setupLogging:_logFile level:lcl_vDebug];
	
	if (enableDebug) {
		// enable logging for all components up to level Debug
		lcl_configure_by_name("*", lcl_vDebug);
		logit(lcl_vInfo,@"***** MPLogout started -- Debug Enabled *****");
	} else {
		// enable logging for all components up to level Info
		lcl_configure_by_name("*", lcl_vInfo);
		logit(lcl_vInfo,@"***** MPLogout started *****");
	}
	
	logit(lcl_vInfo,@"MPLogout v.%@",[appVerText stringValue]);
	
	[window center];
	
	ProcessSerialNumber myPSN;
	GetCurrentProcess(&myPSN);
	SetFrontProcess(&myPSN);
	
	[progressBar setUsesThreadedAnimation:YES];
	[progressBar startAnimation:nil];
    
	mps = [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:WS_NAMESPACE];
	catObj = [[MPASUSCatalogs alloc] initWithServerConnection:mpServerConnection];
	
	[NSThread detachNewThreadSelector:@selector(runSwuai) toTarget:self withObject:nil];
	[self setNumberOfUpdatesInstalled:0];
	
	installIsRunning = NO;
	installTask = nil;
}

#pragma mark -
#pragma mark Drawer
- (void)setupDrawer 
{
    [infoDrawer setMinContentSize:NSMakeSize(400, 400)];
    [infoDrawer setMaxContentSize:NSMakeSize(400, 400)];
}

- (void)openDrawer:(id)sender 
{
	[infoDrawer openOnEdge:NSMinYEdge];
	[infoDrawer centerSelectionInVisibleArea:nil];
}

- (void)closeDrawer:(id)sender 
{
	[infoDrawer close];
}

- (void)toggleDrawer:(id)sender 
{
    NSDrawerState state = [infoDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
        [infoDrawer close];
    } else {
        [infoDrawer openOnEdge:NSMinYEdge];
    }
}

- (IBAction)disclosureTrianglePressed:(id)sender
{
	[self toggleDrawer:nil];
}

#pragma mark -
#pragma mark Class Method

-(NSArray *)scanHostForPatches
{
	logit(lcl_vInfo,@"Preparing to scan host for patches.");
	
	// Method Valiables
	NSMutableArray *approvedUpdatesArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpDict;
	
	MPAsus		*asus		= [[MPAsus alloc] initWithServerConnection:mpServerConnection];
	MPSoap		*soap		= [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:WS_NAMESPACE];
	
	// Get Patch Group Patches
	logit(lcl_vInfo,@"Getting approved patch list for client.");
	NSDictionary *patchGroupPatches = [asus getPatchGroupPatches:[mpServerConnection.mpDefaults objectForKey:@"PatchGroup"] encode:YES];
	if (!patchGroupPatches) {
		logit(lcl_vError,@"There was a issue getting the approved patches for the patch group, scan will exit.");
		logit(lcl_vDebug,@"%@",patchGroupPatches);
		goto done;
	}
	NSArray *approvedApplePatches = [patchGroupPatches objectForKey:@"AppleUpdates"];
	NSArray *approvedCustomPatches = [patchGroupPatches objectForKey:@"CustomUpdates"]; 
	
	// Scan for Apple Patches
	NSArray *applePatchesArray = nil;
	applePatchesArray = [self scanForAppleUpdates];
	
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
				logit(lcl_vInfo,@"No Patch Group patches found.");
				logit(lcl_vInfo,@"No apple updates found for \"%@\" patch group.",[mpServerConnection.mpDefaults objectForKey:@"PatchGroup"]);
			} else {
				// Build Approved Patches
				logit(lcl_vInfo,@"Building approved patch list...");
				for (int i=0; i<[applePatchesArray count]; i++) {
					for (int x=0;x < [approvedApplePatches count]; x++) {
						if ([[[approvedApplePatches objectAtIndex:x] objectForKey:@"name"] isEqualTo:[[applePatchesArray objectAtIndex:i] objectForKey:@"patch"]]) {
							logit(lcl_vInfo,@"Patch %@ approved for update.",[[approvedApplePatches objectAtIndex:x] objectForKey:@"name"]);
							tmpDict = [[NSMutableDictionary alloc] init];
							[tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"patch"] forKey:@"patch"];
							[tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"description"] forKey:@"description"];
							[tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"reboot"] forKey:@"restart"];
							[tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"version"] forKey:@"version"];
							
							[tmpDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"hasCriteria"] forKey:@"hasCriteria"];
							if ([[[approvedApplePatches objectAtIndex:x] objectForKey:@"hasCriteria"] boolValue] == YES) {
								if ([[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] && [[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] count] > 0) {
									[tmpDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] forKey:@"criteria_pre"];
								}
								if ([[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] && [[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] count] > 0) {
									[tmpDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] forKey:@"criteria_post"];
								}
							}
							
							[tmpDict setObject:@"Apple" forKey:@"type"];
							
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
	
	// Scan for Custom Patches to see what is relevant for the system
	MPPatchScan *patchScanObj = [[MPPatchScan alloc] init];	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(scanForNotification:)
												 name: @"ScanForNotification"
											   object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(scanForNotificationFinished:)
												 name: @"ScanForNotificationFinished"
											   object: nil];
	
	NSMutableArray *customPatchesArray = [NSMutableArray arrayWithArray:[patchScanObj scanForPatches:soap]];
	
	logit(lcl_vDebug,@"Custom Patches Needed: %@",customPatchesArray);
	logit(lcl_vDebug,@"Approved Custom Patches: %@",approvedCustomPatches);
	
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
				
				logit(lcl_vDebug,@"Custom Patch Dictionary Added: %@",tmpDict);
				[approvedUpdatesArray addObject:tmpDict];
				[tmpDict release];
				break;
			}
		}	
	}
	
	logit(lcl_vDebug,@"Approved patches to install: %@",approvedUpdatesArray);
	[patchScanObj release];
	
done:	
	
	[soap release];
	[asus release];
	return [approvedUpdatesArray autorelease];
}

- (NSArray *)scanForAppleUpdates
{
	if (![catObj checkAndSetCatalogURL]) {
		logit(lcl_vError,@"There was an error checking and setting the ASUS catalog.");
	}
	
	[statusText setStringValue:@"Scanning for Apple software updates."];
	logit(lcl_vInfo,@"Scanning for Apple software updates.");
	
	NSArray *appleUpdates = nil;
	NSTask *l_task = [[[NSTask alloc] init] autorelease];
    [l_task setLaunchPath: ASUS_BIN_PATH];
    [l_task setArguments: [NSArray arrayWithObjects: @"-l", nil]];
	
    NSPipe *pipe = [NSPipe pipe];
    [l_task setStandardOutput: pipe];
    [l_task setStandardError: pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
    [l_task launch];
	logit(lcl_vInfo,@"Starting Apple software update scan.");
	[l_task waitUntilExit];
	
	int l_status = [l_task terminationStatus];
	if (l_status != 0) {
		logit(lcl_vError,@"Error: softwareupdate exit code = %d",l_status);
		return appleUpdates;
	} else {
		[statusText setStringValue:@"Scanning for Apple software updates."];
		logit(lcl_vInfo,@"Apple software update scan was completed.");
	}
	
	NSData *data = [file readDataToEndOfFile];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	
	logit(lcl_vDebug,@"Apple software update full scan results\n%@",string);
	
	if (!([string rangeOfString:@"No new"].location == NSNotFound)) {
		[statusText setStringValue:@"No Apple updates needed"];
		logit(lcl_vInfo,@"No new updates.");
		return appleUpdates;
	}
	
	// We have updates so we need to parse the results
	NSArray *strArr = [NSArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
	
	NSMutableArray *tmpAppleUpdates = [[NSMutableArray alloc] init];
	NSString *tmpStr;
	NSMutableDictionary *tmpDict;
	
	for (int i=0; i<[strArr count]; i++) {
		// Ignore empty lines
		if ([[strArr objectAtIndex:i] length] != 0) {
			
			//Clear the tmpDict object before populating it
			if (!([[strArr objectAtIndex:i] rangeOfString:@"Software Update Tool"].location == NSNotFound)) {
				continue;
			}
			if (!([[strArr objectAtIndex:i] rangeOfString:@"Copyright"].location == NSNotFound)) {
				continue;
			}	
			
			// Strip the White Space and any New line data
			tmpStr = [[strArr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			// If the object/string starts with *,!,- then allow it 
			if ([[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"*"] || [[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"!"] || [[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"-"]) {
				tmpDict = [[NSMutableDictionary alloc] init];
				logit(lcl_vInfo,@"Apple Update: %@",[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))]);
				[tmpDict setObject:[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))] forKey:@"patch"];
				[tmpDict setObject:[[[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))] componentsSeparatedByString:@"-"] lastObject] forKey:@"version"];
				[tmpDict setObject:[[strArr objectAtIndex:(i+1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"description"];
				if ([[[strArr objectAtIndex:(i+1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] containsString:@"[restart]" ignoringCase:YES] == TRUE) {
					[tmpDict setObject:@"TRUE" forKey:@"reboot"];
				} else {
					[tmpDict setObject:@"FALSE" forKey:@"reboot"];
				}
				
				[tmpAppleUpdates addObject:tmpDict];
				[tmpDict release];
			} // if is an update
		} // if / empty lines
	} // for loop
	appleUpdates = [NSArray arrayWithArray:tmpAppleUpdates];
	[tmpAppleUpdates release];
	
	logit(lcl_vDebug,@"Apple Updates Found, %@",appleUpdates);
	return appleUpdates;
}

- (void)scanForNotification:(NSNotification *)notification
{
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		[statusText setStringValue:[NSString stringWithFormat:@"Scanning for %@",[tmpDict objectForKey:@"pname"]]];
		[statusText display];
	}	
}

- (void)scanForNotificationFinished:(NSNotification *)notification
{
	NSNumber *patchesNeeded;
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		patchesNeeded = [tmpDict objectForKey:@"patchesNeeded"];
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}	
}

- (void)beginWatchStringThread
{
    [NSThread detachNewThreadSelector:@selector(watchStringThread) toTarget:self withObject:nil];
}

- (void)watchStringThread
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *str;
	int strCount = -1;
	for (;;)
	{
		str = [NSString stringWithString:[[MPLogout sharedManager] g_InstallStatusStr]];
		if (strCount != [str length])
		{
			[self appendStatusString:str];
		}
		strCount = (int)[str length];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
    [pool release];
}

-(void)runSwuai
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSRunLoop currentRunLoop] run];
	
	[[NSNotificationCenter defaultCenter] addObserver:nil 
											 selector:@selector(installStatusNotify:) 
												 name:NULL 
											   object:nil];
	
	[arrayController removeObjects:[arrayController arrangedObjects]];
	[tableView reloadData];
	
	
    NSArray *approvedUpdatesArray;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *updateFilePath = [NSString stringWithFormat:@"%@/Data/.approvedPatches.plist",MP_ROOT_CLIENT];
    
    /*  Check to see if we have a patch scan file within the last 15 minutes.
     If we do, then use the contents of that file and no need to re-scan.
     */ 
	if ([fm fileExistsAtPath:updateFilePath]) {
        NSError *attributesRetrievalError = nil;
        NSDictionary *attributes = [fm attributesOfItemAtPath:updateFilePath error:&attributesRetrievalError];
        
        if (!attributes) {
            logit(lcl_vError,@"Error for file at %@: %@", updateFilePath, attributesRetrievalError);
        }
        NSDate *fmDate = [attributes fileModificationDate];
        // File was created within 15 minutes of last scan...
        if (([[NSDate date] timeIntervalSinceDate:fmDate] / 60) < 15) {
            logit(lcl_vDebug, @"Within 15 Minutes. Using scan file.");
            approvedUpdatesArray = [NSArray arrayWithContentsOfFile:updateFilePath];
            if ([approvedUpdatesArray count] <= 0) {
                [statusText setStringValue:@"Begin scanning host for patches..."];
                [statusText display];
                approvedUpdatesArray = [self scanHostForPatches];	
            }
        } else {        
            logit(lcl_vDebug, @"Older than 15 Minutes, rescanning.");
            [statusText setStringValue:@"Begin scanning host for patches..."];
            [statusText display];
            approvedUpdatesArray = [self scanHostForPatches];
        }    
	} else {
		// Scan for Patches
		[statusText setStringValue:@"Begin scanning host for patches..."];
		[statusText display];
		approvedUpdatesArray = [self scanHostForPatches];	
	}
	
	
	// If no items in array, lets bail...
	if ([approvedUpdatesArray count] == 0 ) {
		logit(lcl_vInfo,@"No Apple updates found.");
		[statusText setStringValue:@"No updates found and needed."];
		[self RebootDialog];
		return;
	}
    
	[self setNumberOfUpdatesNeeded:(int)[approvedUpdatesArray count]];
	[numberOfUpdates setStringValue:[NSString stringWithFormat:@"Updates to install: %d",numberOfUpdatesNeeded]];
	
	//Set Progress Bar Max Value
	[progressBar setMaxValue:numberOfUpdatesNeeded];
	
	if (approvedUpdatesArray && [approvedUpdatesArray count] > 0) {
		[arrayController removeObjects:[arrayController arrangedObjects]];
		[arrayController addObjects:approvedUpdatesArray];	
		[tableView reloadData];
		[tableView deselectAll:self];
		[tableView display];
	}
	
	// Install the approved patches
	logit(lcl_vInfo,@"Approved Patches: %d",(int)[approvedUpdatesArray count]);
	logit(lcl_vDebug,@"Approved Patches: %@",approvedUpdatesArray);
	int result = 1;
	int i = 0;
    int pre_criteria = 0;
    int post_criteria = 0;
    
	NSDictionary *l_patch = nil;
	if ([approvedUpdatesArray count] > 0) {
		
		// Purge Pre Download Apple Updates
		if ([[NSFileManager defaultManager] removeItemAtPath:@"/Library/Updates" error:NULL]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:@"/Library/Updates" withIntermediateDirectories:YES attributes:nil error:NULL];
        }
		
		for (i = 0; i < [approvedUpdatesArray count]; i++) 
		{
			l_patch = [[NSDictionary alloc] initWithDictionary:[approvedUpdatesArray objectAtIndex:i]];
			if ([[l_patch objectForKey:@"type"] isEqualToString:@"Apple"]) 
			{	
				[self updateTableAndArrayController:i status:0];
				[tableView reloadData];
				
				logit(lcl_vInfo,@"Begin software update install for %@",[l_patch objectForKey:@"patch"]);
				logit(lcl_vDebug,@"Patch Dict:%@",l_patch);
				[statusText setStringValue:[NSString stringWithFormat:@"Installing %@",[l_patch objectForKey:@"patch"]]];
				[statusText display];
                
                // If the patch has any pre install criteria
                pre_criteria = 0;
                if ([[l_patch objectForKey:@"hasCriteria"] boolValue] == YES) {
                    pre_criteria = [self startCriteria:l_patch type:0];
                }
				
                if (pre_criteria == 0) 
                {
                    // Setup new install task, to start the install
                    if (installTask!=nil) {
                        [installTask release];
                    }
                    
                    installTask=[[TaskWrapper alloc] initWithController:self patch:l_patch];
                    installIsRunning=YES;
                    [installTask startProcess];
                    
                    // loop waiting for task to finish
                    while (installIsRunning) {
                        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                    }
                    
                    if ([installTask taskResult] != 0) {
                        logit(lcl_vError,@"There was a problem installing %@",[l_patch objectForKey:@"patch"]);
                        [self updateTableAndArrayController:i status:2];
                        [tableView reloadData];
                    } else {
                        
                        // Run Post Criteria
                        if ([[l_patch objectForKey:@"hasCriteria"] boolValue] == YES) {
                            post_criteria = [self startCriteria:l_patch type:1];
                        }
                        // Instal is complete, post result to web service
                        @try {
                            [self postInstallToWebService:[l_patch objectForKey:@"patch"] type:@"apple"];
                        }
                        @catch (NSException *e) {
                            logit(lcl_vError,@"%@", e);
                        }	
                        
                        [self updateTableAndArrayController:i status:1];
                        [tableView reloadData];
                    }
                } else {
                    logit(lcl_vError,@"There was a problem installing %@",[l_patch objectForKey:@"patch"]);
                    [self updateTableAndArrayController:i status:2];
                    [tableView reloadData];
                }
                
				[progressBar incrementBy:1.0];
				[installTask release];
				installTask = nil;
			} 
			else 
			{
				[self updateTableAndArrayController:i status:0];
				[tableView reloadData];
				[tableView display];
				
				result =  [self installCustomUpdate:l_patch];
				if (result != 0) {
					logit(lcl_vError,@"[%d] There was a problem installing %@",result, [l_patch objectForKey:@"patch"]);
					[self updateTableAndArrayController:i status:2];
					[tableView reloadData];
				} else {
					[self updateTableAndArrayController:i status:1];
					[tableView reloadData];
				}
				[progressBar incrementBy:1.0];
			}
			[l_patch release];
			l_patch = nil;
			[NSThread sleepForTimeInterval:0.5]; // Small hal second delay, before next update...
		}
	}
    
	[progressWheel stopAnimation:nil];
	[statusText setStringValue:@"Update task completed."];
	[pool release];
	[self performSelectorOnMainThread:@selector(RebootDialog) withObject:nil waitUntilDone:false];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView 
{
	if (arrayController) {
		return (int)[[arrayController arrangedObjects] count];
	} else {
		return 0;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row 
{
	if (row != -1)
		return [[[arrayController arrangedObjects] objectAtIndex:row] objectForKey:[tableColumn identifier]];
	
	return nil;
}

- (void)updateTableAndArrayController:(int)idx status:(int)aStatusImage
{
	NSMutableArray *patches = [NSMutableArray arrayWithArray:[arrayController arrangedObjects]];
	NSMutableDictionary *patch = [[NSMutableDictionary alloc] initWithDictionary:[patches objectAtIndex:idx]];
	if (aStatusImage == 0) {
		[patch setObject:[NSImage imageNamed:@"running.tiff"] forKey:@"status"];
	}
	if (aStatusImage == 1) {
		[patch setObject:[NSImage imageNamed:@"Installcomplete.tif"] forKey:@"status"];
	}
	if (aStatusImage == 2) {
		[patch setObject:[NSImage imageNamed:@"exclamation.tif"] forKey:@"status"];
	}
	[patches replaceObjectAtIndex:idx withObject:patch];
	[arrayController setContent:patches];
	[tableView deselectAll:nil];
	[tableView reloadData];
	[tableView display];
	
	[patch release];
}

- (int)installCustomUpdate:(NSDictionary *)patch
{	
	uid_t uid = getuid();
	if (uid != 0) {
		logit(lcl_vError,@"Unable to install updates, user is not root.");
		return 1;
	}
	
	//NSDictionary *mpDefaults;
	
	MPAsus *mpAsus      = [[MPAsus alloc] initWithServerConnection:mpServerConnection];
	MPScript *mpScript  = [[MPScript alloc] init];
	NSDictionary		*currPatchToInstallDict;
	NSArray				*patchPatchesArray;
	NSString			*downloadURL;
	NSError				*err;
	
	int installResult = -1;
	
	// Now proceed to the download and install			
	
	// Get all of the patches, main and subs
	// This is messed up, not sure why I have an array right within an array, needs to be fixed ...later :-)
	patchPatchesArray = [NSArray arrayWithArray:[[patch objectForKey:@"patches"] objectForKey:@"patches"]];
	logit(lcl_vInfo,@"Current patch has total patches associated with it %d", (int)([patchPatchesArray count]-1));
	
	NSString *dlPatchLoc; //Download location Path
	int patchIndex = 0;
	for (patchIndex=0;patchIndex < [patchPatchesArray count];patchIndex++) {
		
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
			[statusText setStringValue:[NSString stringWithFormat:@"Start download for patch from %@",[currPatchToInstallDict objectForKey:@"url"]]];
			
			logit(lcl_vInfo,@"Downloading patch from %@",[currPatchToInstallDict objectForKey:@"url"]);
			downloadURL = [NSString stringWithFormat:@"http://%@/mp-content%@",mpServerConnection.HTTP_HOST,[currPatchToInstallDict objectForKey:@"url"]];
			logit(lcl_vDebug,@"Download URL: %@",downloadURL);
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
		
		// Validate hash, before install
        MPCrypto *mpCrypto = [[MPCrypto alloc] init];
		NSString *fileHash = [mpCrypto md5HashForFile:dlPatchLoc];
        [mpCrypto release];
        
		logit(lcl_vInfo,@"Downloaded file hash: %@ (%@)",fileHash,[currPatchToInstallDict objectForKey:@"hash"]);
		if ([[[currPatchToInstallDict objectForKey:@"hash"] uppercaseString] isEqualTo:[fileHash uppercaseString]] == NO) {
			logit(lcl_vError,@"The downloaded file did not pass the file hash validation. No install will occure.");
			continue;
		}
		
		// Now we need to unzip
		[statusText setStringValue:[NSString stringWithFormat:@"Begin decompression of file, %@",dlPatchLoc]];	
		[statusText display];
		logit(lcl_vInfo,@"Begin decompression of file, %@",dlPatchLoc);
		err = nil;
		[mpAsus unzip:dlPatchLoc error:&err];
		if (err) {
			logit(lcl_vError,@"Error decompressing a patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
			break;
		}
		logit(lcl_vInfo,@"File has been decompressed.");
		
		// *****************************
		// Run PreInstall Script
		if ([[currPatchToInstallDict objectForKey:@"preinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"preinst"] isEqualTo:@"NA"] == NO) {
			[statusText setStringValue:[NSString stringWithFormat:@"Begin pre install script."]];
			[statusText display];
			if ([mpScript runScript:[[currPatchToInstallDict objectForKey:@"preinst"] decodeBase64WithNewLinesReturnString:NO]] == NO)
				break;
		}
		
		// Install the update
		BOOL hadErr = NO;
		@try {
			NSMutableDictionary *_approvedUpdate = nil;
			NSString *pkgPath;
			NSString *pkgBaseDir = [dlPatchLoc stringByDeletingLastPathComponent];
			NSPredicate *pkgPredicate = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
			NSArray *pkgList = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[dlPatchLoc stringByDeletingLastPathComponent] error:NULL] filteredArrayUsingPredicate:pkgPredicate];
			installResult = -1;
			
			// Install pkg(s)
			for (int ii = 0; ii < [pkgList count]; ii++) {	
				pkgPath = [NSString stringWithFormat:@"%@/%@",pkgBaseDir,[pkgList objectAtIndex:ii]];
				logit(lcl_vInfo,@"Installing %@",[pkgList objectAtIndex:ii]);
				[statusText setStringValue:[NSString stringWithFormat:@"Installing %@",pkgPath]];
				[statusText display];
				
				// Setup new install task, to start the install
				if (installTask!=nil)
					[installTask release];
				
				installTask=[[TaskWrapper alloc] initWithController:self patch:nil];
				installIsRunning=YES;
				
				_approvedUpdate = [[NSMutableDictionary alloc] init];
				[_approvedUpdate setValue:@"Third" forKey:@"type"];
				[_approvedUpdate setValue:pkgPath forKey:@"patch"];
				if ([[currPatchToInstallDict objectForKey:@"env"] isEqualToString:@"NA"] == NO)
					[_approvedUpdate setValue:[currPatchToInstallDict objectForKey:@"env"] forKey:@"env"];
				
				[installTask setApprovedPatch:[NSDictionary dictionaryWithDictionary:_approvedUpdate]];
				[installTask startProcess];
				[_approvedUpdate release];
				_approvedUpdate = nil;
				
				while (installIsRunning) {
					[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
				}
				
				if ([installTask taskResult] != 0) {
					logit(lcl_vError,@"Error installing package, error code %d.",installResult);
					installResult = 1; // This is the value used to return the function result
					hadErr = YES;
					[installTask release];
					break;
				} else {
					logit(lcl_vInfo,@"%@ was installed successfully.",pkgPath);
					installResult = 0; // This is the value used to return the function result
				}
				[installTask release];
				installTask = nil;
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
			[statusText setStringValue:[NSString stringWithFormat:@"Begin post install script."]];
			[statusText display];
			if ([mpScript runScript:[[currPatchToInstallDict objectForKey:@"postinst"] decodeBase64WithNewLinesReturnString:NO]] == NO) 
				break;
		}
		
		// Instal is complete, post result to web service
		@try {
			[self postInstallToWebService:[patch objectForKey:@"patch_id"] type:@"third"];
		}
		@catch (NSException *e) {
			logit(lcl_vError,@"%@", e);
		}		
	} // End patchArray To install
	
	[mpScript release];
	
	return installResult;
}

- (void)postInstallToWebService:(NSString *)aPatch type:(NSString *)aType
{
	NSString *cuuid = [MPSystemInfo clientUUID];
	cuuid = [NSString stringWithString:[cuuid trim]];
	
	MPDefaults *defaults = [[MPDefaults alloc] init];
	MPSoap *soap = [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:WS_NAMESPACE];
	NSData *soapResult;
	// First we need to post the installed patch
	NSArray *patchInstalledArray;
	patchInstalledArray = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:aPatch,@"patch",aType,@"type",nil]];
	
	MPDataMgr *dataMgr = [[MPDataMgr alloc] init];
	NSString *resXML = [NSString stringWithString:[dataMgr GenXMLForDataMgr:patchInstalledArray dbTable:@"installed_patches" 
															  dbTablePrefix:@"mp_"
															  dbFieldPrefix:@""
															   updateFields:@"cuuid,patch"]];
	
	NSString *xmlBase64String = [[resXML dataUsingEncoding: NSASCIIStringEncoding] encodeBase64WithNewlines:NO]; 
	NSString *message = [soap createSOAPMessage:@"ProcessXML" argName:@"encodedXML" argType:@"string" argValue:xmlBase64String];
	
	NSError *err = nil;
	soapResult = [soap invoke:message isBase64:NO error:&err];
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
	}
	NSString *ws1 = [[NSString alloc] initWithData:soapResult encoding:NSUTF8StringEncoding];
	
	// Now we need to update the client patch tables and remove the entry.
	// datamgr can not do this since it's a different table
	NSDictionary *soapMsgData = [NSDictionary dictionaryWithObjectsAndKeys:aPatch,@"patch",aType,@"type",cuuid,@"cuuid",nil];
	logit(lcl_vDebug,@"UpdateInstalledPatches Dict: %@",soapMsgData);
	
	
	message = [soap createBasicSOAPMessage:@"UpdateInstalledPatches" argDictionary:soapMsgData];
	err = nil;
	soapResult = [soap invoke:message isBase64:NO error:&err];
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
	}
	NSString *ws2 = [[NSString alloc] initWithData:soapResult encoding:NSUTF8StringEncoding];
	
	if ([ws1 isEqualTo:@"1"] == TRUE || [ws1 isEqualTo:@"true"] == TRUE) {
		logit(lcl_vInfo,@"Patch (%@) install result was posted to webservice.",aPatch);
	} else {
		logit(lcl_vError,@"Patch (%@) install result was not posted to webservice.",aPatch);
	}
	if ([ws2 isEqualTo:@"1"] == YES  || [ws2 isEqualTo:@"true"] == TRUE) {
		logit(lcl_vInfo,@"Client patch state for (%@) was posted to webservice.",aPatch);
	} else {
		logit(lcl_vError,@"Client patch state for (%@) was not posted to webservice.",aPatch);
	}
    
	
	// We should queue this in case we fail.
	
	//Release Objects
	[ws2 release];
	[ws1 release];
	[dataMgr release];
	[soap release];
	[defaults release];
}

#pragma mark -
#pragma mark IBAction

- (IBAction)sendCancel:(id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Restart"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Cancel Patch Installation?"];
	[alert setInformativeText:@"If you cancel, this process will re-run on next logout/restart."];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		// OK clicked, delete the record
		killTasks = YES;
        sleep(1);
		[self restartLocalSystem];
		exit(0);
	}
	[alert release];
}

- (IBAction)sendAppQuit:(id)sender
{
	[self exitTheApp];
}

#pragma mark -
#pragma mark Helper Methods

-(void)restartLocalSystem
{
	[self removeLogOutHook];
	int rb = 0;
	rb = reboot(RB_AUTOBOOT);
}

- (void)removeLogOutHook
{
	logit(lcl_vInfo,@"Removing logout hook.");
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:MPLOGOUT_HOOK_PLIST]) {
		NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:MPLOGOUT_HOOK_PLIST];
		[plistDict removeObjectForKey:@"LogoutHook"];
		
		[plistDict writeToFile:MPLOGOUT_HOOK_PLIST atomically:YES];
		[plistDict release];
	}
	return;
}

- (void)incrementTimer:(id)sender
{
	if(secondsTilReboot > 1){
		[self setSecondsTilReboot:(secondsTilReboot -1)];
		[restartWindowText setStringValue:[NSString stringWithFormat:@"System updates have been completed. This system will automatically restart in %i seconds or click the restart button now.", secondsTilReboot]];
		[[restartWindowText window] update];
	} else {
		[restartWindowText setStringValue:[NSString stringWithFormat:@"System updates have been completed. This system will automatically restart in %i seconds or click the restart button now.", 0]];
		[restartTimer invalidate];
		[self exitTheApp];
	}
}

- (void)RebootDialog
{
	[progressWheel stopAnimation:nil]; // Just incase :-)
	[self setSecondsTilReboot:10];
	[restartWindow center];
	[restartWindow makeKeyAndOrderFront:nil];
	restartTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTimer:) userInfo:nil repeats:YES];
}

- (void)exitTheApp
{
	[self removeLogOutHook];
	[self restartLocalSystem];
	exit(0);
}

- (void)sendBasicSOAP:(NSString *)aMethod content:(NSDictionary *)aDict
{
	NSError *err = nil;
	NSString *message = [mps createBasicSOAPMessage:aMethod argDictionary:aDict];
	NSData *result = [mps invoke:message isBase64:NO error:&err];	
	
	NSString *ws = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
	logit(lcl_vInfo,@"WS Results: %@",ws);
	
	if ([ws isEqualTo:@"1"] == TRUE || [ws isEqualTo:@"true"] == TRUE) {
		logit(lcl_vInfo,@"Install results posted to webservice.");
	} else {
		logit(lcl_vError,@"Install results posted to webservice returned false.");
	}
	
	[ws release];
}

- (void)appendStatusString:(NSString *)aStr
{
	NSRange tvRange;
    tvRange = NSMakeRange ([[installStatusOutput string] length], 0);
    [installStatusOutput replaceCharactersInRange:tvRange withString:aStr];
	[installStatusOutput scrollRangeToVisible:tvRange];
}

- (void)installStatusNotify:(NSNotification *)aNotification
{
	if (aNotification) {
		NSDictionary *userInfo = [aNotification userInfo];
		if ([userInfo objectForKey:@"InstallStatus"]) {
			[self appendStatusString:[userInfo objectForKey:@"InstallStatus"]];
		}
	}
}

#pragma mark -

- (void)installProcessStarted
{
    installIsRunning=YES;
}

- (void)installProcessFinished
{
	installIsRunning=NO;
}

-(void)realAppendOutput:(NSString *)output
{
	assert([NSThread isMainThread]);
	
	[[installStatusOutput textStorage] appendAttributedString: [[[NSAttributedString alloc] initWithString:output] autorelease]];
	[self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
}

- (void)appendOutput:(NSString *)output
{
	[self performSelectorOnMainThread:@selector(realAppendOutput:) withObject:output waitUntilDone:YES];
}

- (void)scrollToVisible:(id)ignore {
    [installStatusOutput scrollRangeToVisible:NSMakeRange([[installStatusOutput string] length], 0)];
}


#pragma mark - Pre/Post Criteria
- (int)startCriteria:(NSDictionary *)aPatch type:(int)criteriaType
{
    int result = 0;
	MPScript		*_mps;
	NSDictionary	*criteriaDict;
	NSData			*scriptData;
	NSString		*scriptText;
    
    NSString        *criteria_type_txt; 
    NSString        *criteria_type = NULL;
    if (criteriaType == 0) {
        criteria_type_txt = @"Pre";
        criteria_type = [NSString stringWithFormat:@"criteria_%@",[criteria_type_txt lowercaseString]];
    } else if (criteriaType == 1) {
        criteria_type_txt = @"Post";
        criteria_type = [NSString stringWithFormat:@"criteria_%@",[criteria_type_txt lowercaseString]];
    } else {
        goto done;
    }
	
	if ([[aPatch objectForKey:@"hasCriteria"] boolValue] == NO) {
		goto done;
		
	} else {
		logit(lcl_vInfo,@"%@ has install criteria assigned to it.",[aPatch objectForKey:@"patch"]);
		
		int i = 0;
		// PreInstall First
		if ([aPatch objectForKey:criteria_type]) {
			logit(lcl_vInfo,@"Processing %@-install criteria.",criteria_type_txt); 
			for (i=0;i<[[aPatch objectForKey:criteria_type] count];i++)
			{
				@try {
					criteriaDict = [[aPatch objectForKey:criteria_type] objectAtIndex:i]; 
					logit(lcl_vDebug,@"criteriaDict=%@",criteriaDict);
					
					scriptData = [[criteriaDict objectForKey:@"data"] decodeBase64WithNewlines:NO];
					scriptText = [[[NSString alloc] initWithData:scriptData encoding:NSUTF8StringEncoding] autorelease];
					logit(lcl_vDebug,@"scriptText=%@",scriptText);
					
					if (_mps!=nil)
						[_mps release];
					
					_mps = [[MPScript alloc] init];
					
					if ([_mps runScript:scriptText]) {
						logit(lcl_vInfo,@"%@-install script returned true.",criteria_type_txt);
						result = 0;
					} else {
						logit(lcl_vError,@"%@-install script returned false for %@. No install will occure.",criteria_type_txt,[aPatch objectForKey:@"patch"]); 
						result = 1;
						goto done;
					}
					
					criteriaDict = nil;
				}
				@catch (NSException * e) {
					logit(lcl_vError,@"%@-install script returned false for %@. No install will occure.",criteria_type_txt,[aPatch objectForKey:@"patch"]); 
					logit(lcl_vError,@"%@",[e description]); 
					result = 1;
					goto done;
				}
			}
		}
	}	
	
done:
	if (_mps!=nil)
		[_mps release];
	
	return result; 
}

@end
