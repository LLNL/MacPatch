//
//  MPAuthWindow.m
//  MPAuthPlugin
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

#import <AppKit/AppKit.h>
#import "MacPatch.h"
#import "MPAuthWindow.h"
#import "MPAuthController.h"

// alignments
#define kHorizontalCenterCompensationPercent	0.05f
#define kVerticalCenterCompensationPercent		0.05f

#undef  ql_component
#define ql_component lcl_cMain

@interface FileSizeTransformer : NSValueTransformer

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

@interface MPAuthWindow ()

- (void)toggleFullScreen;
- (void)toggleStatusProgress;

// Helper
- (void)connect;
- (void)connect:(NSError **)err;
- (void)cleanup;
- (void)connectionDown:(NSNotification *)notification;

// Worker Methods
- (int)setCatalogURL;
- (void)unSetCatalogURL;
- (void)purgeASUSDownloadsViaProxy;

//- (void)installPatches;
- (NSArray *)scanForAppleUpdates:(NSError **)err;
- (NSArray *)scanForCustomUpdates:(NSError **)err;

- (int)installAppleSoftwareUpdateViaProxy:(NSString *)appleUpdate;
- (int)installPKGViaProxy:(NSString *)aPkgPath target:(NSString *)aTarget env:(NSString *)aEnv;
- (int)runScriptViaProxy:(NSString *)aScript;

// MP
- (void)scanAndPatch;
- (void)scanHostForPatches;

- (NSImage *)imageForName:(NSString*)iName;

- (void)sendReboot;

@end

@implementation MPAuthWindow

@synthesize mpServerConnection;
@synthesize taskThread;
@synthesize killTaskThread;
@synthesize progressCount;
@synthesize progressCountTotal;
@synthesize currentPatchInstallIndex;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [self setLevel: NSStatusWindowLevel+1];
    [self setHasShadow: YES];
    [self orderFrontRegardless];
	[self center];

	return self;
}

#pragma mark -

enum {
	kMPInstallRunning = 0,
	kMPInstallComplete = 1,
    kMPInstallError = 2,
	kMPInstallWarning = 3
};
typedef NSUInteger MPInstallIconStatus;

#pragma mark -

- (void)awakeFromNib
{
    mpServerConnection = [[MPServerConnection alloc] init];
    fm = [NSFileManager defaultManager];

    [self toggleFullScreen];
    [self scanAndPatch];
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (void)centerOurWindow
{
	NSRect screenFrame, windowFrame;

	// get the necessary frames
	screenFrame = [[NSScreen mainScreen] frame];
	windowFrame = [self frame];

	// calculate the new window frame
	windowFrame.origin.x = (screenFrame.size.width - windowFrame.size.width) * 0.5f;
	windowFrame.origin.y = ((screenFrame.size.height - windowFrame.size.height) * 0.5f) +
    (screenFrame.size.height * kVerticalCenterCompensationPercent);

	// set the windows frame
	[self setFrame: windowFrame display: [self isVisible]];
}

- (void)countDownToClose
{
    for (int i = 0; i < 5;i++)
    {
        // Message that window is closing
        statusText.stringValue = [NSString stringWithFormat:@"Rebooting system in %d seconds...",(5-i)];
        [statusText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
        sleep(1);
    }

    statusText.stringValue = @"Rebooting System Please Be Patient...";
    [statusText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
    
    [self sendReboot];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeWindowNotification" object:self userInfo:nil];

}

- (void)toggleFullScreen
{
    fullscreen = !fullscreen;
    if(fullscreen) {
        NSRect screenRect = [[NSScreen mainScreen] frame];
        [self setStyleMask:NSBorderlessWindowMask];
        [self setFrame:screenRect display:YES];
        [self setBackgroundColor:[NSColor darkGrayColor]];
        [self setHidesOnDeactivate:YES];
    }
}

- (NSImage *)imageForName:(NSString*)iName
{
    NSImage *_img;
    _img = [NSImage imageNamed:NSImageNameRemoveTemplate];
    @try
    {
        NSBundle *myBundle = [NSBundle bundleWithIdentifier:BUNDLE_ID];
        qlerror(@"CEH resourcePath: %@",[myBundle resourcePath]);
        NSArray *rFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[myBundle resourcePath] error:NULL];
        for (NSString *file in rFiles)
        {
            NSRange isRange = [file rangeOfString:iName options:NSCaseInsensitiveSearch];
            if(isRange.location == 0) {
                _img = [[NSImage alloc] initWithContentsOfFile:[[myBundle resourcePath] stringByAppendingPathComponent:file]];
                break;
            }
        }
    }
    @catch (NSException *exception) {
        qlerror(@"%@",exception);
    }
    return _img;
}

#pragma mark - MacPatch Functions

- (void)scanAndPatch
{
    progressCount = 0;
    progressCountTotal = 0;

    [statusText setHidden:NO];
    [statusText setStringValue:@""];
    [progressText setHidden:NO];
    [progressText setStringValue:@""];
    [progressCountText setHidden:NO];
    [progressCountText setStringValue:@""];
    [progressBarStatus setHidden:YES];
    [progressBarStatus stopAnimation:nil];
    [progressBarProgress setHidden:YES];
    [progressBarProgress stopAnimation:nil];

    killTaskThread = NO;

	if (taskThread != nil) {
		taskThread = nil;
	}

	taskThread = [[NSThread alloc] initWithTarget:self selector:@selector(scanHostForPatches) object:nil];
	[taskThread start];
}

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

- (void)sendReboot
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
            [self cleanup];
            return;
        }
    }

    @try
	{
		qldebug(@"[proxy run reboot]");
		[proxy logoutInstallCompletion:0]; //Just Reboot for now
    }
    @catch (NSException *e) {
        qlerror(@"runSetCatalogURLUsingHelper error: %@", e);
    }
}

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

