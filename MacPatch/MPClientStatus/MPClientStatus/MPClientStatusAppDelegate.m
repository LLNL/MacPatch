//
//  MPClientStatusAppDelegate.m
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

#import "MPClientStatusAppDelegate.h"
#import "MacPatch.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "MPAppUsage.h"
#import "MPWorkerProtocol.h"
#import "AppLaunchObject.h"
#import "CHMenuViewController.h"
#import "VDKQueue.h"

// Private Methods
@interface MPClientStatusAppDelegate ()

// Helper
- (void)connect;
- (int)connect:(NSError **)err;
- (void)cleanup;
- (void)connectionDown:(NSNotification *)notification;

// Worker Methods
- (void)disableASUSSchedule;

// Watch Patch Status/Needed  
- (void)setupWatchedFolder;
@property (nonatomic, strong) NSDate *lastPatchStatusUpdate;

@end


@implementation MPClientStatusAppDelegate

#pragma mark Properties
@synthesize window;
@synthesize checkInStatusMenuItem;
@synthesize checkPatchStatusMenuItem;
@synthesize selfVersionInfoMenuItem;
@synthesize MPVersionInfoMenuItem;
@synthesize checkAgentAndUpdateMenuItem;

@synthesize openASUS;
@synthesize asusAlertOpen;

// Client Info
@synthesize clientInfoWindow;
@synthesize clientInfoTableView;
@synthesize clientArrayController;

// Aboiut Window
@synthesize aboutWindow;
@synthesize appIcon;
@synthesize appName;
@synthesize appVersion;

// Client CheckIn Data
@synthesize queue;

#pragma mark UI Events
-(void)awakeFromNib
{
	// Turn off Scheduled Software Updates
    [self setupWatchedFolder];
	[self setAsusAlertOpen:NO];
    [self disableASUSSchedule];
	
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setMenu:statusMenu];
	[statusItem setImage:[NSImage imageNamed:@"mpmenubar_normal.png"]];
	[statusItem setHighlightMode:YES];
    
	// App Version Info
	[selfVersionInfoMenuItem setTitle:[NSString stringWithFormat:@"Status App Version: %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
	NSDictionary *_mpVerDict = [NSDictionary dictionaryWithContentsOfFile:AGENT_VER_PLIST];
	[MPVersionInfoMenuItem setTitle:[NSString stringWithFormat:@"MacPatch Version: %@",[_mpVerDict objectForKey:@"version"]]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	//Setup Defaults	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs registerDefaults:[NSDictionary dictionaryWithContentsOfFile:APP_PREFS_PLIST]];
    
	NSString *_logFile = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/MPClientStatus.log"];
	[MPLog setupLogging:_logFile level:lcl_vDebug];
	
	if ([prefs boolForKey:@"DeBug"] == YES) 
	{
		// enable logging for all components up to level Debug
		lcl_configure_by_name("*", lcl_vDebug);
		logit(lcl_vInfo,@"***** MPStatus started -- Debug Enabled *****");
	} else {
		// enable logging for all components up to level Info
		lcl_configure_by_name("*", lcl_vInfo);
		logit(lcl_vInfo,@"***** MPStatus started *****");
	}
	
	// Watch for SoftwareUpdate Launches
	NSNotificationCenter *dc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[dc addObserver:self selector:@selector(notificationReceived:) name:NSWorkspaceWillLaunchApplicationNotification object:[NSWorkspace sharedWorkspace]];
	// Setup App monitoring
	mpAppUsage = [[MPAppUsage alloc] init];
    [mpAppUsage cleanDB]; // Removes Entries Where App Version is NULL

	[dc addObserver:self selector:@selector(appLaunchNotificationReceived:) name:NSWorkspaceWillLaunchApplicationNotification object:[NSWorkspace sharedWorkspace]];
    
	// Start Last CheckIn Thread, update every 10 min
	[self showLastCheckIn];
	
	// This will monitor for hits, when to update the patch status flags
    [self displayPatchData];
	
	[self setOpenASUS:NO];
}

- (void) applicationWillTerminate: (NSNotification *)note
{
	
}


#pragma mark -
#pragma mark MPWorker
- (void)connect
{
    // Use mach ports for communication, since we're local.
    NSConnection *connection = [NSConnection connectionWithRegisteredName:kMPWorkerPortName host:nil];
	
    [connection setRequestTimeout: 60.0];
    [connection setReplyTimeout: 1800.0]; //30 min to install
	
    @try {
        proxy = [connection rootProxy];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDown:) name:NSConnectionDidDieNotification object:connection];
		
        [proxy setProtocolForProxy: @protocol(MPWorkerServer)];
        BOOL successful;
        for (int i = 0; i < 3; i++)
        {
            successful = [proxy registerClient:self];
            if (!successful) {
                if (i == 3) {
                    NSRunAlertPanel(@"Error", @"Unable to connect to helper application. Please try logging out and logging back in to resolve the issue.", nil, nil, nil);
                }
                [self cleanup];
            } else {
                break;
            }
        }
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Could not connect to MPHelper: %@", e);
        [self cleanup];
    }
}

