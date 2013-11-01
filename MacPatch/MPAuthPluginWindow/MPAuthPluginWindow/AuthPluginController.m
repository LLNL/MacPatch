//
//  AuthPluginController.m
//  MPAuthPluginWindow
//
//  Created by Heizer, Charles on 10/30/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "AuthPluginController.h"
#import "FileSizeTransformer.h"

#undef  ql_component
#define ql_component lcl_cMain

// alignments
#define kHorizontalCenterCompensationPercent	0.05f
#define kVerticalCenterCompensationPercent		0.05f

@interface AuthPluginController ()

#pragma mark - Copy

// Helper
- (void)connect;
- (void)connect:(NSError **)err;
- (void)cleanup;
- (void)connectionDown:(NSNotification *)notification;

- (void)toggleStatusProgress;
- (void)scanAndPatch;

- (NSDictionary *)patchGroupPatches;
- (NSArray *)filterFoundPatches:(NSDictionary *)patchGroupPatches applePatches:(NSArray *)apple customePatches:(NSArray *)custom;
- (void)scanHostForPatches;
- (void)updateTableAndArrayController:(int)idx status:(int)aStatusImage;
- (void)postInstallToWebService:(NSString *)aPatch type:(NSString *)aType;


- (void)sendInfo:(NSString *)aField message:(NSString *)aMsg;
#pragma mark - No Copy

- (void)closeWindowNotification:(NSNotification *)note;
- (void)dismissWindow;
@end

@implementation AuthPluginController

@synthesize mpServerConnection;
@synthesize taskThread;
@synthesize killTaskThread;
@synthesize progressCount;
@synthesize progressCountTotal;
@synthesize currentPatchInstallIndex;

- (id)init
{
    self=[super initWithWindowNibName:@"AuthPluginController"];
    if(self)
    {
        //perform any initializations
        [MPLog setupLogging:@"/Library/Logs/MPAuth.log" level:lcl_vDebug];
        lcl_configure_by_name("*", lcl_vDebug);
        qlinfo(@"***** MPAuth started -- Debug Enabled *****");
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        [MPLog setupLogging:@"/Library/Logs/MPAuth.log" level:lcl_vDebug];
        lcl_configure_by_name("*", lcl_vDebug);
        qlinfo(@"***** MPAuth started -- Debug Enabled *****");
    }
    return self;
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeWindowNotification:)
                                                 name:@"closeWindowNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postInfo:)
                                                 name:@"postInfoToTextField"
                                               object:nil];

    mpServerConnection = [[MPServerConnection alloc] init];
    fm = [NSFileManager defaultManager];

}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self scanAndPatch];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark -

enum
{
	kMPInstallRunning = 0,
	kMPInstallComplete = 1,
    kMPInstallError = 2,
	kMPInstallWarning = 3
};
typedef NSUInteger MPInstallIconStatus;

#pragma mark -
#pragma mark MPWorker
- (void)connect
{
    [self connect:NULL];
}

- (void)connect:(NSError **)err
{
    // Use mach ports for communication, since we're local.
    NSConnection *connection = [NSConnection connectionWithRegisteredName:kMPWorkerPortName host:nil];

    [connection setRequestTimeout: 10.0];
    [connection setReplyTimeout: 1800.0]; //30 min to install

    @try {
        proxy = [connection rootProxy];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDown:) name:NSConnectionDidDieNotification object:connection];

        [proxy setProtocolForProxy: @protocol(MPWorkerServer)];
        BOOL successful = [proxy registerClient:self];
        if (!successful)
        {
            NSString *errMsg = @"Unable to connect to helper application. Please try logging out and logging back in to resolve the issue.";
            qlerror(@"%@",errMsg);
            NSMutableDictionary *details = [NSMutableDictionary dictionary];
			[details setValue:errMsg forKey:NSLocalizedDescriptionKey];
            if (err != NULL) *err = [NSError errorWithDomain:@"world" code:1 userInfo:details];
            [self cleanup];
        }
    }
    @catch (NSException *e) {
        qlerror(@"Could not connect to MPWorker: %@", e);
        [self cleanup];
    }
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
    qlinfo(@"MPWorker connection closed.");
    [self cleanup];
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
		qldebug(@"[proxy run setCatalogURL]");
		result = [proxy setCatalogURLViaHelper];
    }
    @catch (NSException *e) {
        qlerror(@"runSetCatalogURLUsingHelper error: %@", e);
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
		qldebug(@"[proxy run unSetCatalogURL]");
		[proxy unSetCatalogURLViaHelper];
    }
    @catch (NSException *e) {
        qlerror(@"unSetCatalogURL error: %@", e);
    }

