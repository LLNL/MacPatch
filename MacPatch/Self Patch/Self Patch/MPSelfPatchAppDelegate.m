//
//  AppDelegate.m
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

#import "MPSelfPatchAppDelegate.h"
#import "MPWorkerProtocol.h"
#import "PrefsController.h"
#import <SystemConfiguration/SystemConfiguration.h>

static BOOL gDone = false;

@interface FileSizeTransformer : NSValueTransformer {
    
}

+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;

@end

@implementation FileSizeTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation;
{
    return NO;
}
- (id)transformedValue:(id)value;
{
    // Data contains "K" remove it to turn it in to a number value
    double convertedValue = [[value stringByReplacingOccurrencesOfString:@"K" withString:@""] doubleValue];
    // Data is already at k, other wise set bytes to 0
    int multiplyFactor = 1;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"B",@"KB",@"MB",@"GB",@"TB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

@end

// Private Methods
@interface MPSelfPatchAppDelegate ()

// Helper
- (void)connect;
- (void)connect:(NSError **)err;
- (void)cleanup;
- (void)connectionDown:(NSNotification *)notification;

// Worker Methods
- (int)setCatalogURL;
- (void)unSetCatalogURL;

- (NSArray *)scanForAppleUpdates:(NSError **)err;
- (NSArray *)scanForCustomUpdates:(NSError **)err;
- (int)installAppleSoftwareUpdate:(NSString *)appleUpdate;
- (int)installPKG:(NSString *)aPkgPath target:(NSString *)aTarget env:(NSString *)aEnv;
- (int)runScript:(NSString *)aScript;
- (void)setLogoutHook;
- (BOOL)setPermissionsForFile:(NSString *)aFile;
- (int)createDirAtPathWithIntermediateDirs:(NSString *)path intermediateDirs:(BOOL)withDirs;
- (int)writeDataToFile:(id)data file:(NSString *)aFile;
- (int)writeArrayToFile:(NSArray *)data file:(NSString *)aFile;
- (int)setLoggingState:(BOOL)aState;

@end


@implementation MPSelfPatchAppDelegate

@synthesize mpHost;
@synthesize mpHostPort;

@synthesize window;
@synthesize tableView;
@synthesize arrayController;
@synthesize spUpdateButton;
@synthesize spCancelButton;

@synthesize runTaskThread;
@synthesize killTaskThread;


+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"enableDebugLogging"];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"enableScanOnLaunch"];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

-(void)handleColStateToggle:(NSNotification *)note
{
	NSTableColumn *column = [tableView tableColumnWithIdentifier:@"select"];
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	if ([d boolForKey:@"colStateOnLaunch"] == YES) {
		[column setHidden:NO];
	} else {
		[column setHidden:YES];
	}
	[tableView setNeedsDisplay:YES];
}

-(void)handleColSizeToggle:(NSNotification *)note
{
	NSTableColumn *column = [tableView tableColumnWithIdentifier:@"size"];
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	if ([d boolForKey:@"colSizeOnLaunch"] == YES) {
		[column setHidden:NO];
	} else {
		[column setHidden:YES];
	}
	[tableView setNeedsDisplay:YES];
}

-(void)handleColBaselineToggle:(NSNotification *)note
{
	NSTableColumn *column = [tableView tableColumnWithIdentifier:@"baseline"];
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	if ([d boolForKey:@"colBaselineOnLaunch"] == YES) {
		[column setHidden:NO];
	} else {
		[column setHidden:YES];
	}
	[tableView setNeedsDisplay:YES];
}

-(void)awakeFromNib 
{	
	// This prevents Self Patch from auto relaunching after reboot/logout
	// 10.7 Feature
    if (floor(NSAppKitVersionNumber) > 1038 /* 10.6 */) {
        @try {
            NSApplication *a = [NSApplication sharedApplication];
            [a disableRelaunchOnLogin];
        }
        @catch (NSException * e) {
            // Nothing
        }
    }
	fm = [NSFileManager defaultManager];
    
	// Center the Window
	[window center];
	
    // Setup serverObject
    mpServerConnection = [[MPServerConnection alloc] initWithNilServerObj];
    
	// Connect to Helper
	//[self connect];
	
	if ([fm fileExistsAtPath:AGENT_PREFS_PLIST] == YES) {	
		if ([fm isReadableFileAtPath:AGENT_PREFS_PLIST] == NO) {
			if ([self setPermissionsForFile:AGENT_PREFS_PLIST] == NO) {
				logit(lcl_vError,@"Error, unable to set permissions needed to read agent plist file.");
			}	
		}
        /* Need a Dialog here with error info */
	}
    
	[patchGroupLabel setStringValue:[mpServerConnection.mpDefaults objectForKey:@"PatchGroup"]];

	// Make sure the cancel button is not enabled
	[spCancelButton setEnabled:NO];	
}

-(IBAction)windowCloseWillExit:(id)sender
{
	[NSApp terminate:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Set up preferences for the app.	
	
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	if (![d objectForKey:@"colBaselineOnLaunch"]) {
		[d setBool:NO forKey:@"colBaselineOnLaunch"];
	}
	if (![d objectForKey:@"colSizeOnLaunch"]) {
		[d setBool:YES forKey:@"colSizeOnLaunch"];
	}
	if (![d objectForKey:@"colStateOnLaunch"]) {
		[d setBool:NO forKey:@"colStateOnLaunch"];
	}
	
	int x = [self setLoggingState:[d boolForKey:@"enableDebugLogging"]];
    
	[self handleColSizeToggle:nil];
	[self handleColStateToggle:nil];
	[self handleColBaselineToggle:nil];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleColStateToggle:) name:@"MPSelfPatchColStateToggle" object:nil];
	[nc addObserver:self selector:@selector(handleColSizeToggle:) name:@"MPSelfPatchColSizeToggle" object:nil];
	[nc addObserver:self selector:@selector(handleColBaselineToggle:) name:@"MPSelfPatchColBaselineToggle" object:nil];
	
	// Setup logging
	NSString *_logFile = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/MPSelfPatch.log"];
	[MPLog setupLogging:_logFile level:lcl_vDebug];
    
	if ([d boolForKey:@"enableDebugLogging"]) {
		// enable logging for all components up to level Debug
		lcl_configure_by_name("*", lcl_vDebug);
		logit(lcl_vInfo,@"***** MPSelfPatch started -- Debug Enabled *****");
	} else {
		// enable logging for all components up to level Info
#ifdef DEBUG
      	lcl_configure_by_name("*", lcl_vDebug);
#else
    	lcl_configure_by_name("*", lcl_vInfo);    
#endif
	
		logit(lcl_vInfo,@"***** MPSelfPatch started *****");
	}
	
	// If scan on launch is true
	if ([d boolForKey:@"enableScanOnLaunch"]) {
		killTaskThread = NO;
        // Dont run scan if we get a error code other than 0
        if (x == 0) {
            [self scanForPatches:nil];
        }
	}
    
	// Center the Window
	[window center];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