- (int)connect:(NSError **)err
{
    // Use mach ports for communication, since we're local.
    NSConnection *connection = [NSConnection connectionWithRegisteredName:kMPWorkerPortName host:nil];
	
    [connection setRequestTimeout: 60.0];
    [connection setReplyTimeout: 1800.0]; //30 min to install
	
    @try {
        proxy = [connection rootProxy];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDown:) name:NSConnectionDidDieNotification object:connection];
		
        [proxy setProtocolForProxy: @protocol(MPWorkerServer)];
        BOOL successful;
        for (int i = 0; i < 3; i++)
        {
            successful = [proxy registerClient:self];
            if (!successful) {
                if (i == 3) {
                    NSRunAlertPanel(@"Error", @"Unable to connect to helper application. Please try logging out and logging back in to resolve the issue.", nil, nil, nil);
                    NSMutableDictionary *details = [NSMutableDictionary dictionary];
                    [details setValue:@"Unable to connect to helper application. Please try logging out and logging back in to resolve the issue." forKey:NSLocalizedDescriptionKey];
                    if (err != NULL)  *err = [NSError errorWithDomain:@"world" code:1 userInfo:details];
                }
                [self cleanup];
            } else {
                break;
            }
        }
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Could not connect to MPHelper: %@", e);
        [self cleanup];
    }

    return 0;
}

- (void)cleanup
{
    if (proxy)
    {
        NSConnection *connection = [proxy connectionForProxy];
        [connection invalidate];
        proxy = nil;
    }
	
}

- (void)connectionDown:(NSNotification *)notification
{
    logit(lcl_vTrace,@"MPWorker connection down");
    [self cleanup];
}

#pragma mark - Worker Methods

- (void)removeStatusFiles
{
    NSError *error = nil;
	if (!proxy) {
        [self connect:&error];
        if (error) {
            logit(lcl_vError,@"%@",error.localizedDescription);
            goto done;
        }
        if (!proxy) {
            logit(lcl_vError,@"Could not create proxy object.");
            goto done;
        }
    }

    @try
	{
		[proxy removeStatusFilesViaHelper];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Trying to set the logging level, %@", e);
    }

done:
	[self cleanup];
	return;
}

- (void)disableASUSSchedule
{
    NSError *error = nil;
	if (!proxy) {
        [self connect:&error];
        if (error) {
            logit(lcl_vError,@"disableSoftwareUpdateScheduleViaHelper error 1001: %@",[error localizedDescription]);
        }
        if (!proxy) {
            logit(lcl_vError,@"disableSoftwareUpdateScheduleViaHelper error 1002: Unable to get proxy object.");
            goto done;
        }
    }
	
    @try
	{
		logit(lcl_vDebug,@"[proxy run disableSoftwareUpdateScheduleViaHelper]");
		[proxy disableSoftwareUpdateScheduleViaHelper];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"disableSoftwareUpdateScheduleViaHelper error: %@", e);
    }
	
done:
	[self cleanup];
}