done:
    qltrace(@"Done, unSetCatalogURL");
	[self cleanup];
	return;
}

- (void)purgeASUSDownloadsViaProxy
{
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }

    @try
	{
		qldebug(@"[proxy run purgeASUSDownloadsViaHelper]");
		[proxy purgeASUSPreDownloadsViaHelper];
    }
    @catch (NSException *e) {
        qlerror(@"purgeASUSDownloadsViaHelper error: %@", e);
    }

done:
    qltrace(@"Done, purgeASUSDownloadsViaHelper");
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
			qlerror(@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		}
    }

	@try {
        [statusText setStringValue:[NSString stringWithFormat:@"Scanning for Apple Patches..."]];
        [statusText display];
		results = [NSArray arrayWithArray:[proxy scanForAppleUpdatesViaHelper]];
    }
    @catch (NSException *e) {
        qlerror(@"runTaskUsingHelper [ASUS Scan] error: %@", e);
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
			qlerror(@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		}
    }

	@try {
        [statusText setStringValue:[NSString stringWithFormat:@"Scanning for Custom Patches..."]];
        [statusText display];
		results = [NSArray arrayWithArray:[proxy scanForCustomUpdatesViaHelper]];
    }
    @catch (NSException *e) {
        qlerror(@"runTaskUsingHelper [Custom Scan] error: %@", e);
    }

done:
    qltrace(@"Done, scanForCustomUpdates");
	[self cleanup];
	return results;
}

- (int)installAppleSoftwareUpdateViaProxy:(NSString *)appleUpdate
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
        qlerror(@"runTaskUsingHelper [ASUS Install] error: %@", e);
		result = 1;
    }

done:
	[self cleanup];
	return result;
}

- (int)installPKGViaProxy:(NSString *)aPkgPath target:(NSString *)aTarget env:(NSString *)aEnv
{
	int result = 99;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }

    @try {
		qldebug(@"[proxy installPkgToRootViaHelper:%@ target:%@]",aPkgPath, aTarget);
		result = [proxy installPkgToRootViaHelper:aPkgPath env:aEnv];
    }
    @catch (NSException *e) {
        qlerror(@"runPKGInstallUsingHelper [PKG Install] error: %@", e);
		result = 99;
    }

done:
	[self cleanup];
	return result;
}

- (int)runScriptViaProxy:(NSString *)aScript
{
	int result = 99;
	if (!proxy) {
        [self connect];
        if (!proxy) goto done;
    }

    @try
	{
		qldebug(@"[proxy run script:%@]",aScript);
		result = [proxy runScriptViaHelper:aScript];
    }
    @catch (NSException *e) {
        qlerror(@"runScript error: %@", e);
		result = 99;
    }
    
done:
	[self cleanup];
	return result;
}

#pragma mark - Notifications
- (void)closeWindowNotification:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissWindow];
}

#pragma mark Client Callbacks
- (void)statusData:(in bycopy NSString *)aData
{
    [statusText setStringValue:aData];
    [statusText display];
}
- (void)installData:(in bycopy NSString *)aData
{
    //[statusTextStatus setStringValue:aData];
}

- (void)postInfo:(NSNotification *)note
{
    if ([[note name] isEqualToString:@"postInfoToTextField"])
    {
        NSDictionary *userInfo = note.userInfo;
        if ([[userInfo objectForKey:@"field"] isEqualToString:@"progressCountText"])
        {
            [progressCountText setStringValue:[userInfo objectForKey:@"message"]];
            [progressCountText display];
        }
    }
}

#pragma mark - Copy Methods

- (void)sendInfo:(NSString *)aField message:(NSString *)aMsg
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:aField,@"field",aMsg,@"message", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"postInfoToTextField" object:nil userInfo:userInfo];
}


- (void)toggleStatusProgress
{
    if ([progressBarStatus isHidden]) {
        [progressBarStatus setHidden:NO];
        [progressBarStatus startAnimation:nil];
    } else {
        [progressBarStatus setHidden:YES];
        [progressBarStatus stopAnimation:nil];
    }
}