-(void)dealloc
{
	[soap release];
	[asus release];
    [mpServerConnection release];
    [self cleanup];
	[super dealloc];
}

#pragma mark -
#pragma mark MPWorker
- (void)connect
{
    // Use mach ports for communication, since we're local.
    NSConnection *connection = [NSConnection connectionWithRegisteredName:kMPWorkerPortName host:nil];
	
    [connection setRequestTimeout: 10.0];
    [connection setReplyTimeout: 1800.0]; //30 min to install
	
    @try {
        proxy = [[connection rootProxy] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDown:) name:NSConnectionDidDieNotification object:connection];
		
        [proxy setProtocolForProxy: @protocol(MPWorkerServer)];
        BOOL successful = [proxy registerClient:self];
        if (!successful) {
            NSRunAlertPanel(@"Error", @"Unable to connect to helper application. Please try logging out and logging back in to resolve the issue.", nil, nil, nil);
            [self cleanup];
        }
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Could not connect to MPHelper: %@", e);
        [self cleanup];
    }
}

- (void)connect:(NSError **)err
{
    // Use mach ports for communication, since we're local.
    NSConnection *connection = [NSConnection connectionWithRegisteredName:kMPWorkerPortName host:nil];
	
    [connection setRequestTimeout: 10.0];
    [connection setReplyTimeout: 1800.0]; //30 min to install
	
    @try {
        proxy = [[connection rootProxy] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDown:) name:NSConnectionDidDieNotification object:connection];
		
        [proxy setProtocolForProxy: @protocol(MPWorkerServer)];
        BOOL successful = [proxy registerClient:self];
        if (!successful) {
            NSRunAlertPanel(@"Error", @"Unable to connect to helper application. Please try logging out and logging back in to resolve the issue.", nil, nil, nil);
            NSMutableDictionary *details = [NSMutableDictionary dictionary];
			[details setValue:@"Unable to connect to helper application. Please try logging out and logging back in to resolve the issue." forKey:NSLocalizedDescriptionKey];
            if (err != NULL)  *err = [NSError errorWithDomain:@"world" code:1 userInfo:details];
            [self cleanup];
        }
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Could not connect to MPHelper: %@", e);
        [self cleanup];
    }
}

- (void)cleanup
{
    if (proxy) 
    {
        NSConnection *connection = [proxy connectionForProxy];
        [connection invalidate];
        [proxy release];
        proxy = nil;
    }
	
}

- (void)connectionDown:(NSNotification *)notification 
{
    logit(lcl_vInfo,@"MPWorker connection down");
    [self cleanup];
} 

#pragma mark Client Callbacks
- (void)statusData:(in bycopy NSString *)aData
{
    [spStatusText setStringValue:aData];
}
- (void)installData:(in bycopy NSString *)aData
{
    //[statusTextStatus setStringValue:aData];
}

#pragma mark - Worker Methods

- (int)setCatalogURL
{
    NSError *error = nil;
	int result = 99;
	if (!proxy) {
        [self connect:&error];
        if (error) {
            result = 1001;
        }
        if (!proxy) {
            result = 1002;
            goto done;
        }
    }
	
    @try 
	{
		logit(lcl_vDebug,@"[proxy run setCatalogURL]");
		result = [proxy setCatalogURLViaHelper]; 
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runSetCatalogURLUsingHelper error: %@", e);
		result = 99;
    }
	
done:	
    qltrace(@"Done, setCatalogURL");
	[self cleanup];
	return result;
}

- (void)unSetCatalogURL
{
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try 
	{
		logit(lcl_vDebug,@"[proxy run unSetCatalogURL]");
		[proxy unSetCatalogURLViaHelper]; 
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"unSetCatalogURL error: %@", e);
    }
	
done:	
    qltrace(@"Done, unSetCatalogURL");
	[self cleanup];
	return;
}