#pragma mark -
#pragma mark Client Info
- (IBAction)getMPClientVersionInfo:(id)sender
{
	[clientArrayController removeObjects:[clientArrayController arrangedObjects]];
	[clientInfoTableView reloadData];
	
	NSDictionary *mpVerDict = [NSDictionary dictionaryWithContentsOfFile:AGENT_VER_PLIST];
    logit(lcl_vDebug,@"mpVerDict: %@", mpVerDict);
	
	NSString *verInfo = [NSString stringWithFormat:@"Version: %@\nBuild: %@\nClient ID: %@",
						 [mpVerDict objectForKey:@"version"],
						 [mpVerDict objectForKey:@"build"],
						 [MPSystemInfo clientUUID]];
	
	[clientInfoTextField setFont:[NSFont fontWithName:@"Lucida Grande" size:11.0]];
	[clientInfoTextField setStringValue:verInfo];
	
	NSMutableArray *data = [[NSMutableArray alloc] init];
	NSMutableDictionary *dict;
	NSDictionary *mpSwuadDict = [NSDictionary dictionaryWithContentsOfFile:AGENT_PREFS_PLIST];
	int i = 0;
	for (i=0;i < [[mpSwuadDict allKeys] count];i++) {
		dict = [[NSMutableDictionary alloc] init];
		[dict setObject:[[mpSwuadDict allKeys] objectAtIndex:i] forKey:@"property"];
		[dict setObject:[[mpSwuadDict allValues] objectAtIndex:i] forKey:@"value"];
		[data addObject:dict];
		dict = nil;
	}
	
	[clientArrayController addObjects:data];
	[clientInfoTableView reloadData];
	[clientInfoTableView deselectAll:self];
	
	
	[clientInfoWindow makeKeyAndOrderFront:sender];
	[clientInfoWindow center];
	[NSApp arrangeInFront:sender];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)closeClientInfoWindow:(id)sender
{
	[clientInfoWindow close];
}

#pragma mark -
#pragma mark About Window
- (IBAction)showAboutWindow:(id)sender
{
	appName.stringValue = [[NSProcessInfo processInfo] processName];
	appVersion.stringValue = [NSString stringWithFormat:@"Version %@ (%@)",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	[appIcon setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
	[aboutWindow makeKeyAndOrderFront:sender];
	[aboutWindow center];
}

#pragma mark Checkin
- (IBAction)showCheckinWindow:(id)sender
{
	[NSThread detachNewThreadSelector:@selector(performClientCheckInThread) toTarget:self withObject:nil];
}

- (void)performClientCheckInThread
{
	@autoreleasepool {
	
		BOOL didRun = NO;
		didRun = [self performClientCheckInMethod];
		
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		if (didRun == NO) {
			[alert setMessageText:@"Error with check-in"];
			[alert setInformativeText:@"There was a problem checking in with the server. Please review the client status logs for cause."];
			[alert setAlertStyle:NSCriticalAlertStyle];
		} else {
			[alert setMessageText:@"Client check-in"];
			[alert setInformativeText:@"Client check-in was successful."];
			[alert setAlertStyle:NSInformationalAlertStyle];
		}
		
		[alert runModal];
	}
}

// Performs a client checkin 
- (BOOL)performClientCheckInMethod
{
	int y = 0;
	
	NSString *_cuuid = [MPSystemInfo clientUUID];
	NSDictionary *osDict = [[NSDictionary alloc] initWithDictionary:[self getOSInfo]];
	
    NSDictionary *consoleUserDict = [MPSystemInfo consoleUserData];
    NSDictionary *hostNameDict = [MPSystemInfo hostAndComputerNames];
	NSDictionary *clientVer = [NSDictionary dictionaryWithContentsOfFile:AGENT_VER_PLIST];
    
	NSMutableDictionary *agentDict = [[NSMutableDictionary alloc] init];
	[agentDict setObject:_cuuid forKey:@"cuuid"];
	[agentDict setObject:[self getHostSerialNumber] forKey:@"serialno" defaultObject:@"NA"];
	[agentDict setObject:[hostNameDict objectForKey:@"localHostName"] forKey:@"hostname" defaultObject:@"localhost"];
	[agentDict setObject:[hostNameDict objectForKey:@"localComputerName"] forKey:@"computername" defaultObject:@"localhost"];
	[agentDict setObject:[consoleUserDict objectForKey:@"consoleUser"] forKey:@"consoleUser" defaultObject:@"NA"];
	[agentDict setObject:[MPSystemInfo getIPAddress] forKey:@"ipaddr" defaultObject:@"127.0.0.1"];
	[agentDict setObject:[MPSystemInfo getMacAddressForInterface:@"en0"] forKey:@"macaddr" defaultObject:@"00:00:00:00:00:00"];
	[agentDict setObject:[osDict objectForKey:@"ProductVersion"] forKey:@"osver" defaultObject:@"10.0.0"];
	[agentDict setObject:[osDict objectForKey:@"ProductName"] forKey:@"ostype" defaultObject:@"Mac OS X"];
	[agentDict setObject:[clientVer objectForKey:@"version"] forKey:@"client_version" defaultObject:@"0"];
	[agentDict setObject:@"false" forKey:@"needsreboot" defaultObject:@"false"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/tmp/.MPAuthRun"]) {
		[agentDict setObject:@"true" forKey:@"needsreboot"];	
	}
    

	NSError *err = nil;
	BOOL postResult;
    MPWebServices *mpws = [[MPWebServices alloc] init];
	postResult = [mpws postJSONDataForMethod:@"client_checkin_base" data:agentDict error:&err];
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
		y++;
	}	
	if (postResult) {
		logit(lcl_vInfo,@"Running client base checkin, returned true.");
	} else {
		logit(lcl_vError,@"Running client base checkin, returned false.");
		y++;
	}
    
	// Read Client Plist Info
    
	NSMutableDictionary *mpDefaults = [NSMutableDictionary dictionaryWithContentsOfFile:AGENT_PREFS_PLIST];
	[mpDefaults setObject:_cuuid forKey:@"cuuid"];
    
	err = nil;
	postResult = [mpws postJSONDataForMethod:@"client_checkin_plist" data:mpDefaults error:&err];
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
	}	
	if (postResult) {
		logit(lcl_vInfo,@"Running client config checkin, returned true.");
	} else {
		logit(lcl_vError,@"Running client config checkin, returned false.");
		y++;
	}

	[self showLastCheckInMethod];
	if (y==0) {
		return YES;
	} else {
		return NO;
	}	
}