- (IBAction)scanAndPatchHost:(id)sender
{
    [self scanAndPatch];
}

- (void)scanAndPatch
{
    progressCount = 0;
    progressCountTotal = 0;

    [statusText setHidden:NO];
    [statusText setStringValue:@"..."];
    [progressText setHidden:NO];
    [progressText setStringValue:@"..."];
    [progressCountText setHidden:NO];
    [progressCountText setStringValue:@"..."];
    [progressBarStatus setHidden:YES];
    [progressBarStatus stopAnimation:nil];
    [progressBarProgress setHidden:YES];
    [progressBarProgress stopAnimation:nil];

    killTaskThread = NO;

	if (taskThread != nil) {
		taskThread = nil;
	}

	//taskThread = [[NSThread alloc] initWithTarget:self selector:@selector(scanHostForPatches) object:nil];
	//[taskThread start];
    [self performSelectorInBackground:@selector(scanHostForPatches) withObject:nil];
    
}

- (NSDictionary *)patchGroupPatches
{
    NSDictionary *patchGroupPatches = nil;
    MPJson *json = [[MPJson alloc] initWithServerConnection:mpServerConnection cuuid:[MPSystemInfo clientUUID]];
	// Get Patch Group Patches
	qlinfo(@"Getting approved patch list for client.");
    patchGroupPatches = [json downloadPatchGroupContent:NULL];
	if (!patchGroupPatches) {
		qlerror(@"There was a issue getting the approved patches for the patch group, scan will exit.");
        return nil;
	}

    return patchGroupPatches;
}