#pragma mark Client Callbacks
- (void)statusData:(in bycopy NSString *)aData
{
    [statusText setStringValue:aData];
    [statusText display];
}

- (void)installData:(in bycopy NSString *)aData
{
    //[statusTextStatus setStringValue:aData];
    qldebug(@"[installData]: %@",aData);
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

                            [tmpPatchDict setObject:[self imageForName:@"AppleLogo"] forKey:@"typeImg"];
							[tmpPatchDict setObject:@"Apple" forKey:@"type"];
                            [tmpPatchDict setObject:[[approvedApplePatches objectAtIndex:i] objectForKey:@"patch_install_weight"] forKey:@"patch_install_weight"];
                            [tmpPatchDict setObject:[self imageForName:@"Empty"] forKey:@"statusImage"];
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

                [tmpPatchDict setObject:[self imageForName:@"MPLogo_64x64"] forKey:@"typeImg"];
                [tmpPatchDict setObject:[self imageForName:@"Empty"] forKey:@"statusImage"];
                [tmpPatchDict setObject:@"Third" forKey:@"type"];
                [tmpPatchDict setObject:[customPatch objectForKey:@"bundleID"] forKey:@"bundleID"];
                [tmpPatchDict setObject:[approvedPatch objectForKey:@"patch_install_weight"] forKey:@"patch_install_weight"];

				[approvedUpdatesArray addObject:tmpPatchDict];
                qldebug(@"Custom Patch Dictionary Added: %@",tmpPatchDict);
				break;
			}
		}
	}

    // Sort Array
    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"patch_install_weight" ascending:YES];
    [approvedUpdatesArray sortUsingDescriptors:[NSArray arrayWithObject:desc]];
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

        [statusText setStringValue:@"Scanning for Apple Updates..."];
        [statusText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
        error = nil;
        resultApple = [self scanForAppleUpdates:&error];
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }
        NSLog(@"%@",resultApple);

        [statusText setStringValue:@"Scanning for Custom Updates..."];
        [statusText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
        error = nil;
        resultCustom = [self scanForCustomUpdates:&error];
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }
        NSLog(@"%@",resultCustom);

        [statusText setStringValue:@"Compiling approved patches from scan list."];
        [statusText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

        approvedPatches = [self filterFoundPatches:[self patchGroupPatches]
                                      applePatches:resultApple
                                    customePatches:resultCustom];

        progressCountTotal = (int)[approvedPatches count];
        [progressCountText setStringValue:[NSString stringWithFormat:@"Updates to install: %d",progressCountTotal]];
        [progressCountText display];
        
		//Set Progress Bar Max Value
        [progressBarProgress setHidden:NO];
        [progressBarProgress setIndeterminate:NO];
        [progressBarProgress setDoubleValue:0.0];
		[progressBarProgress setMaxValue:progressCountTotal];

        [statusText setStringValue:@"Patch scanning completed."];
        [statusText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

		if (approvedPatches && [approvedPatches count] > 0)
        {
			[patchesArrayController removeObjects:[patchesArrayController arrangedObjects]];
			[patchesArrayController addObjects:approvedPatches];
            qlinfo(@"approvedPatches:\n%@)",approvedPatches);
			[patchesTableView reloadData];
			[patchesTableView deselectAll:self];
            [patchesTableView performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
		} else {
            [self toggleStatusProgress];
            [self countDownToClose];
        }

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

        [NSThread sleepForTimeInterval:1.5];
        [statusText setStringValue:@"Installing patches..."];
        [statusText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

        for (i = 0; i < [approvedPatches count]; i++)
        {
            // Create/Get Dictionary of Patch to install
            patch = nil;
            patch = [NSDictionary dictionaryWithDictionary:[approvedPatches objectAtIndex:i]];

            qlinfo(@"Preparing to install %@(%@)",[patch objectForKey:@"patch"],[patch objectForKey:@"version"]);
            qldebug(@"Patch to process: %@",patch);

            [progressCountText setStringValue:[NSString stringWithFormat:@"%d of %d Patches",(i+1),(int)[approvedPatches count]]];
            [progressCountText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

            // Now proceed to the download and install
            installResult = -1;

            if ([[patch objectForKey:@"type"] isEqualTo:@"Third"])
            {
                NSString *infoText = [NSString stringWithFormat:@"Starting install for %@",[patch objectForKey:@"patch"]];
                [progressText setStringValue:infoText];
                [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                // Get all of the patches, main and subs
                // This is messed up, not sure why I have an array right within an array, needs to be fixed ...later :-)
                patchPatchesArray = [NSArray arrayWithArray:[[patch objectForKey:@"patches"] objectForKey:@"patches"]];
                qldebug(@"Current patch has total patches associated with it %d", (int)([patchPatchesArray count]-1));

                NSString *dlPatchLoc; //Download location Path
                int patchIndex = 0;
                for (patchIndex=0;patchIndex < [patchPatchesArray count];patchIndex++)
                {
                    // Make sure we only process the dictionaries in the NSArray
                    if ([[patchPatchesArray objectAtIndex:patchIndex] isKindOfClass:[NSDictionary class]])
                    {
                        currPatchToInstallDict = [NSDictionary dictionaryWithDictionary:[patchPatchesArray objectAtIndex:patchIndex]];
                    } else {
                        qlinfo(@"Object found was not of dictionary type; could be a problem. %@",[patchPatchesArray objectAtIndex:patchIndex]);
                        continue;
                    }

                    // Update table view to show whats installing
                    [self updateTableAndArrayController:i status:0];

                    // We have a currPatchToInstallDict to work with
                    qlinfo(@"Start install for patch %@ from %@",[currPatchToInstallDict objectForKey:@"url"],[patch objectForKey:@"patch"]);

                    // First we need to download the update
                    @try
                    {
                        qlinfo(@"Start download for patch from %@",[currPatchToInstallDict objectForKey:@"url"]);
                        [progressText setStringValue:[NSString stringWithFormat:@"Downloading %@",[[currPatchToInstallDict objectForKey:@"url"] lastPathComponent]]];
                        [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                        //Pre Proxy Config
                        downloadURL = [NSString stringWithFormat:@"http://%@/mp-content%@",mpServerConnection.HTTP_HOST,[currPatchToInstallDict objectForKey:@"url"]];
                        qlinfo(@"Download patch from: %@",downloadURL);
                        err = nil;
                        dlPatchLoc = [mpAsus downloadUpdate:downloadURL error:&err];
                        if (err) {
                            qlerror(@"Error downloading a patch, skipping %@. Err Message: %@",[patch objectForKey:@"patch"],[err localizedDescription]);
                            [progressText setStringValue:[NSString stringWithFormat:@"Error downloading a patch, skipping %@.",[patch objectForKey:@"patch"]]];
                            [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                            [self updateTableAndArrayController:i status:2];
                            break;
                        }
                        [progressText setStringValue:[NSString stringWithFormat:@"Patch download completed."]];
                        [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                        [NSThread sleepForTimeInterval:1.0];
                        qlinfo(@"File downloaded to %@",dlPatchLoc);
                    }
                    @catch (NSException *e)
                    {
                        qlerror(@"%@", e);
                        [self updateTableAndArrayController:i status:2];
                        break;
                    }

                    // *****************************
                    // Validate hash, before install
                    [progressText setStringValue:[NSString stringWithFormat:@"Validating downloaded patch."]];
                    [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                    MPCrypto *mpCrypto = [[MPCrypto alloc] init];
                    NSString *fileHash = [mpCrypto md5HashForFile:dlPatchLoc];

                    qlinfo(@"Downloaded file hash: %@ (%@)",fileHash,[currPatchToInstallDict objectForKey:@"hash"]);
                    if ([[[currPatchToInstallDict objectForKey:@"hash"] uppercaseString] isEqualTo:[fileHash uppercaseString]] == NO)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"The downloaded file did not pass the file hash validation. No install will occur."]];
                        [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                        qlerror(@"The downloaded file did not pass the file hash validation. No install will occur.");
                        [self updateTableAndArrayController:i status:2];
                        continue;
                    }

                    // *****************************
                    // Now we need to unzip
                    [progressText setStringValue:[NSString stringWithFormat:@"Uncompressing patch, to begin install."]];
                    [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                    qlinfo(@"Begin decompression of file, %@",dlPatchLoc);
                    err = nil;
                    [mpAsus unzip:dlPatchLoc error:&err];
                    if (err)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"Error decompressing a patch, skipping %@.",[patch objectForKey:@"patch"]]];
                        [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                        qlerror(@"Error decompressing a patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
                        [self updateTableAndArrayController:i status:2];
                        break;
                    }
                    [progressText setStringValue:[NSString stringWithFormat:@"Patch has been uncompressed."]];
                    [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                    qlinfo(@"File has been decompressed.");

                    // *****************************
                    // Run PreInstall Script
                    if ([[currPatchToInstallDict objectForKey:@"preinst"] length] > 0 && [[currPatchToInstallDict objectForKey:@"preinst"] isEqualTo:@"NA"] == NO)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"Begin pre install script."]];
                        [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                        NSString *preInstScript = [[currPatchToInstallDict objectForKey:@"preinst"] decodeBase64WithNewLinesReturnString:NO];
                        qldebug(@"preInstScript=%@",preInstScript);
                        if ([self runScriptViaProxy:preInstScript] != 0 )
                        {
                            qlerror(@"Error (%d) running pre-install script.",(int)installResult);
                            [self updateTableAndArrayController:i status:2];
                            [patchesTableView reloadData];
                            break;
                        }
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
                            [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                            qlinfo(@"Start install of %@",pkgPath);
                            installResult = [self installPKGViaProxy:pkgPath target:@"/" env:[currPatchToInstallDict objectForKey:@"env"]];
                            if (installResult != 0) {
                                [progressText setStringValue:[NSString stringWithFormat:@"Error installing patch."]];
                                [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                                qlerror(@"Error installing package, error code %d.",installResult);
                                [self updateTableAndArrayController:i status:2];
                                hadErr = YES;
                                break;
                            } else {
                                [progressText setStringValue:[NSString stringWithFormat:@"Install was successful."]];
                                [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                                qlinfo(@"%@ was installed successfully.",pkgPath);
                            }
                        } // End Loop
                    }
                    @catch (NSException *e)
                    {
                        [progressText setStringValue:[NSString stringWithFormat:@"Error installing patch."]];
                        [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                        qlerror(@"%@", e);
                        qlerror(@"Error attempting to install patch, skipping %@. Err Message:%@",[patch objectForKey:@"patch"],[err localizedDescription]);
                        [self updateTableAndArrayController:i status:2];
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
                        [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                        NSString *postInstScript = [[currPatchToInstallDict objectForKey:@"postinst"] decodeBase64WithNewLinesReturnString:NO];
                        qldebug(@"postInstScript=%@",postInstScript);
                        if ([self runScriptViaProxy:postInstScript] != 0 )
                        {
                            break;
                        }
                    }

                    // *****************************
                    // Instal is complete, post result to web service
                    @try
                    {
                        [self postInstallToWebService:[patch objectForKey:@"patch_id"] type:@"third"];
                    }
                    @catch (NSException *e) {
                        qlerror(@"%@", e);
                    }
                    [progressText setStringValue:[NSString stringWithFormat:@"Patch install completed."]];
                    [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                    [self updateTableAndArrayController:i status:1];
                } // End patchArray To install
            }
            else if ([[patch objectForKey:@"type"] isEqualTo:@"Apple"])
            {
                // Process Apple Type Patches
                infoText = [NSString stringWithFormat:@"Starting install for %@",[patch objectForKey:@"patch"]];
                [progressText setStringValue:infoText];
                [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

                // Update the table view to show we are in the install process
                [self updateTableAndArrayController:i status:0];

                if ([[patch objectForKey:@"hasCriteria"] boolValue] == NO || ![patch objectForKey:@"hasCriteria"])
                {
                    qlinfo(@"%@ has no criteria, begining install.",[patch objectForKey:@"patch"]);
                    installResult = [self installAppleSoftwareUpdateViaProxy:[patch objectForKey:@"patch"]];
                }
                else
                {
                    qlinfo(@"%@ has install criteria assigned to it.",[patch objectForKey:@"patch"]);

                    NSDictionary *criteriaDictPre, *criteriaDictPost;
                    NSData *scriptData;
                    NSString *scriptText;

                    int i = 0;
                    int s_res;
                    // PreInstall First
                    if ([patch objectForKey:@"criteria_pre"])
                    {
                        qlinfo(@"Processing pre-install criteria.");
                        for (i=0;i<[[patch objectForKey:@"criteria_pre"] count];i++)
                        {
                            criteriaDictPre = [[patch objectForKey:@"criteria_pre"] objectAtIndex:i];

                            scriptData = [[criteriaDictPre objectForKey:@"data"] decodeBase64WithNewlines:NO];
                            scriptText = [[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding];

                            [progressText setStringValue:[NSString stringWithFormat:@"Run pre-install criteria."]];
                            [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                            s_res = [self runScriptViaProxy:scriptText];
                            if (s_res != 0) {
                                installResult = 1;
                                qlerror(@"Pre-install script returned false for %@. No install will occur.",[patch objectForKey:@"patch"]);
                                goto instResult;
                            } else {
                                qlinfo(@"Pre-install script returned true.");
                            }
                            criteriaDictPre = nil;
                        }
                    }
                    // Run the patch install, now that the install has occured.
                    installResult = [self installAppleSoftwareUpdateViaProxy:[patch objectForKey:@"patch"]];

                    // If Install retuened anything but 0, the dont run post criteria
                    if (installResult != 0)
                    {
                        qlerror(@"The install for %@ returned an error.",[patch objectForKey:@"patch"]);
                        goto instResult;
                    }

                    if ([patch objectForKey:@"criteria_post"])
                    {
                        qlinfo(@"Processing post-install criteria.");
                        for (i=0;i<[[patch objectForKey:@"criteria_post"] count];i++)
                        {
                            criteriaDictPost = [[patch objectForKey:@"criteria_post"] objectAtIndex:i];

                            scriptData = [[criteriaDictPost objectForKey:@"data"] decodeBase64WithNewlines:NO];
                            scriptText = [[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding];
                            [progressText setStringValue:[NSString stringWithFormat:@"Run post-install criteria."]];
                            [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                            s_res = [self runScriptViaProxy:scriptText];
                            if (s_res != 0) {
                                installResult = 1;
                                qlerror(@"Pre-install script returned false for %@. No install will occur.",[patch objectForKey:@"patch"]);
                                goto instResult;
                            } else {
                                qlinfo(@"Post-install script returned true.");
                            }
                            criteriaDictPost = nil;
                        }
                    }
                }

            instResult:
                if (installResult != 0)
                {
                    [progressText setStringValue:[NSString stringWithFormat:@"Error installing update, error code %d.",installResult]];
                    [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                    qlerror(@"Error installing update, error code %d.",installResult);
                    [self updateTableAndArrayController:i status:2];
                    continue;
                }
                else
                {
                    [progressText setStringValue:[NSString stringWithFormat:@"%@ was installed successfully.",[patch objectForKey:@"patch"]]];
                    [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                    qlinfo(@"%@ was installed successfully.",[patch objectForKey:@"patch"]);

                    // Post the results to web service
                    @try {
                        [self postInstallToWebService:[patch objectForKey:@"patch"] type:@"apple"];
                    }
                    @catch (NSException *e) {
                        qlerror(@"%@", e);
                    }

                    [progressText setStringValue:[NSString stringWithFormat:@"Patch install completed."]];
                    [progressText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
                    [self updateTableAndArrayController:i status:1];
                }
            }
            else
            {
                // Not Apple or Custom Patch
                continue;
            }

            [progressBarProgress setDoubleValue:(i+1)];
            [progressBarProgress performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
        }

        [patchesTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        [patchesTableView performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
        [self toggleStatusProgress];
        [self countDownToClose];
    }
}

- (void)updateTableAndArrayController:(int)idx status:(int)aStatusImage
{
    NSMutableArray      *patches = [NSMutableArray arrayWithArray:[patchesArrayController arrangedObjects]];
	NSMutableDictionary *patch = [[NSMutableDictionary alloc] initWithDictionary:[patches objectAtIndex:idx]];
	if (aStatusImage == 0) {
		[patch setObject:[NSImage imageNamed:@"NSRemoveTemplate"] forKey:@"statusImage"];
	}
	if (aStatusImage == 1) {
		[patch setObject:[self tableImage:@"Success.png"] forKey:@"statusImage"];
	}
	if (aStatusImage == 2) {
		[patch setObject:[self tableImage:@"Fail.png"] forKey:@"statusImage"];
	}
	if (aStatusImage == 3) {
		[patch setObject:[self tableImage:@"Logout.png"] forKey:@"statusImage"];
	}
	[patches replaceObjectAtIndex:idx withObject:patch];
	[patchesArrayController setContent:patches];
    [patchesTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    [patchesTableView performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];
    [patchesTableView performSelectorOnMainThread:@selector(deselectAll:) withObject:nil waitUntilDone:NO];

}

- (NSImage *)tableImage:(NSString*)fileName
{
    NSImage *_img;
    NSString *imgFile = [@"/System/Library/CoreServices/SecurityAgentPlugins/MPAuthPlugin.bundle/Contents/Resources" stringByAppendingPathComponent:fileName];
    NSLog(@"Image Path: %@",imgFile);
    _img = [[NSImage alloc] initWithContentsOfFile:imgFile];
    return _img;
}

- (void)postInstallToWebService:(NSString *)aPatch type:(NSString *)aType
{
    BOOL result = NO;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    NSError *wsErr = nil;
    result = [mpws postPatchInstallResultsToWebService:aPatch patchType:aType error:&wsErr];
    if (wsErr) {
        qlerror(@"%@",wsErr.localizedDescription);
    } else {
        if (result == TRUE) {
            qlinfo(@"Patch (%@) install result was posted to webservice.",aPatch);
        } else {
            qlerror(@"Patch (%@) install result was not posted to webservice.",aPatch);
        }
    }

    return;
}

- (IBAction)cancelScanAndPatch:(id)sender
{
    statusText.stringValue = @"Canceling current task...";
    [statusText performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO];

    [taskThread cancel];
    taskThread = nil;
    [self cleanup];

    int i = 0;
    while ( i < 60 ) {
        i++;
        if ([taskThread isCancelled]) {
            break;
        }
    }

    [self countDownToClose];
}

@end