- (NSDictionary *)systemVersionDictionary
{
	NSDictionary *sysVer = NULL;
	
	SInt32 OSmajor, OSminor, OSrevision;
	OSErr err1 = Gestalt(gestaltSystemVersionMajor, &OSmajor);
	OSErr err2 = Gestalt(gestaltSystemVersionMinor, &OSminor);
	OSErr err3 = Gestalt(gestaltSystemVersionBugFix, &OSrevision);
	if (!err1 && !err2 && !err3)
	{
		sysVer = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:OSmajor],[NSNumber numberWithInt:OSminor],[NSNumber numberWithInt:OSrevision],nil] 
											 forKeys:[NSArray arrayWithObjects:@"major",@"minor",@"revision",nil]];
	}
	return sysVer;
}

- (NSDictionary *)getOSInfo
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *results = nil;
	NSString *clientVerPath = @"/System/Library/CoreServices/SystemVersion.plist";
	NSString *serverVerPath = @"/System/Library/CoreServices/ServerVersion.plist";
	
	if ([fm fileExistsAtPath:serverVerPath] == TRUE) {
		results = [NSDictionary dictionaryWithContentsOfFile:serverVerPath];
	} else {
		if ([fm fileExistsAtPath:clientVerPath] == TRUE) {
			results = [NSDictionary dictionaryWithContentsOfFile:clientVerPath];
		}
	}
	
	return results;
}

- (NSString *)getHostSerialNumber
{
	NSString *result = nil;
	io_registry_entry_t rootEntry = IORegistryEntryFromPath( kIOMasterPortDefault, "IOService:/" );
	CFTypeRef serialAsCFString = NULL;
	serialAsCFString = IORegistryEntryCreateCFProperty( rootEntry,
													   CFSTR(kIOPlatformSerialNumberKey),
													   kCFAllocatorDefault,
													   0);
	
	IOObjectRelease( rootEntry );
	if (serialAsCFString == NULL) {
		result = @"NA";
	} else {
		result = [NSString stringWithFormat:@"%@",(__bridge NSString *)serialAsCFString];
	}
    
	if(serialAsCFString) {
        CFRelease(serialAsCFString);
    }
	return result;
}

#pragma mark Show Last CheckIn Menu
- (void)showLastCheckIn
{
	[NSThread detachNewThreadSelector:@selector(showLastCheckInThread) toTarget:self withObject:nil];
}

- (void)showLastCheckInThread
{
	@autoreleasepool
    {
        // Run Once, to show current status
		[self showLastCheckInMethod];
		// 600.0 = 10 Minutes
		NSTimer *timer = [NSTimer timerWithTimeInterval:600.0
												 target:self 
											   selector:@selector(showLastCheckInMethod) 
											   userInfo:nil 
												repeats:YES];
		
		
		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];  
        [[NSRunLoop currentRunLoop] run];
	}
}

- (void)showLastCheckInMethod
{
    @autoreleasepool
    {
        NSError *wsErr = nil;
        MPWebServices *mpws = [[MPWebServices alloc] init];
        NSDictionary *result = [mpws GetLastCheckIn:&wsErr];
        if (wsErr) {
            logit(lcl_vError,@"Web service returned the following error (%d).%@",(int)wsErr.code,wsErr.localizedDescription);
            return;
        }

        if ([result objectForKey:@"mdate"]) {
			[checkInStatusMenuItem setTitle:[NSString stringWithFormat:@"Last Checkin: %@",[result objectForKey:@"mdate"]]];
		}
    }
}