- (NSArray *)filterFoundPatches:(NSDictionary *)patchGroupPatches applePatches:(NSArray *)apple customePatches:(NSArray *)custom
{
    NSMutableArray *approvedUpdatesArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *tmpPatchDict;
    NSDictionary *customPatch;
    NSDictionary *approvedPatch;

    NSArray *approvedApplePatches;
	NSArray *approvedCustomPatches;
    // Sort Apple & Custom PatchGroup Patches
    approvedApplePatches = [patchGroupPatches objectForKey:@"AppleUpdates"];
	approvedCustomPatches = [patchGroupPatches objectForKey:@"CustomUpdates"];


    // Filter Apple Patches
	if (!apple) {
		qlinfo(@"The scan results for ASUS scan were nil.");
	} else {
		// If no items in array, lets bail...
		if ([apple count] == 0 ) {
			qlinfo(@"No Apple updates found.");
			sleep(1);
		} else {
			// We have Apple patches, now add them to the array of approved patches

			// If no items in array, lets bail...
			if ([approvedApplePatches count] == 0 ) {
				qlinfo(@"No Patch Group patches found.");
				qlinfo(@"No apple updates found for \"%@\" patch group.",[mpServerConnection.mpDefaults objectForKey:@"PatchGroup"]);
			} else {
				// Build Approved Patches
				qlinfo(@"Building approved apple patch list...");
				for (int i=0; i<[apple count]; i++) {
					for (int x=0;x < [approvedApplePatches count]; x++) {
						if ([[[approvedApplePatches objectAtIndex:x] objectForKey:@"name"] isEqualTo:[[apple objectAtIndex:i] objectForKey:@"patch"]]) {
							qlinfo(@"Patch %@ approved for update.",[[approvedApplePatches objectAtIndex:x] objectForKey:@"name"]);
							tmpPatchDict = [[NSMutableDictionary alloc] init];
                            [tmpPatchDict setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
                            [tmpPatchDict setObject:[[apple objectAtIndex:i] objectForKey:@"patch"] forKey:@"patch"];
                            [tmpPatchDict setObject:[[apple objectAtIndex:i] objectForKey:@"size"] forKey:@"size"];
                            [tmpPatchDict setObject:[[apple objectAtIndex:i] objectForKey:@"description"] forKey:@"description"];
                            [tmpPatchDict setObject:[[apple objectAtIndex:i] objectForKey:@"restart"] forKey:@"restart"];
                            [tmpPatchDict setObject:[[apple objectAtIndex:i] objectForKey:@"version"] forKey:@"version"];
                            [tmpPatchDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"hasCriteria"] forKey:@"hasCriteria"];

							if ([[[approvedApplePatches objectAtIndex:x] objectForKey:@"hasCriteria"] boolValue] == YES) {
								if ([[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] && [[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] count] > 0) {
									[tmpPatchDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_pre"] forKey:@"criteria_pre"];
								}
                                if ([[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] && [[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] count] > 0) {
                                    [tmpPatchDict setObject:[[approvedApplePatches objectAtIndex:x] objectForKey:@"criteria_post"] forKey:@"criteria_post"];
								}
							}

                            [tmpPatchDict setObject:[NSImage imageNamed:@"apple"] forKey:@"typeImg"];
							[tmpPatchDict setObject:@"Apple" forKey:@"type"];
							[approvedUpdatesArray addObject:tmpPatchDict];
                            qldebug(@"Apple Patch Dictionary Added: %@",tmpPatchDict);
							break;
						}
					}
				}
			}
		}
	}

	// Filter Custom Patches
	qlinfo(@"Building approved custom patch list...");
	for (int i=0; i<[custom count]; i++) {
		customPatch	= [custom objectAtIndex:i];
		for (int x=0;x < [approvedCustomPatches count]; x++) {
			approvedPatch = [approvedCustomPatches objectAtIndex:x];
			if ([[customPatch objectForKey:@"patch_id"] isEqualTo:[approvedPatch objectForKey:@"patch_id"]]) {
				qlinfo(@"Patch %@ approved for update.",[customPatch objectForKey:@"description"]);
				tmpPatchDict = [[NSMutableDictionary alloc] init];
                [tmpPatchDict setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
				[tmpPatchDict setObject:[customPatch objectForKey:@"patch"] forKey:@"patch"];
                for (id item in [approvedPatch objectForKey:@"patches"]) {
					if ([[item objectForKey:@"type"] isEqualTo:@"1"]) {
						[tmpPatchDict setObject:[NSString stringWithFormat:@"%@K",[item objectForKey:@"size"]] forKey:@"size"];
						break;
					}
				}
                [tmpPatchDict setObject:[customPatch objectForKey:@"description"] forKey:@"description"];
                [tmpPatchDict setObject:[customPatch objectForKey:@"restart"] forKey:@"restart"];
                [tmpPatchDict setObject:[customPatch objectForKey:@"version"] forKey:@"version"];
                [tmpPatchDict setObject:approvedPatch forKey:@"patches"];
                [tmpPatchDict setObject:[customPatch objectForKey:@"patch_id"] forKey:@"patch_id"];

                [tmpPatchDict setObject:[NSImage imageNamed:@"MPLogo_64x64"] forKey:@"typeImg"];
                [tmpPatchDict setObject:@"Third" forKey:@"type"];

				[approvedUpdatesArray addObject:tmpPatchDict];
                qldebug(@"Custom Patch Dictionary Added: %@",tmpPatchDict);
				break;
			}
		}
	}

    return (NSArray *)approvedUpdatesArray;
}

- (void)scanHostForPatches
{
    @autoreleasepool
    {
        [self toggleStatusProgress];

        NSError *error = nil;
        NSArray *resultApple = nil;
        NSArray *resultCustom = nil;
        NSArray *approvedPatches = nil;

        // Scan for Apple Patches
        error = nil;
        resultApple = [self scanForAppleUpdates:&error];
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }

        // Scan for Custom Patches
        error = nil;
        resultCustom = [self scanForCustomUpdates:&error];
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }

        // Filter the found patches against the patch group patches
        [statusText setStringValue:@"Compiling approved patches from scan list."];
        [statusText display];
        approvedPatches = [self filterFoundPatches:[self patchGroupPatches]
                                      applePatches:resultApple
                                    customePatches:resultCustom];


        progressCountTotal = (int)[approvedPatches count];
        [progressText setStringValue:[NSString stringWithFormat:@"Updates to install: %d",progressCountTotal]];
        [progressText display];

		//Set Progress Bar Max Value
        [progressBarProgress setIndeterminate:NO];
        [progressBarProgress setDoubleValue:0.0];
		[progressBarProgress setMaxValue:progressCountTotal];

		if (approvedPatches && [approvedPatches count] > 0)
        {
			[patchesArrayController removeObjects:[patchesArrayController arrangedObjects]];
			[patchesArrayController addObjects:approvedPatches];
			[patchesTableView reloadData];
			[patchesTableView deselectAll:self];
			[patchesTableView display];
		}
        

        [statusText setStringValue:@"Patch scanning completed."];
        [statusText display];

        // Begin Patching
        MPAsus          *mpAsus = [[MPAsus alloc] initWithServerConnection:mpServerConnection];
        NSDictionary	*patch;
        NSDictionary	*currPatchToInstallDict;
        NSArray			*patchPatchesArray;
        NSString		*downloadURL;
        NSString		*infoText;
        NSError			*err;
        int i;
        int installResult = 1;

        for (i = 0; i < [approvedPatches count]; i++)
        {
            // Create/Get Dictionary of Patch to install
            patch = nil;
            patch = [NSDictionary dictionaryWithDictionary:[approvedPatches objectAtIndex:i]];

            logit(lcl_vInfo,@"Preparing to install %@(%@)",[patch objectForKey:@"patch"],[patch objectForKey:@"version"]);
            logit(lcl_vDebug,@"Patch to process: %@",patch);

            //progressCountText.stringValue = @"Install it ....";
            //[progressCountText setStringValue:[NSString stringWithFormat:@"%d of %d Patches",i,(int)[approvedPatches count]]];
            //[progressCountText display];
            [self sendInfo:@"progressCountText" message:@"Install it ...."];

            // Now proceed to the download and install
            installResult = -1;

            if ([[patch objectForKey:@"type"] isEqualTo:@"Third"])
            {
                NSString *infoText = [NSString stringWithFormat:@"Starting install for %@",[patch objectForKey:@"patch"]];
                [progressText setStringValue:infoText];
                [progressText setNeedsDisplay:YES];
                [progressText display];

                // Get all of the patches, main and subs
                // This is messed up, not sure why I have an array right within an array, needs to be fixed ...later :-)
                patchPatchesArray = [NSArray arrayWithArray:[[patch objectForKey:@"patches"] objectForKey:@"patches"]];
                logit(lcl_vDebug,@"Current patch has total patches associated with it %d", (int)([patchPatchesArray count]-1));

                NSString *dlPatchLoc; //Download location Path
                int patchIndex = 0;
                for (patchIndex=0;patchIndex < [patchPatchesArray count];patchIndex++)
                {
                    // Make sure we only process the dictionaries in the NSArray
                    if ([[patchPatchesArray objectAtIndex:patchIndex] isKindOfClass:[NSDictionary class]])
                    {
                        currPatchToInstallDict = [NSDictionary dictionaryWithDictionary:[patchPatchesArray objectAtIndex:patchIndex]];
                    } else {
                        logit(lcl_vInfo,@"Object found was not of dictionary type; could be a problem. %@",[patchPatchesArray objectAtIndex:patchIndex]);
                        continue;
                    }

                    // Update table view to show whats installing
                    [self updateTableAndArrayController:i status:0];
                    [patchesTableView reloadData];

                    // We have a currPatchToInstallDict to work with
                    logit(lcl_vInfo,@"Start install for patch %@ from %@",[currPatchToInstallDict objectForKey:@"url"],[patch objectForKey:@"patch"]);

                    // First we need to download the update
                    @try
                    {
                        logit(lcl_vInfo,@"Start download for patch from %@",[currPatchToInstallDict objectForKey:@"url"]);
                        [progressText setStringValue:[NSString stringWithFormat:@"Downloading %@",[[currPatchToInstallDict objectForKey:@"url"] lastPathComponent]]];
                        [progressText display];
                        //Pre Proxy Config
                        downloadURL = [NSString stringWithFormat:@"http://%@/mp-content%@",mpServerConnection.HTTP_HOST,[currPatchToInstallDict objectForKey:@"url"]];
                        logit(lcl_vInfo,@"Download patch from: %@",downloadURL);
                        err = nil;
                        dlPatchLoc = [mpAsus downloadUpdate:downloadURL error:&err];
                        if (err) {
                            logit(lcl_vError,@"Error downloading a patch, skipping %@. Err Message: %@",[patch objectForKey:@"patch"],[err localizedDescription]);
                            [progressText setStringValue:[NSString stringWithFormat:@"Error downloading a patch, skipping %@.",[patch objectForKey:@"patch"]]];
                            [progressText display];

                            [self updateTableAndArrayController:i status:2];
                            [patchesTableView reloadData];
                            break;
                        }
                        [progressText setStringValue:[NSString stringWithFormat:@"Patch download completed."]];
                        [progressText display];
                        logit(lcl_vInfo,@"File downloaded to %@",dlPatchLoc);
                    }
                    @catch (NSException *e)
                    {
                        logit(lcl_vError,@"%@", e);
                        [self updateTableAndArrayController:i status:2];
                        [patchesTableView reloadData];
                        break;
                    }

                    // *****************************
                    // Validate hash, before install
                    [progressText setStringValue:[NSString stringWithFormat:@"Validating downloaded patch."]];
                    [progressText display];

                    MPCrypto *mpCrypto = [[MPCrypto alloc] init];
                    NSString *fileHash = [mpCrypto md5HashForFile:dlPatchLoc];

                    logit(lcl_vInfo,@"Downloaded file hash: %@ (%@)",fileHash,[currPatchToInstallDict objectForKey:@"hash"]);
                    if ([[[currPatchToInstallDict objectForKey:@"hash"] uppercaseString] isEqualTo:[fileHash uppercaseString]] == NO)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"The downloaded file did not pass the file hash validation. No install will occur."]];
                        [progressText display];
                        logit(lcl_vError,@"The downloaded file did not pass the file hash validation. No install will occur.");
                        [self updateTableAndArrayController:i status:2];
                        [patchesTableView reloadData];
                        continue;
                    }

                    // *****************************
                    // Now we need to unzip
                    [progressText setStringValue:[NSString stringWithFormat:@"Uncompressing patch, to begin install."]];
                    [progressText display];
                    logit(lcl_vInfo,@"Begin decompression of file, %@",dlPatchLoc);
                    err = nil;
                    [mpAsus unzip:dlPatchLoc error:&err];
                    if (err)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"Error decompressing a patch, skipping %@.",[patch objectForKey:@"patch"]]];
                        [progressText display];
                        logit(lcl_vError,@"Error decompressing a patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
                        [self updateTableAndArrayController:i status:2];
                        [patchesTableView reloadData];
                        break;
                    }
                    [progressText setStringValue:[NSString stringWithFormat:@"Patch has been uncompressed."]];
                    [progressText display];
                    logit(lcl_vInfo,@"File has been decompressed.");

                    // *****************************
                    // Run PreInstall Script
                    if ([[currPatchToInstallDict objectForKey:@"preinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"preinst"] isEqualTo:@"NA"] == NO)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"Begin pre install script."]];
                        [progressText display];
                        NSString *preInstScript = [[currPatchToInstallDict objectForKey:@"preinst"] decodeBase64WithNewLinesReturnString:NO];
                        logit(lcl_vDebug,@"preInstScript=%@",preInstScript);
                    #ifdef DEBUG
                        [progressText setStringValue:[NSString stringWithFormat:@"Run pre-install script."]];
                        [progressText display];
                        sleep(2);
                    #else
                        if ([self runScriptViaProxy:preInstScript] != 0 )
                        {
                            logit(lcl_vError,@"Error (%d) running pre-install script.",(int)installResult);
                            [self updateTableAndArrayController:i status:2];
                            [patchesTableView reloadData];
                            break;
                        }
                    #endif
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
                            [progressText setStringValue:[NSString stringWithFormat:@"Installing %@",[pkgPath lastPathComponent]]];
                            [progressText display];
                            logit(lcl_vInfo,@"Start install of %@",pkgPath);
                        #ifdef DEBUG
                            sleep(2);
                            [progressText setStringValue:[NSString stringWithFormat:@"Install was successful."]];
                            [progressText display];
                            logit(lcl_vInfo,@"%@ was installed successfully.",pkgPath);
                        #else
                            installResult = [self installPKGViaProxy:pkgPath target:@"/" env:[currPatchToInstallDict objectForKey:@"env"]];
                            if (installResult != 0) {
                                [progressText setStringValue:[NSString stringWithFormat:@"Error installing patch."]];
                                [progressText display];
                                logit(lcl_vError,@"Error installing package, error code %d.",installResult);
                                [self updateTableAndArrayController:i status:2];
                                [patchesTableView reloadData];
                                hadErr = YES;
                                break;
                            } else {
                                [progressText setStringValue:[NSString stringWithFormat:@"Install was successful."]];
                                [progressText display];
                                logit(lcl_vInfo,@"%@ was installed successfully.",pkgPath);
                            }
                        #endif
                        } // End Loop
                    }
                    @catch (NSException *e)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"Error installing patch."]];
                        [progressText display];
                        logit(lcl_vError,@"%@", e);
                        logit(lcl_vError,@"Error attempting to install patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
                        [self updateTableAndArrayController:i status:2];
                        [patchesTableView reloadData];
                        break;
                    }
                    if (hadErr)
                    {
                        // We had an error, try the next one.
                        continue;
                    }

                    // *****************************
                    // Run PostInstall Script
                    if ([[currPatchToInstallDict objectForKey:@"postinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"postinst"] isEqualTo:@"NA"] == NO)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"Begin post install script."]];
                        [progressText display];
                        NSString *postInstScript = [[currPatchToInstallDict objectForKey:@"postinst"] decodeBase64WithNewLinesReturnString:NO];
                        logit(lcl_vDebug,@"postInstScript=%@",postInstScript);
                    #ifdef DEBUG
                        [progressText setStringValue:[NSString stringWithFormat:@"Install was successful."]];
                        [progressText display];
                        sleep(2);
                    #else
                        if ([self runScriptViaProxy:postInstScript] != 0 )
                        {
                            break;
                        }
                    #endif
                    }

                    // *****************************
                    // Instal is complete, post result to web service
                    @try
                    {
                        [self postInstallToWebService:[patch objectForKey:@"patch_id"] type:@"third"];
                    }
                    @catch (NSException *e) {
                        logit(lcl_vError,@"%@", e);
                    }
                    [progressText setStringValue:[NSString stringWithFormat:@"Patch install completed."]];
                    [progressText display];

                    [self updateTableAndArrayController:i status:1];
                    [patchesTableView reloadData];

                } // End patchArray To install
            }
            else if ([[patch objectForKey:@"type"] isEqualTo:@"Apple"])
            {
                // Process Apple Type Patches
                infoText = [NSString stringWithFormat:@"Starting install for %@",[patch objectForKey:@"patch"]];
                logit(lcl_vInfo,@"Apple Dict:%@",patch);
                logit(lcl_vInfo,@"%@",infoText);

                [progressText setStringValue:infoText];
                [progressText display];

                // Update the table view to show we are in the install process
                [self updateTableAndArrayController:i status:0];
                [patchesTableView reloadData];
                    

                if ([[patch objectForKey:@"hasCriteria"] boolValue] == NO || ![patch objectForKey:@"hasCriteria"])
                {
                #ifdef DEBUG
                    [progressText setStringValue:[NSString stringWithFormat:@"Install apple update."]];
                    [progressText display];
                    sleep(2);
                #else
                    installResult = [self installAppleSoftwareUpdateViaProxy:[patch objectForKey:@"patch"]];
                #endif
                }
                else
                {
                    logit(lcl_vInfo,@"%@ has install criteria assigned to it.",[patch objectForKey:@"patch"]);
                    
                    NSDictionary *criteriaDictPre, *criteriaDictPost;
                    NSData *scriptData;
                    NSString *scriptText;
                    
                    int i = 0;
                    int s_res;
                    // PreInstall First
                    if ([patch objectForKey:@"criteria_pre"])
                    {
                        logit(lcl_vInfo,@"Processing pre-install criteria."); 
                        for (i=0;i<[[patch objectForKey:@"criteria_pre"] count];i++)
                        {
                            criteriaDictPre = [[patch objectForKey:@"criteria_pre"] objectAtIndex:i]; 
                            
                            scriptData = [[criteriaDictPre objectForKey:@"data"] decodeBase64WithNewlines:NO];		
                            scriptText = [[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding];
                        #ifdef DEBUG
                            [progressText setStringValue:[NSString stringWithFormat:@"Run pre-install criteria."]];
                            [progressText display];
                            sleep(2);
                        #else
                            s_res = [self runScriptViaProxy:scriptText];
                            if (s_res != 0) {
                                installResult = 1;
                                logit(lcl_vError,@"Pre-install script returned false for %@. No install will occur.",[patch objectForKey:@"patch"]);
                                goto instResult;
                            } else {
                                logit(lcl_vInfo,@"Pre-install script returned true.");
                            }
                            criteriaDictPre = nil;
                        #endif
                        }
                    }
                    // Run the patch install, now that the install has occured.
                #ifdef DEBUG
                    [progressText setStringValue:[NSString stringWithFormat:@"Install apple update."]];
                    [progressText display];
                    sleep(2);
                #else
                    installResult = [self installAppleSoftwareUpdateViaProxy:[patch objectForKey:@"patch"]];
                #endif
                    // If Install retuened anything but 0, the dont run post criteria
                    if (installResult != 0)
                    {
                        logit(lcl_vError,@"The install for %@ returned an error.",[patch objectForKey:@"patch"]); 
                        goto instResult;
                    }
                    
                    if ([patch objectForKey:@"criteria_post"])
                    {
                        logit(lcl_vInfo,@"Processing post-install criteria.");  
                        for (i=0;i<[[patch objectForKey:@"criteria_post"] count];i++)
                        {
                            criteriaDictPost = [[patch objectForKey:@"criteria_post"] objectAtIndex:i];
                            
                            scriptData = [[criteriaDictPost objectForKey:@"data"] decodeBase64WithNewlines:NO];		
                            scriptText = [[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding];
                        #ifdef DEBUG
                            [progressText setStringValue:[NSString stringWithFormat:@"Run post-install criteria."]];
                            [progressText display];
                            sleep(2);
                        #else
                            s_res = [self runScriptViaProxy:scriptText];
                            if (s_res != 0) {
                                installResult = 1;
                                logit(lcl_vError,@"Pre-install script returned false for %@. No install will occur.",[patch objectForKey:@"patch"]);
                                goto instResult;
                            } else {
                                logit(lcl_vInfo,@"Post-install script returned true.");	
                            }
                            criteriaDictPost = nil;
                        #endif
                        }
                    }

                    instResult:
                    if (installResult != 0)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"Error installing update, error code %d.",installResult]];
                        [progressText display];
                        logit(lcl_vError,@"Error installing update, error code %d.",installResult);
                        [self updateTableAndArrayController:i status:2];
                        [patchesTableView reloadData];
                        continue;
                    }
                    else
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"%@ was installed successfully.",[patch objectForKey:@"patch"]]];
                        [progressText display];
                        logit(lcl_vInfo,@"%@ was installed successfully.",[patch objectForKey:@"patch"]);

                        // Post the results to web service
                        @try {
                            [self postInstallToWebService:[patch objectForKey:@"patch"] type:@"apple"];
                        }
                        @catch (NSException *e) {
                            logit(lcl_vError,@"%@", e);
                        }

                        [progressText setStringValue:[NSString stringWithFormat:@"Patch install completed."]];
                        [progressText display];

                        [self updateTableAndArrayController:i status:1];
                        [patchesTableView reloadData];
                    }
                }
            }
            else
            {
                // Not Apple or Custom Patch
                continue;
            }
        }

        [self toggleStatusProgress];
    } // Autorelease Pool
}