- (NSArray *)scanForAppleUpdates:(NSError **)err
{
	NSArray *results = nil;
	NSError *error = nil;
	if (!proxy) {
        [self connect:&error];
        if (error) {
            if (err != NULL) *err = [NSError errorWithDomain:@"scanForAppleUpdates" code:1001 userInfo:nil];
            goto done;
        }
        if (!proxy) {
			logit(lcl_vError,@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		} 
    }
	
	@try {
		results = [NSArray arrayWithArray:[proxy scanForAppleUpdatesViaHelper]];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runTaskUsingHelper [ASUS Scan] error: %@", e);
    }
	
done:
    qltrace(@"Done, scanForAppleUpdates");
	[self cleanup];
	return results;
}

- (NSArray *)scanForCustomUpdates:(NSError **)err
{
    NSArray *results = nil;
	NSError *error = nil;
	if (!proxy) {
        [self connect:&error];
        if (error) {
            if (err != NULL) *err = [NSError errorWithDomain:@"scanForCustomUpdates" code:1001 userInfo:nil];
            goto done;
        }
        if (!proxy) {
			logit(lcl_vError,@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		} 
    }
	
	@try {
		results = [NSArray arrayWithArray:[proxy scanForCustomUpdatesViaHelper]];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runTaskUsingHelper [Custom Scan] error: %@", e);
    }
	
done:
    qltrace(@"Done, scanForCustomUpdates");
	[self cleanup];
	return results;
}

- (int)installAppleSoftwareUpdate:(NSString *)appleUpdate
{
	int result = -1;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try {
		result = [proxy installAppleSoftwareUpdateViaHelper:appleUpdate];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runTaskUsingHelper [ASUS Install] error: %@", e);
		result = 1;
    }
	
done:	
	[self cleanup];
	return result;
}

- (int)installPKG:(NSString *)aPkgPath target:(NSString *)aTarget env:(NSString *)aEnv
{
	int result = 99;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try {
		logit(lcl_vDebug,@"[proxy installPkgToRootViaHelper:%@ target:%@]",aPkgPath, aTarget);
		result = [proxy installPkgToRootViaHelper:aPkgPath env:aEnv];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runPKGInstallUsingHelper [PKG Install] error: %@", e);
		result = 99;
    }
	
done:	
	[self cleanup];
	return result;
}

- (int)runScript:(NSString *)aScript 
{
	int result = 99;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try 
	{
		logit(lcl_vDebug,@"[proxy run script:%@]",aScript);
		result = [proxy runScriptViaHelper:aScript];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runScript error: %@", e);
		result = 99;
    }
	
done:	
	[self cleanup];
	return result;
}

- (void)setLogoutHook
{
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try 
	{
		[proxy setLogoutHookViaHelper];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Trying to set the logout hook, %@", e);
    }
	
done:	
	return;
}

- (BOOL)setPermissionsForFile:(NSString *)aFile
{
	int result = -1;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try 
	{
		result = [proxy setPermissionsForFileViaHelper:aFile posixPerms:0664UL];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Trying to set the logging level, %@", e);
    }
	
done:	
	[self cleanup];
	if (result == -1 || result == 1) { 
		return NO;
	} else {
		return YES;
	}
	
}

- (int)createDirAtPathWithIntermediateDirs:(NSString *)path intermediateDirs:(BOOL)withDirs
{
    int result = -1;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try 
	{
		result = [proxy createDirAtPathWithIntermediateDirectoriesViaHelper:path intermediateDirectories:withDirs];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Trying to create dir at path(%@). %@",path, e);
    }
	
done:	
	[self cleanup];
    return result;
}

- (int)writeDataToFile:(id)data file:(NSString *)aFile
{
    int result = -1;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try 
	{
        result = [proxy writeDataToFileViaHelper:data toFile:aFile];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Trying to write data to file(%@). %@",aFile, e);
    }
	
done:	
	[self cleanup];
    return result;
}

- (int)writeArrayToFile:(NSArray *)data file:(NSString *)aFile
{
    int result = -1;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }
	
    @try
	{
        result = [proxy writeArrayToFileViaHelper:data toFile:aFile];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Trying to write data to file(%@). %@",aFile, e);
    }
	
done:
	[self cleanup];
    return result;
}

- (int)setLoggingState:(BOOL)aState
{
    int result = 0;
    NSError *error = nil;
	if (!proxy) {
        [self connect:&error];
        if (error) {
            result = 1;
        }
        if (!proxy) {
            result = 1;
        }
        goto done;
    }
	
    @try 
	{
		[proxy setDebugLogging:aState];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"Trying to set the logging level, %@", e);
    }
	
done:	
	[self cleanup];
	return result;
}

#pragma mark -
#pragma mark SelfPatch
- (void)showSelfPatchWindow:(id)sender
{
	[spScanAndPatchButton setTitle:@"Scan"];
	[spStatusText setStringValue:@""];
	if ([[arrayController arrangedObjects] count] >= 1) {
		[arrayController removeObjects:[arrayController arrangedObjects]];
		[tableView reloadData];
	}
	
	[window	makeKeyAndOrderFront:sender];
	[window center];
	[NSApp arrangeInFront:sender];
	[NSApp activateIgnoringOtherApps:YES];	
}

- (IBAction)scanForPatches:(id)sender
{
	killTaskThread = NO;
	
	if (runTaskThread != nil) {
		[runTaskThread release];
		runTaskThread = nil;
	}
    
	runTaskThread = [[NSThread alloc] initWithTarget:self selector:@selector(runPatchScan) object:nil];
	[runTaskThread start];
	[spCancelButton setEnabled:YES];
}

- (IBAction)installPatches:(id)sender
{
	if (runTaskThread) {
		[runTaskThread release];
		runTaskThread = nil;
	}
	
	runTaskThread = [[NSThread alloc] initWithTarget:self selector:@selector(runPatchUpdates) object:nil];
	[runTaskThread start];
	[spCancelButton setEnabled:YES];
}