#pragma mark Show Patch Status

- (void)displayPatchData
{
    NSArray  *data = [[NSKeyedUnarchiver unarchiveObjectWithFile:PATCHES_NEEDED_PLIST] mutableCopy];
    NSString *subMenuTitle = [NSString stringWithFormat:@"Patches Needed: %d ",(int)[data count]];

    // If No Patches ...
    if (!data) {
        [statusItem setImage:[NSImage imageNamed:@"mpmenubar_normal.png"]];
        [checkPatchStatusMenuItem setTitle:@"Patches Needed: 0"];
        [checkPatchStatusMenuItem setSubmenu:NULL];
        return;
    } else if ([data count] <= 0) {
        [statusItem setImage:[NSImage imageNamed:@"mpmenubar_normal.png"]];
        [checkPatchStatusMenuItem setTitle:@"Patches Needed: 0"];
        [checkPatchStatusMenuItem setSubmenu:NULL];
        return;
    } else {
        [statusItem setImage:[NSImage imageNamed:@"mpmenubar_alert2.png"]];
    }

    [checkPatchStatusMenuItem setTitle:subMenuTitle];
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:subMenuTitle];
    [checkPatchStatusMenuItem setSubmenu:subMenu];
    [checkPatchStatusMenuItem setEnabled:YES];

    NSMenuItem *newMenuItem;

    // Add Header Menu Item
    CHMenuViewController *vcTitle = [[CHMenuViewController alloc] init];
    NSRect f = vcTitle.view.frame;
    f.size.width = 337;
    f.size.height = 26;
    vcTitle.view.frame = f;

    [vcTitle.view addSubview:vcTitle.titleView];
    newMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [newMenuItem setView:vcTitle.view];
    [subMenu addItem:newMenuItem];

    // Add Patches as menu item using views
    CHMenuViewController *vc;
    for (NSDictionary *d in data)
    {
        newMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
        vc = [[CHMenuViewController alloc] init];
        [vc addTitle:[d objectForKey:@"patch"] version:[d objectForKey:@"version"]];
        if ([[[d objectForKey:@"restart"] uppercaseString] isEqualTo:@"TRUE"] || [[[d objectForKey:@"restart"] uppercaseString] isEqualTo:@"YES"])
        {
            vc.ximage = [NSImage imageNamed:@"RestartReq.tif"];
        } else {
            vc.ximage = [NSImage imageNamed:@"empty.tif"];
        }
        [newMenuItem setView:vc.view];
        [subMenu addItem:newMenuItem];
    }

    //
    // Add Bottom Menu Item thats says you need to use Self Patch to patch
    //
    CHMenuViewController *vc1 = [[CHMenuViewController alloc] init];

    f = vc1.view.frame;
    f.size.width = 337;
    f.size.height = 35;
    vc1.view.frame = f;

    [vc1.view addSubview:vc1.altView];

    newMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open Self Patch To Patch..." action:NULL keyEquivalent:@""];
    [newMenuItem setView:vc1.view];
    [subMenu addItem:newMenuItem];

    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:PATCHES_NEEDED_PLIST error:nil];
    if (attrs != nil) {
        [self setLastPatchStatusUpdate:(NSDate*)[attrs objectForKey: NSFileModificationDate]];
    }
}

- (IBAction)refreshClientStatus:(id)sender
{
    // Should add scan now action and update without opening self patch
    [self showLastCheckIn];
}

#pragma mark -
#pragma mark Open SelfPatch
- (IBAction)openSelfPatchApplications:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:SELF_PATCH_PATH]]
					withAppBundleIdentifier:@""
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:nil
						  launchIdentifiers:NULL];
}