- (void)updateTableAndArrayController:(int)idx status:(int)aStatusImage
{
	//NSPredicate		*selectedPatchesPredicate = [NSPredicate predicateWithFormat:@"select == 1"];
	//NSMutableArray	*patches				  = [NSMutableArray arrayWithArray:[[patchesArrayController arrangedObjects] filteredArrayUsingPredicate:selectedPatchesPredicate]];
    NSMutableArray      *patches = [NSMutableArray arrayWithArray:[patchesArrayController arrangedObjects]];
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
	[patchesArrayController setContent:patches];
	[patchesTableView reloadData];
}

- (void)postInstallToWebService:(NSString *)aPatch type:(NSString *)aType
{
    BOOL result = NO;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    NSError *wsErr = nil;
    result = [mpws postPatchInstallResultsToWebService:aPatch patchType:aType error:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"%@",wsErr.localizedDescription);
    } else {
        if (result == TRUE) {
            logit(lcl_vInfo,@"Patch (%@) install result was posted to webservice.",aPatch);
        } else {
            logit(lcl_vError,@"Patch (%@) install result was not posted to webservice.",aPatch);
        }
    }

    return;
}

#pragma mark - No Copy
- (void)dismissWindow
{
    NSLog(@"dismissWindow");
	// Hide window in either case
	[[self window] orderOut:nil];
}

- (IBAction)closeit:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"closeWindowNotification" object:nil];
}


@end