- (void)runPatchScan
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *appleScanError = nil;
    NSError *customScanError = nil;
    
	[arrayController removeObjects:[arrayController arrangedObjects]];
	[tableView reloadData];
	
	[spUpdateButton setEnabled:NO];
	[spStatusProgress startAnimation:self];
	[spStatusText setStringValue:@"Preparing to scan for patches."];
	[spScanAndPatchButton setEnabled:NO];
	
	// Method Valiables
	NSMutableArray *approvedUpdatesArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpDict;
	NSImage *emptyImage = [NSImage imageNamed:@"empty.tif"];
	NSImage *rebootImage = [NSImage imageNamed:@"RestartReq.tif"];
	NSImage *baselineImage = [NSImage imageNamed:@"Installcomplete.tif"];
	
    [mpServerConnection refreshServerObject];
	asus = [[MPAsus alloc] initWithServerConnection:mpServerConnection];
	soap = [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:WS_NAMESPACE];
	
	if (killTaskThread == YES) {
		[spStatusText setStringValue:@"Canceling request..."];
		goto done;
	}
	
	// Get Patch Group Patches
	[spStatusText setStringValue:@"Getting approved patch list for client."];
	NSDictionary *patchGroupPatches = [asus getPatchGroupPatches:[mpServerConnection.mpDefaults objectForKey:@"PatchGroup"] encode:YES];
	if (!patchGroupPatches) {
		NSRunAlertPanel(@"Communications Error", @"There was a issue getting the approved patches for the patch group, scan will exit.", @"OK", nil,nil);
		logit(lcl_vError,@"There was a issue getting the approved patches for the patch group, scan will exit.");
		goto done;
	}
	NSArray *approvedApplePatches = [patchGroupPatches objectForKey:@"AppleUpdates"];
	NSArray *approvedCustomPatches = [patchGroupPatches objectForKey:@"CustomUpdates"]; 
	
	// Scan for Apple Patches
    int catResult = [self setCatalogURL];
	if (catResult != 0) {
        if (catResult == 1001) {
            goto done;
        }
		logit(lcl_vError,@"There was a issue setting the CatalogURL, Apple updates will not occur.");
    }
	
	if (killTaskThread == YES) {
		[spStatusText setStringValue:@"Canceling request..."];
		goto done;
	}
	
	[spStatusText setStringValue:@"Scanning for Apple software updates..."];
    appleScanError = nil;
	NSArray *applePatchesArray = nil;
	applePatchesArray = [self scanForAppleUpdates:&appleScanError];
    if (appleScanError) {
        goto done;
    }
    
	if (killTaskThread == YES) {
		[spStatusText setStringValue:@"Canceling request..."];
		goto done;
	}
	
	// post patches to web service
	MPDataMgr *dataMgr = [[[MPDataMgr alloc] init] autorelease];
	NSString *dataMgrXML;
	dataMgrXML = [dataMgr GenXMLForDataMgr:applePatchesArray
								   dbTable:@"client_patches_apple" 
							 dbTablePrefix:@"mp_" 
							 dbFieldPrefix:@""
							  updateFields:@"cuuid,patch"
								 deleteCol:@"cuuid"
                            deleteColValue:[MPSystemInfo clientUUID]];
	
	
	// Encode to base64 and send to web service	
	NSString *xmlBase64String   = [[dataMgrXML dataUsingEncoding:NSUTF8StringEncoding] encodeBase64WithNewlines:NO];
	NSDictionary	*msgArgs	= [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[MPSystemInfo clientUUID],xmlBase64String,nil] 
														forKeys:[NSArray arrayWithObjects:@"cuuid",@"encodedXML",nil]];
	NSString		*message	= [soap createBasicSOAPMessage:@"DataMgrXML" argDictionary:msgArgs];
	NSError         *p_err      = nil;
	NSData          *soapResult = [soap invoke:message isBase64:NO error:&p_err];
	if (p_err) {
		logit(lcl_vError,@"%@",[p_err localizedDescription]);
	} else {
		NSString *ws = [[[NSString alloc] initWithData:soapResult encoding:NSUTF8StringEncoding] autorelease];
		if ([ws isEqualTo:@"1"] == TRUE || [ws isEqualTo:@"true"] == TRUE) {
			logit(lcl_vInfo,@"Scan results posted to webservice.");
		} else {
			logit(lcl_vError,@"Scan results posted to webservice returned false.");
		}
	}
	
	if (killTaskThread == YES) {
		[spStatusText setStringValue:@"Canceling request..."];
		goto done;
	}
	
	// Process patches
	if (!applePatchesArray) {
		logit(lcl_vInfo,@"The scan results for ASUS scan were nil.");
	} else {
		// If no items in array, lets bail...
		if ([applePatchesArray count] == 0 ) {
			[spStatusText setStringValue:@"No Apple updates found."];
			sleep(1);
		} else {
			// We have Apple patches, now add them to the array of approved patches
			
			
			// If no items in array, lets bail...
			if ([approvedApplePatches count] == 0 ) {
				[spStatusText setStringValue:@"No Patch Group patches found."];
				logit(lcl_vInfo,@"No apple updates found for \"%@\" patch group.",[mpServerConnection.mpDefaults objectForKey:@"PatchGroup"]);
			} else {
				// Build Approved Patches
				[spStatusText setStringValue:@"Building approved patch list..."];
				
				for (int i=0; i<[applePatchesArray count]; i++) {
					for (int x=0;x < [approvedApplePatches count]; x++) {
						if ([[[approvedApplePatches objectAtIndex:x] objectForKey:@"name"] isEqualTo:[[applePatchesArray objectAtIndex:i] objectForKey:@"patch"]]) {
							tmpDict = [[NSMutableDictionary alloc] init];
							[tmpDict setObject:[NSNumber numberWithBool:YES] forKey:@"select"];
							[tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"size"] forKey:@"size"];
							[tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"patch"] forKey:@"patch"];
							[tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"description"] forKey:@"description"];
							[tmpDict setObject:[[applePatchesArray objectAtIndex:i] objectForKey:@"restart"] forKey:@"restart"];
							if ([[[[applePatchesArray objectAtIndex:i] objectForKey:@"restart"] uppercaseString] isEqualTo:@"Y"] || [[[[applePatchesArray objectAtIndex:i] objectForKey:@"restart"] uppercaseString] isEqualTo:@"YES"])
							{
								[tmpDict setObject:rebootImage forKey:@"reboot"];
							} else {
								[tmpDict setObject:emptyImage forKey:@"reboot"];
							}
							if ([[[applePatchesArray objectAtIndex:i] objectForKey:@"baseline"] isEqualTo:@"1"]) {
								[tmpDict setObject:baselineImage forKey:@"baseline"];
								break;
							}
							
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
	if (killTaskThread == YES) {
		[spStatusText setStringValue:@"Canceling request..."];
		goto done;
	}
	
    [spStatusText setStringValue:@"Scanning for custom updates..."];
    [spStatusText display];
    customScanError = nil;
	NSMutableArray *customPatchesArray = (NSMutableArray *)[self scanForCustomUpdates:&customScanError];
	if (customScanError) {
        goto done;
    }
	
	logit(lcl_vDebug,@"Custom Patches Needed: %@",customPatchesArray);
	logit(lcl_vDebug,@"Approved Custom Patches: %@",approvedCustomPatches);
	
	// Filter List of Patches containing only the approved patches
	NSDictionary *customPatch, *approvedPatch;
	[spStatusText setStringValue:@"Building approved patch list..."];
    [spStatusText display];
	for (int i=0; i<[customPatchesArray count]; i++) {
		customPatch	= [customPatchesArray objectAtIndex:i];
		for (int x=0;x < [approvedCustomPatches count]; x++) {
			approvedPatch	= [approvedCustomPatches objectAtIndex:x];
			if ([[customPatch objectForKey:@"patch_id"] isEqualTo:[approvedPatch objectForKey:@"patch_id"]]) {
				logit(lcl_vInfo,@"Patch %@ approved for update.",[customPatch objectForKey:@"description"]);
				tmpDict = [[NSMutableDictionary alloc] init];
				[tmpDict setObject:[NSNumber numberWithBool:YES] forKey:@"select"];
				//[tmpDict setObject:[[approvedPatch objectForKey:@"patches"] objectForKey:@"size"] forKey:@"size"];
				for (id item in [approvedPatch objectForKey:@"patches"]) {
					if ([[item objectForKey:@"type"] isEqualTo:@"1"]) {
						[tmpDict setObject:[NSString stringWithFormat:@"%@K",[item objectForKey:@"size"]] forKey:@"size"];
						break;
					}
				}
				for (id item in [approvedPatch objectForKey:@"patches"]) {
					if ([[item objectForKey:@"baseline"] isEqualTo:@"1"]) {
						[tmpDict setObject:baselineImage forKey:@"baseline"];
						break;
					}
				}
				[tmpDict setObject:[customPatch objectForKey:@"patch"] forKey:@"patch"];
				[tmpDict setObject:[customPatch objectForKey:@"description"] forKey:@"description"];
				[tmpDict setObject:[customPatch objectForKey:@"restart"] forKey:@"restart"];
				if ([[[customPatch objectForKey:@"restart"] uppercaseString] isEqualTo:@"TRUE"] || [[[customPatch objectForKey:@"restart"] uppercaseString] isEqualTo:@"YES"])
				{
					[tmpDict setObject:rebootImage forKey:@"reboot"];
				} else {
					[tmpDict setObject:emptyImage forKey:@"reboot"];
				}
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
	
	if (approvedUpdatesArray && [approvedUpdatesArray count] > 0) {
        
        NSString *_approvedPatchesFile = [NSString stringWithFormat:@"%@/Data/.approvedPatches.plist",MP_ROOT_CLIENT];
        
        BOOL isDir;
        BOOL exists = [fm fileExistsAtPath:[_approvedPatchesFile stringByDeletingLastPathComponent] isDirectory:&isDir];
        if (exists) {
            /* file exists */
            if (!isDir) {
                /* file is a directory */
                logit(lcl_vWarning,@"Unable to create file %@. \"Data\" directory already exists but is not a directory.",_approvedPatchesFile);
            }
        } else {
            [self createDirAtPathWithIntermediateDirs:[_approvedPatchesFile stringByDeletingLastPathComponent] intermediateDirs:YES];
        }
        
        [self writeArrayToFile:(NSArray *)approvedUpdatesArray file:[NSString stringWithFormat:@"%@/Data/.approvedPatches.plist",MP_ROOT_CLIENT]];
        
		[arrayController removeObjects:[arrayController arrangedObjects]];
		[arrayController addObjects:approvedUpdatesArray];	
		[tableView reloadData];
		[tableView deselectAll:self];
	}
	
done:	
	// Create a file to tell MPStatus to update is patch info...
	logit(lcl_vInfo,@"Create CLIENT_PATCH_STATUS_FILE = %@",[CLIENT_PATCH_STATUS_FILE stringByExpandingTildeInPath]);
	[fm createFileAtPath:[CLIENT_PATCH_STATUS_FILE stringByExpandingTildeInPath] 
											contents:[@"update" dataUsingEncoding:NSASCIIStringEncoding] 
										  attributes:nil];
	
	[spStatusText setStringValue:@"Scan Completed."];
	[spStatusText display];
	
	[spStatusProgress stopAnimation:self];
	if  ([approvedUpdatesArray count] <= 0) {
		NSRunAlertPanel(@"Patch Scan Complete", @"There are no patches needed at this time.", @"OK", nil,nil);
	} else {
		logit(lcl_vInfo,@"Patches found %d",(int)[[arrayController arrangedObjects] count]);
		[spStatusText setStringValue:[NSString stringWithFormat:@"%d patches needed.",(int)[[arrayController arrangedObjects] count]]];
		[spStatusText display];
		[spUpdateButton setEnabled:YES];
	}
    
    if (!appleScanError || !customScanError) {
        [self unSetCatalogURL];
	}
    
	[spScanAndPatchButton setEnabled:YES];
	[spCancelButton setEnabled:NO];
	
	[approvedUpdatesArray release];
	[soap release];
	[asus release];
	
	[pool drain];
}

- (void)runPatchUpdates
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[spStatusProgress startAnimation:self];
	[spScanAndPatchButton setEnabled:NO];
	[spUpdateButton setEnabled:NO];
	
	[spStatusText setStringValue:@"Begin patching process."];
	[spStatusText display];
	
	if ([self setCatalogURL] != 0)
		logit(lcl_vError,@"There was a issue setting the CatalogURL, Apple updates will not occur.");
	
	[mpServerConnection refreshServerObject];
	MPAsus *mpAsus = [[[MPAsus alloc] initWithServerConnection:mpServerConnection] autorelease];
	
	NSPredicate         *selectedPatchesPredicate = [NSPredicate predicateWithFormat:@"select == 1"];
	NSMutableArray		*patchesToInstallArray    = [NSMutableArray arrayWithArray:[[arrayController arrangedObjects] filteredArrayUsingPredicate:selectedPatchesPredicate]];
	
	NSDictionary		*patch;
	NSDictionary		*currPatchToInstallDict;
	NSArray				*patchPatchesArray;
	NSString			*infoText;
	NSString			*downloadURL;
	NSError				*err;
	int i;
	int installResult = 1;
	int	launchRebootWindow = 0;
	
	for (i = 0; i < [patchesToInstallArray count]; i++) {
		// Create/Get Dictionary of Patch to install  
		patch = nil;
		patch = [NSDictionary dictionaryWithDictionary:[patchesToInstallArray objectAtIndex:i]];
		logit(lcl_vDebug,@"Checking to see if patch %@ needs a reboot; \"%@\"",[patch objectForKey:@"patch"],[patch objectForKey:@"restart"]);
		
		// Check if patch needs a reboot
		if ([[[patch objectForKey:@"restart"] uppercaseString] isEqualTo:@"N"] || [[[patch objectForKey:@"restart"] uppercaseString] isEqualTo:@"NO"] || [[[patch objectForKey:@"restart"] uppercaseString] isEqualTo:@"FALSE"]) {
			logit(lcl_vInfo,@"Preparing to install %@(%@)",[patch objectForKey:@"patch"],[patch objectForKey:@"version"]);
			logit(lcl_vDebug,@"Patch to process: %@",patch);
			
			/* Disabled for a min
			 if ([self checkPatchPreAndPostForRebootRequired:patchPatchesArray]) {
			 logit(lcl_vInfo,@"One or more of the pre & post installs requires a reboot, this patch will be installed on logout.");
			 continue;
			 }
			 */
			
			// Now proceed to the download and install			
			installResult = -1;
			
			if ([[patch objectForKey:@"type"] isEqualTo:@"Third"]) {
				NSString *infoText = [NSString stringWithFormat:@"Starting install for %@",[patch objectForKey:@"patch"]];
				[spStatusText setStringValue:infoText];
				[spStatusText display];
				
				// Get all of the patches, main and subs
				// This is messed up, not sure why I have an array right within an array, needs to be fixed ...later :-)
				patchPatchesArray = [NSArray arrayWithArray:[[patch objectForKey:@"patches"] objectForKey:@"patches"]];
				logit(lcl_vDebug,@"Current patch has total patches associated with it %d", (int)([patchPatchesArray count]-1));
				
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
					
					// Update table view to show whats installing
					[self updateTableAndArrayController:i status:0];
					[tableView reloadData];
					
					// We have a currPatchToInstallDict to work with
					logit(lcl_vInfo,@"Start install for patch %@ from %@",[currPatchToInstallDict objectForKey:@"url"],[patch objectForKey:@"patch"]);
					
					// First we need to download the update
					@try {
						logit(lcl_vInfo,@"Start download for patch from %@",[currPatchToInstallDict objectForKey:@"url"]);
						[spStatusText setStringValue:[NSString stringWithFormat:@"Downloading %@",[[currPatchToInstallDict objectForKey:@"url"] lastPathComponent]]];
						[spStatusText display];
						//Pre Proxy Config
						downloadURL = [NSString stringWithFormat:@"http://%@/mp-content%@",mpServerConnection.HTTP_HOST,[currPatchToInstallDict objectForKey:@"url"]];
						logit(lcl_vInfo,@"Download patch from: %@",downloadURL);
						err = nil;
						dlPatchLoc = [mpAsus downloadUpdate:downloadURL error:&err];
						if (err) {
							logit(lcl_vError,@"Error downloading a patch, skipping %@. Err Message: %@",[patch objectForKey:@"patch"],[err localizedDescription]);
							[spStatusText setStringValue:[NSString stringWithFormat:@"Error downloading a patch, skipping %@.",[patch objectForKey:@"patch"]]];
							[spStatusText display];
							
							[self updateTableAndArrayController:i status:2];
							[tableView reloadData];
							break;
						}
						[spStatusText setStringValue:[NSString stringWithFormat:@"Patch download completed."]];
						[spStatusText display];
						logit(lcl_vInfo,@"File downloaded to %@",dlPatchLoc);
					}
					@catch (NSException *e) {
						logit(lcl_vError,@"%@", e);
						[self updateTableAndArrayController:i status:2];
						[tableView reloadData];
						break;
					}
					
					// *****************************
					// Validate hash, before install
					[spStatusText setStringValue:[NSString stringWithFormat:@"Validating downloaded patch."]];
					[spStatusText display];
                    
                    MPCrypto *mpCrypto = [[MPCrypto alloc] init];
					NSString *fileHash = [mpCrypto md5HashForFile:dlPatchLoc];
                    [mpCrypto release];
                    
					logit(lcl_vInfo,@"Downloaded file hash: %@ (%@)",fileHash,[currPatchToInstallDict objectForKey:@"hash"]);
					if ([[[currPatchToInstallDict objectForKey:@"hash"] uppercaseString] isEqualTo:[fileHash uppercaseString]] == NO) {
						[spStatusText setStringValue:[NSString stringWithFormat:@"The downloaded file did not pass the file hash validation. No install will occur."]];
						[spStatusText display];
						logit(lcl_vError,@"The downloaded file did not pass the file hash validation. No install will occur.");
						[self updateTableAndArrayController:i status:2];
						[tableView reloadData];
						continue;
					}
					
					// *****************************
					// Now we need to unzip
					[spStatusText setStringValue:[NSString stringWithFormat:@"Uncompressing patch, to begin install."]];
					[spStatusText display];
					logit(lcl_vInfo,@"Begin decompression of file, %@",dlPatchLoc);
					err = nil;
					[mpAsus unzip:dlPatchLoc error:&err];
					if (err) {
						[spStatusText setStringValue:[NSString stringWithFormat:@"Error decompressing a patch, skipping %@.",[patch objectForKey:@"patch"]]];
						[spStatusText display];
						logit(lcl_vError,@"Error decompressing a patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
						[self updateTableAndArrayController:i status:2];
						[tableView reloadData];
						break;
					}
					[spStatusText setStringValue:[NSString stringWithFormat:@"Patch has been uncompressed."]];
					[spStatusText display];
					logit(lcl_vInfo,@"File has been decompressed.");
					
					// *****************************
					// Run PreInstall Script
					if ([[currPatchToInstallDict objectForKey:@"preinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"preinst"] isEqualTo:@"NA"] == NO) {
						[spStatusText setStringValue:[NSString stringWithFormat:@"Begin pre install script."]];
						[spStatusText display];
						NSString *preInstScript = [[currPatchToInstallDict objectForKey:@"preinst"] decodeBase64WithNewLinesReturnString:NO];
						logit(lcl_vDebug,@"preInstScript=%@",preInstScript);
						if ([self runScript:preInstScript] != 0 ) 
						{
							logit(lcl_vError,@"Error (%d) running pre-install script.",(int)installResult);
							[self updateTableAndArrayController:i status:2];
							[tableView reloadData];
							break;
						}
					}
					
					// *****************************
					// Install the update
					BOOL hadErr = NO;
					@try {
						NSString *pkgPath;
						NSString *pkgBaseDir = [dlPatchLoc stringByDeletingLastPathComponent];						
						NSPredicate *pkgPredicate = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
						NSArray *pkgList = [[fm contentsOfDirectoryAtPath:[dlPatchLoc stringByDeletingLastPathComponent] error:NULL] filteredArrayUsingPredicate:pkgPredicate];
						installResult = -1;
						
						// Install pkg(s)
						for (int ii = 0; ii < [pkgList count]; ii++) {
							pkgPath = [NSString stringWithFormat:@"%@/%@",pkgBaseDir,[pkgList objectAtIndex:ii]];
							[spStatusText setStringValue:[NSString stringWithFormat:@"Installing %@",[pkgPath lastPathComponent]]];
							[spStatusText display];
							logit(lcl_vInfo,@"Start install of %@",pkgPath);
							installResult = [self installPKG:pkgPath target:@"/" env:[currPatchToInstallDict objectForKey:@"env"]];
							if (installResult != 0) {
								[spStatusText setStringValue:[NSString stringWithFormat:@"Error installing patch."]];
								[spStatusText display];
								logit(lcl_vError,@"Error installing package, error code %d.",installResult);
								[self updateTableAndArrayController:i status:2];
								[tableView reloadData];
								hadErr = YES;
								break;
							} else {
								[spStatusText setStringValue:[NSString stringWithFormat:@"Install was successful."]];
								[spStatusText display];
								logit(lcl_vInfo,@"%@ was installed successfully.",pkgPath);
							}
						} // End Loop
					}
					@catch (NSException *e) {
						[spStatusText setStringValue:[NSString stringWithFormat:@"Error installing patch."]];
						[spStatusText display];
						logit(lcl_vError,@"%@", e);
						logit(lcl_vError,@"Error attempting to install patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
						[self updateTableAndArrayController:i status:2];
						[tableView reloadData];
						break;
					}
					if (hadErr) {
						// We had an error, try the next one.
						continue;
					}
					
					// *****************************
					// Run PostInstall Script
					if ([[currPatchToInstallDict objectForKey:@"postinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"postinst"] isEqualTo:@"NA"] == NO) {
						[spStatusText setStringValue:[NSString stringWithFormat:@"Begin post install script."]];
						[spStatusText display];
						NSString *postInstScript = [[currPatchToInstallDict objectForKey:@"postinst"] decodeBase64WithNewLinesReturnString:NO];
						logit(lcl_vDebug,@"postInstScript=%@",postInstScript);
						if ([self runScript:postInstScript] != 0 ) 
						{
							break;
						}
					}
					
					// *****************************
					// Instal is complete, post result to web service
					@try {
						[self postInstallToWebService:[patch objectForKey:@"patch_id"] type:@"third"];
					}
					@catch (NSException *e) {
						logit(lcl_vError,@"%@", e);
					}
				    [spStatusText setStringValue:[NSString stringWithFormat:@"Patch install completed."]];
				    [spStatusText display];	 
                    
					[self updateTableAndArrayController:i status:1];
					[tableView reloadData];
					
				} // End patchArray To install
			} else if ([[patch objectForKey:@"type"] isEqualTo:@"Apple"]) {
				// Process Apple Type Patches
				
				infoText = [NSString stringWithFormat:@"Starting install for %@",[patch objectForKey:@"patch"]];
				logit(lcl_vInfo,@"Apple Dict:%@",patch);
				logit(lcl_vInfo,@"%@",infoText);
				
				[spStatusText setStringValue:infoText];
				[spStatusText display];
				
				// Update the table view to show we are in the install process
				[self updateTableAndArrayController:i status:0];
				[tableView reloadData];
				
				
				
				if ([[patch objectForKey:@"hasCriteria"] boolValue] == NO || ![patch objectForKey:@"hasCriteria"]) {
					
					installResult = [self installAppleSoftwareUpdate:[patch objectForKey:@"patch"]];
					
				} else {
					logit(lcl_vInfo,@"%@ has install criteria assigned to it.",[patch objectForKey:@"patch"]);
					
					NSDictionary *criteriaDictPre, *criteriaDictPost;
					NSData *scriptData;
					NSString *scriptText;
					
					int i = 0;
					int s_res;
					// PreInstall First
					if ([patch objectForKey:@"criteria_pre"]) {
						logit(lcl_vInfo,@"Processing pre-install criteria."); 
						for (i=0;i<[[patch objectForKey:@"criteria_pre"] count];i++)
						{
							criteriaDictPre = [[patch objectForKey:@"criteria_pre"] objectAtIndex:i]; 
							
							scriptData = [[criteriaDictPre objectForKey:@"data"] decodeBase64WithNewlines:NO];		
							scriptText = [[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding];
							
							s_res = [self runScript:scriptText];
							if (s_res != 0) {
								installResult = 1;
								logit(lcl_vError,@"Pre-install script returned false for %@. No install will occur.",[patch objectForKey:@"patch"]); 
								[scriptText release];
								goto instResult;
							} else {
								logit(lcl_vInfo,@"Pre-install script returned true.");
							}
							
							[scriptText release];
							criteriaDictPre = nil;
						}
					}	
					// Run the patch install, now that the install has occured.
					installResult = [self installAppleSoftwareUpdate:[patch objectForKey:@"patch"]];
					
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
							scriptText = [[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding];
							
							s_res = [self runScript:scriptText];
							if (s_res != 0) {
								installResult = 1;
								logit(lcl_vError,@"Pre-install script returned false for %@. No install will occur.",[patch objectForKey:@"patch"]); 
								[scriptText release];
								goto instResult;
							} else {
								logit(lcl_vInfo,@"Post-install script returned true.");	
							}
							[scriptText release];
							criteriaDictPost = nil;
						}
					}
				}
                
			instResult:				
				if (installResult != 0) {	
					[spStatusText setStringValue:[NSString stringWithFormat:@"Error installing update, error code %d.",installResult]];
					[spStatusText display];	 
					logit(lcl_vError,@"Error installing update, error code %d.",installResult);
					[self updateTableAndArrayController:i status:2];
					[tableView reloadData];
					continue;
				} else {
					[spStatusText setStringValue:[NSString stringWithFormat:@"%@ was installed successfully.",[patch objectForKey:@"patch"]]];
					[spStatusText display];	 
					logit(lcl_vInfo,@"%@ was installed successfully.",[patch objectForKey:@"patch"]);
					
					// Post the results to web service
					@try {
						[self postInstallToWebService:[patch objectForKey:@"patch"] type:@"apple"];
					}
					@catch (NSException *e) {
						logit(lcl_vError,@"%@", e);
					}
					
					[spStatusText setStringValue:[NSString stringWithFormat:@"Patch install completed."]];
					[spStatusText display];	 
					
					[self updateTableAndArrayController:i status:1];
					[tableView reloadData];
				}
			} else {
				continue;
			}
			
		} else {
			logit(lcl_vInfo,@"%@(%@) requires a reboot, this patch will be installed on logout.",[patch objectForKey:@"patch"],[patch objectForKey:@"version"]);
			launchRebootWindow++;
			[self updateTableAndArrayController:i status:3];
			[tableView reloadData];
			continue;
		}
	} //End patchesToInstallArray For Loop
	
	[spStatusText setStringValue:@"Completed."];
	[spScanAndPatchButton setEnabled:YES];
	[spStatusProgress stopAnimation:nil];
	[tableView reloadData];
	
	// Open the Reboot App
	if (launchRebootWindow > 0) {
		[self setLogoutHook];
		[self openRebootApp];
	}
	
	// Create a file to tell MPStatus to update is patch info...
	[fm createFileAtPath:[CLIENT_PATCH_STATUS_FILE stringByExpandingTildeInPath] 
											contents:[@"update" dataUsingEncoding:NSASCIIStringEncoding] 
										  attributes:nil];
	
	[spCancelButton setEnabled:NO];
	[pool drain];
}

- (void)openRebootApp
{
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];	
	
	if ([fm fileExistsAtPath:MPREBOOT_APP_PATH]) {
		[ws launchApplication:MPREBOOT_APP_PATH];	
	} else {
		logit(lcl_vError,@"MPReboot (%@) is missing, unable to open reboot window.", MPREBOOT_APP_PATH);
	}
}

- (void)updateTableAndArrayController:(int)idx status:(int)aStatusImage
{
	NSPredicate		*selectedPatchesPredicate = [NSPredicate predicateWithFormat:@"select == 1"];
	NSMutableArray	*patches				  = [NSMutableArray arrayWithArray:[[arrayController arrangedObjects] filteredArrayUsingPredicate:selectedPatchesPredicate]];
	
	NSMutableDictionary *patch = [[NSMutableDictionary alloc] initWithDictionary:[patches objectAtIndex:idx]];
	if (aStatusImage == 0) {
		[patch setObject:[NSImage imageNamed:@"NSRemoveTemplate"] forKey:@"statusImage"];
	}
	if (aStatusImage == 1) {
		[patch setObject:[NSImage imageNamed:@"Installcomplete.tif"] forKey:@"statusImage"];
	}
	if (aStatusImage == 2) {
		[patch setObject:[NSImage imageNamed:@"exclamation.tif"] forKey:@"statusImage"];
	}
	if (aStatusImage == 3) {
		[patch setObject:[NSImage imageNamed:@"LogOutReq.tif"] forKey:@"statusImage"];
	}
	[patches replaceObjectAtIndex:idx withObject:patch];
	[arrayController setContent:patches];
	[tableView deselectAll:nil];
	[tableView reloadData];
	
	[patch release];
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

- (void)postInstallToWebService:(NSString *)aPatch type:(NSString *)aType
{
	NSString *cuuid = [MPSystemInfo clientUUID];
	soap = [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:WS_NAMESPACE];
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
	if ([ws2 isEqualTo:@"0"] == YES  || [ws2 isEqualTo:@"false"] == TRUE) {
		logit(lcl_vError,@"Client patch state for (%@) was not posted to webservice.",aPatch);
	}
	
	// We should queue this in case we fail.
	
	//Release Objects
	[ws2 release];
	[ws1 release];
	[dataMgr release];
	[soap release];
}

- (IBAction)showLogInConsole:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/MPSelfPatch.log"] withApplication:@"Console"]; 
}

- (IBAction)stopAndCloseSelfPatch:(id)sender
{
	[spStatusText setStringValue:@"Canceling task..."];
	[self setKillTaskThread:YES];
	if (runTaskThread) {
		[runTaskThread cancel];
		[runTaskThread release];
		runTaskThread = nil;
		[spStatusProgress stopAnimation:nil];		
	}
	
	[spCancelButton setEnabled:NO];
	[spScanAndPatchButton setEnabled:YES];
	[self cleanup];
}

- (IBAction)showPrefsPanel:(id)sender
{
	if (!prefsController)
		prefsController = [[PrefsController alloc] init];
	
	[prefsController showWindow:self];
}

#pragma mark -
#pragma mark Misc
- (NSDictionary *)getClientPatchState
{	
	NSDictionary *patchStateData = NULL;
	soap = [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:WS_NAMESPACE];
	
	// Get the patch group patches
	NSString *message = [soap createSOAPMessage:@"ClientPatchStatus" argName:@"cuuid" argType:@"string" argValue:[MPSystemInfo clientUUID]];
	NSError *err = nil;
	NSData *result = [soap invoke:message isBase64:NO error:&err];
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
		goto done;
	}
	
	
	NSString *returnPlistXML = [[[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding] autorelease];	
	@try {
		patchStateData = [returnPlistXML propertyList];
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"Problem parsing return plist data. %@, %@",[e reason],[e userInfo]);
	}
	
done:	
	[soap release];
	return (NSDictionary *)patchStateData;
}

#pragma mark Notifications
/*
- (void)readInstallData:(NSNotification *)notification
{
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		if ([tmpDict objectForKey:@"pname"]) {
			[spStatusText setStringValue:[NSString stringWithFormat:@"Scanning for %@",[tmpDict objectForKey:@"pname"]]];
			[spStatusText display];	
		}
		if ([tmpDict objectForKey:@"iData"]) {
			logit(lcl_vDebug,@"readInstallData: %@",[tmpDict objectForKey:@"iData"]);
		}	
	}
}

- (void)installStatusCompleteNotify:(NSNotification *)notification
{
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		if ([tmpDict objectForKey:@"patchesNeeded"]) {
			NSNumber *patchesNeeded = [tmpDict objectForKey:@"patchesNeeded"];
			
			[spStatusText setStringValue:[NSString stringWithFormat:@"%d patches needed.",[patchesNeeded intValue]]];
			[spStatusText display];
		}
		gDone = true;
	}	
}
*/
@end