#pragma mark -
#pragma mark Kill SoftwareUpdate GUI App
- (void)notificationReceived:(NSNotification *)aNotification 
{
	
	if ([[[aNotification userInfo] objectForKey:@"NSApplicationPath"] isEqualToString:ASUS_APP_PATH]) {		
		[NSApp activateIgnoringOtherApps:YES];
		if ([self openASUS] == NO)
		{			
			[self killApplication:[[aNotification userInfo] objectForKey:@"NSApplicationProcessIdentifier"]];
			
			if (asusAlertOpen == YES)
				return;
			
			NSAlert *alert;
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"EnableASUS"]) {
				alert = [NSAlert alertWithMessageText:@"Software Update" 
                                        defaultButton:@"Open Self Patch" 
                                      alternateButton:@"Open Software Update" 
                                          otherButton:@"Cancel"
                            informativeTextWithFormat:@"To help ensure patch compatibility for this system, updates are now handled by the \"Self Patch\" application.\n\nWarning: Applying patches using Software Update can screw up your system if you have disk encryption installed."];
			} else {
				alert = [NSAlert alertWithMessageText:@"Software Update" 
                                        defaultButton:@"Open Self Patch" 
                                      alternateButton:nil
                                          otherButton:@"Cancel"
                            informativeTextWithFormat:@"To help ensure patch compatibility for this system, updates are now handled by the \"Self Patch\" application."];
			}
			
			[self setAsusAlertOpen:YES];
			NSInteger res = [alert runModal];
			
			if (res == NSAlertDefaultReturn) {
				[self openSelfPatchApplications:nil];
				[self setAsusAlertOpen:NO];
			} else if (res == NSAlertAlternateReturn) {
				[self setOpenASUS:YES];
				[self openSoftwareUpdateApplication:nil];
				[self setAsusAlertOpen:NO];
			} else {
				[self setAsusAlertOpen:NO];
			}
            
		} else {
			[self setOpenASUS:NO];
		}
        
	}
	
}

- (void)killApplication:(NSNumber *)aPID
{
    pid_t pid=[aPID intValue];
    kill(pid,SIGKILL);
}

- (void)openSoftwareUpdateApplication:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:ASUS_APP_PATH]]
					withAppBundleIdentifier:@""
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:nil
						  launchIdentifiers:NULL];
}

#pragma mark - Software Catalog

- (IBAction)openSoftwareCatalogApplications:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:SWDIST_APP_PATH]]
					withAppBundleIdentifier:@""
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:nil
						  launchIdentifiers:NULL]; 
}

#pragma mark -
#pragma mark Record App Usage Info
- (void)appLaunchNotificationReceived:(NSNotification *)aNotification
{
	if ([[aNotification userInfo] objectForKey:@"NSApplicationName"]) {
		@try {
			NSBundle *b = [NSBundle bundleWithPath:[[aNotification userInfo] objectForKey:@"NSApplicationPath"]];
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[aNotification userInfo]];
            [userInfo setObject:[[b infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"CFBundleShortVersionString"];
            AppLaunchObject *alo = [AppLaunchObject appLaunchObjectWithDictionary:userInfo];

			logit(lcl_vDebug,@"Application launched: %@ %@ %@",[alo appName],[alo appPath],[alo appVersion]);
			[mpAppUsage insertLaunchDataForApp:[alo appName] appPath:[alo appPath] appVersion:[alo appVersion]];
		}
		@catch (NSException *exception) {
			logit(lcl_vError,@"%@",exception);
		}
	}
}

#pragma mark -
#pragma mark Softwareupdate
// Softwareupdate Method
- (void)turnOffSoftwareUpdateSchedule
{
	[NSTask launchedTaskWithLaunchPath:ASUS_BIN_PATH arguments:[NSArray arrayWithObjects:@"--schedule", @"off", nil]];
}

- (void)checkAgentStatus:(id)sender
{
    
}

#pragma mark - 
#pragma mark Watch Patch Needed File
- (void)setupWatchedFolder
{
    NSString *watchedFolder = [MP_ROOT_CLIENT stringByAppendingPathComponent:@"Data"];
    vdkQueue = [[VDKQueue alloc] init];
    [vdkQueue setDelegate:self];
    [vdkQueue addPath:watchedFolder];
    [vdkQueue setAlwaysPostNotifications:YES];
}

-(void) VDKQueue:(VDKQueue *)queue receivedNotification:(NSString*)note forPath:(NSString*)fpath
{
    if ([note.description isEqualTo:@"VDKQueueFileWrittenToNotification"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:PATCHES_NEEDED_PLIST])
        {
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:PATCHES_NEEDED_PLIST error:nil];

            if (attrs != nil) {
                NSDate *cdate = (NSDate*)[attrs objectForKey: NSFileModificationDate];
                if ([cdate timeIntervalSince1970] > [self.lastPatchStatusUpdate timeIntervalSince1970])
                {
                    [self displayPatchData];
                }
            }
        }
        else
        {
            [self removeStatusFiles];
        }
    }
}

@end
