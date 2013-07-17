//
//  MPCatalogAppDelegate.m
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

#import "MPCatalogAppDelegate.h"
#import "PreferenceController.h"
#import "MacPatch.h"
#import "MPWorkerProtocol.h"
#import "MPDLWrapper.h"
#import "EventToSend.h" 
#import "SWDistInfoController.h"

#define MP_INSTALLED_DATA       @".installed.plist"

@interface MPInstallIconValueTransformer: NSValueTransformer
{
    NSImage *installedImage;
    NSImage *insallingImage;
    NSImage *errorImage;
    NSImage *emptyImage;
    NSImage *downloadImage;
}
@end

@implementation MPInstallIconValueTransformer

- (id)init
{
    if (self = [super init]) 
    {
        installedImage = [[NSImage imageNamed:@"Installcomplete"] retain];
        insallingImage = [[NSImage imageNamed:@"running"] retain];
        errorImage = [[NSImage imageNamed:@"exclamation"] retain];
        emptyImage = [[NSImage imageNamed:@"empty"] retain];
        downloadImage = [[NSImage imageNamed:@"blue_down_16"] retain];
        
    }
    return self;
}

- (void)dealloc 
{
    [installedImage release], installedImage = nil;
    [insallingImage release], insallingImage = nil;
    [errorImage release], errorImage = nil;
    [emptyImage release], emptyImage = nil;
    [downloadImage release], downloadImage = nil;
    [super dealloc];
}

+ (Class)transformedValueClass { return [NSImage class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value 
{
    if ([value intValue] == 0) {
        return emptyImage;
    } else if ([value intValue] == 1) {
        return installedImage;
    } else if ([value intValue] == 2) {
        return insallingImage;
    } else if ([value intValue] == 3) {
        return errorImage;
    } else if ([value intValue] == 4) {
        return downloadImage;    
    } else {
        return emptyImage;
    }
    //return ([value boolValue] ? installedImage : emptyImage);
}
@end

@interface MPBOOLIconValueTransformer: NSValueTransformer
{
    NSImage *installedImage;
    NSImage *emptyImage;
}
@end

@implementation MPBOOLIconValueTransformer

- (id)init
{
    if (self = [super init]) 
    {
        installedImage = [[NSImage imageNamed:@"Installcomplete"] retain];
        emptyImage = [[NSImage imageNamed:@"empty"] retain];
        
    }
    return self;
}

- (void)dealloc 
{
    [installedImage release], installedImage = nil;
    [emptyImage release], emptyImage = nil;
    [super dealloc];
}

+ (Class)transformedValueClass { return [NSImage class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value 
{
    return ([value boolValue] ? installedImage : emptyImage);
}
@end

#pragma mark -

@interface MPBOOLRebootIconValueTransformer: NSValueTransformer
{
    NSImage *rebootImage;
    NSImage *emptyImage;
}
@end

@implementation MPBOOLRebootIconValueTransformer

- (id)init 
{
    if (self = [super init]) 
    {
        rebootImage = [[NSImage imageNamed:@"RestartReq"] retain];
        emptyImage = [[NSImage imageNamed:@"empty"] retain];
    }
    return self;
}

- (void)dealloc 
{
    [rebootImage release];
    rebootImage = nil;
    [emptyImage release];
    emptyImage = nil;
    [super dealloc];
}

+ (Class)transformedValueClass { return [NSImage class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value 
{
    return ([value boolValue] ? rebootImage : emptyImage);
}
@end

#pragma mark -

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

#pragma mark -

// Private Methods
@interface MPCatalogAppDelegate ()

// Reboot
- (IBAction)showRebootPanel:(id)sender;
- (IBAction)closeRebootPanel:(id)sender;
- (IBAction)closeRebootPanelAndReboot:(id)sender;
- (void)rebootPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;

// SW Dist Info
- (IBAction)showSWDistInfo:(id)sender;
- (void)populateSoftwareGroupsPopupButton;

// Install Mandatory Software
- (void)checkAndInstallMandatoryApplications;
- (void)checkAndInstallMandatoryApplicationsThread;
// Helpers
- (NSArray *)filterMandatorySoftwareContent;
- (BOOL)softwareItemInstalled:(NSDictionary *)dict;
- (BOOL)softwareTaskInstalled:(NSString *)aTaskID;

// Install
- (IBAction)installSoftware:(id)sender;
- (void)installSoftwareThread;
- (BOOL)installSoftwareItem:(NSDictionary *)dict;

// Remove
- (IBAction)removeSoftware:(id)sender;
- (void)removeSoftwareThread;

// Actions
- (IBAction)showMainLog:(id)sender;
- (IBAction)showHelperLog:(id)sender;

// Class Methods
- (void)updateArrayControllerWithDictionary:(NSDictionary *)dict;
- (void)updateArrayControllerWithDictionary:(NSDictionary *)dict forActionType:(NSString *)type;
- (void)removeSoftwareInstallStatus:(NSString *)swID;
- (void)downloadSoftwareContent;
- (void)filterSoftwareContent:(NSArray *)content;

- (void)setLoggingState:(BOOL)aState;

// Web Services
- (void)postInstallResults:(int)resultNo resultText:(NSString *)resultString task:(NSDictionary *)taskDict;
- (void)postUnInstallResults:(int)resultNo resultText:(NSString *)resultString task:(NSDictionary *)taskDict;

// Helper
- (void)connect;
- (void)cleanup;
- (void)connectionDown:(NSNotification *)notification;

- (int)installSoftwareViaProxy:(NSDictionary *)aInstallDict;
- (int)patchSoftwareViaProxy:(NSDictionary *)aInstallDict;
- (int)removeSoftwareViaProxy:(NSString *)removeScript;
- (int)writeToFileViaProxy:(NSString *)aFile data:(id)data;
- (int)writeArrayFileViaProxy:(NSString *)aFile data:(NSArray *)data;

- (BOOL)hasCanceledInstall:(NSDictionary *)task;

@end

#pragma mark -

// Public

@implementation MPCatalogAppDelegate

@synthesize _defaults;

@synthesize window;
@synthesize tableView;
@synthesize arrayController;
@synthesize statusTextTitle;
@synthesize statusTextStatus;
@synthesize progressBar;
@synthesize installButton;
@synthesize removeButton;
@synthesize cancelButton;
@synthesize refreshButton;
@synthesize infoButton;
@synthesize swDistGroupsButton;
@synthesize selectedItems;
@synthesize swDistGroupsArray;

@synthesize rebootPanel;

@synthesize queue;
@synthesize cancelInstalls;
@synthesize _selectionColumn;
@synthesize tableColEdit;
@synthesize mp_SOFTWARE_DATA_DIR;
@synthesize swDistInfoPanelDict;
@synthesize swDistInfoPanel;
@synthesize swDistCurrentTitle;

#pragma mark -

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Center the Window
	[window center];
}

- (void)awakeFromNib
{
    fm = [NSFileManager defaultManager];
    queue = [[NSOperationQueue alloc] init];
    selectedItems = [[NSMutableArray alloc] init];
    
    // Default Server Connection Object
    mpServerConnection = [[MPServerConnection alloc] init];
    
    // User Defaults 
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
    
    // Setup logging
	NSString *_logFile = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/MPCatalog.log"];
	[MPLog setupLogging:_logFile level:lcl_vDebug];
    
	if ([d boolForKey:@"enableDebugLogging"]) {
		// enable logging for all components up to level Debug
		lcl_configure_by_name("*", lcl_vDebug);
		logit(lcl_vInfo,@"***** MP SW Catalog started -- Debug Enabled *****");
	} else {
		// enable logging for all components up to level Info
		lcl_configure_by_name("*", lcl_vDebug);
		logit(lcl_vInfo,@"***** MP SW Catalog started *****");
	}
    
    // Set Data Directory
    NSURL *appSupportDir = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSSystemDomainMask] objectAtIndex:0];
    NSURL *appSupportMPDir = [appSupportDir URLByAppendingPathComponent:@"MacPatch"];
    [self setMp_SOFTWARE_DATA_DIR:[appSupportMPDir URLByAppendingPathComponent:@"SW_Data"]];
    if ([fm fileExistsAtPath:[mp_SOFTWARE_DATA_DIR path]] == NO) {
        NSError *err = nil;
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
        [fm createDirectoryAtPath:[mp_SOFTWARE_DATA_DIR path] withIntermediateDirectories:YES attributes:attributes error:&err];
        if (err) {
            logit(lcl_vError,@"%@",[err description]);
        }
    }
    if ([fm fileExistsAtPath:[[mp_SOFTWARE_DATA_DIR URLByAppendingPathComponent:@"sw"] path]] == NO) {
        NSError *err = nil;
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
        [fm createDirectoryAtPath:[[mp_SOFTWARE_DATA_DIR URLByAppendingPathComponent:@"sw"] path] withIntermediateDirectories:YES attributes:attributes error:&err];
        if (err) {
            logit(lcl_vError,@"%@",[err description]);
        }
        [[mp_SOFTWARE_DATA_DIR URLByAppendingPathComponent:@"sw"] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsHiddenKey error:NULL];
    }
    
    // Get Agent Default Settings
    [self set_defaults:mpServerConnection.mpDefaults];
    
    window.title = [NSString stringWithFormat:@"MP - Software Catalog (%@)",[self._defaults objectForKey:@"SWDistGroup"]];
    
    [progressBar setUsesThreadedAnimation:YES];
    [self performSelectorInBackground:@selector(downloadSoftwareContent) withObject:nil];
    
    [installButton setEnabled:NO];
    [removeButton  setEnabled:NO];
    [cancelButton  setEnabled:NO];
    [infoButton    setEnabled:NO];
	
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(installOutputFromProxy:) name:@"installSoftwareNote" object:nil];
	
	// If scan on launch is true
	if ([d boolForKey:@"enableScanOnLaunch"]) {
		//killTaskThread = NO;
		//[self scanForPatches:nil];
	}	
    
    [self setTableColEdit:YES];
    
    // Connect to Helper
    logit(lcl_vInfo,@"Start");
    if ([d boolForKey:@"enableDebugLogging"])
        [self setLoggingState:[d boolForKey:@"enableDebugLogging"]];
    
    [self performSelectorInBackground:@selector(populateSoftwareGroupsPopupButton) withObject:nil];    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	//[self setLoggingState:NO];
    return YES;
}

-(IBAction)windowCloseWillExit:(id)sender
{
    //[self setLoggingState:NO];
	[NSApp terminate:nil];
}

- (void)dealloc
{
    [selectedItems autorelease];
    [queue autorelease];
    [tableView autorelease];
    [arrayController autorelease];
    [statusTextTitle autorelease];
    [statusTextStatus autorelease];
    [progressBar autorelease];
    [installButton autorelease];
    [removeButton autorelease];
    [cancelButton autorelease];
    [refreshButton autorelease];
	
    [self cleanup];
    [super dealloc];
}

- (IBAction)showRebootPanel:(id)sender
{
    [NSApp beginSheet: rebootPanel
       modalForWindow: window
        modalDelegate: self
       didEndSelector: @selector(rebootPanelDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (IBAction)closeRebootPanel:(id)sender
{
    [NSApp endSheet:rebootPanel returnCode:0];
} 

- (IBAction)closeRebootPanelAndReboot:(id)sender
{
    [NSApp endSheet:rebootPanel returnCode:1];
} 

- (void)rebootPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [sheet orderOut:self];
    // Reboot
    if (returnCode == 1) {
        OSStatus error = noErr;
        error = SendAppleEventToSystemProcess(kAEShowRestartDialog);
        if (error == noErr) {
            [NSApp terminate:self];
        }
    }
}

- (IBAction)showPreferencePanel:(id)sender
{
    // Is preferenceController nil?
    if (!preferenceController) {
		preferenceController = [[PreferenceController alloc] init];
    }
    [preferenceController showWindow:self];
}

- (IBAction)showSWDistInfo:(id)sender
{
    if (!swDistInfoController) {
        swDistInfoController = [[SWDistInfoController alloc] init];
    }
    
    [swDistInfoController setSwDistInfoPanelDict:[selectedItems objectAtIndex:0]];
    [swDistInfoController showWindow:self];
}

- (void)populateSoftwareGroupsPopupButton
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [swDistGroupsButton removeAllItems];
    
    NSError *error = nil;
    NSString *result;
    MPASINet *asiNet = [[[MPASINet alloc] init] autorelease];
    result = [asiNet synchronousRequestForURL:@"/Services/MPWSControllerCocoa.cfc?method=GetSWDistGroups" error:&error];
    if (error) {
        qlerror(@"%@",[error description]);
        [swDistGroupsButton addItemWithTitle:[_defaults objectForKey:@"SWDistGroup"]];
    } else {
        NSDictionary *j = [result objectFromJSONString];
        
        if ([[j objectForKey:@"errorno"] isEqualToString:@"0"]) {
            NSArray *i = [[j objectForKey:@"result"] objectFromJSONString];
            [self setSwDistGroupsArray:i];
            for (NSDictionary *n in i) {
                [swDistGroupsButton addItemWithTitle:[n objectForKey:@"Name"]];
            }
            
            if ([[swDistGroupsButton itemTitles] containsObject:[_defaults objectForKey:@"SWDistGroup"]]) {
                [swDistGroupsButton selectItemAtIndex:[[swDistGroupsButton itemTitles] indexOfObject:[_defaults objectForKey:@"SWDistGroup"]]];
            }
            
        } else {
            [swDistGroupsButton addItemWithTitle:[_defaults objectForKey:@"SWDistGroup"]];
        }
    }
    
    [swDistGroupsButton display];
    [pool drain];
}

- (IBAction)popUpChanged:(id)sender
{
    if ([[sender title] isEqualToString:swDistCurrentTitle] == NO) {
        [self refreshSoftware:nil];
    }
}

#pragma mark - Install Mandatory Software

- (void)checkAndInstallMandatoryApplications
{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"enableInstallOnLaunch"] == nil) 
    {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"enableInstallOnLaunch"];
    }
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"enableInstallOnLaunch"] == 1) {
        logit(lcl_vInfo,@"Check and install any mandatory applications.");
        [self checkAndInstallMandatoryApplicationsThread];
    }
}

- (void)checkAndInstallMandatoryApplicationsThread
{
    NSArray *mandatoryInstllTasks;
    mandatoryInstllTasks = [self filterMandatorySoftwareContent];
    
    // Check to see if there is anything to install
    if (mandatoryInstllTasks == nil || [mandatoryInstllTasks count] <= 0) {
        return;
    }
    
    MPDiskUtil *mpd = [[MPDiskUtil alloc] init];
    
    // Install the mandatory software 
    int _needsReboot = 0;
    for (NSDictionary *d in mandatoryInstllTasks) 
    {
        [statusTextStatus setStringValue:[NSString stringWithFormat:@"Installing %@ ...",[d objectForKey:@"name"]]];
        logit(lcl_vInfo,@"Installing %@ (%@).",[d objectForKey:@"name"],[d objectForKey:@"id"]);
        logit(lcl_vInfo,@"INFO: %@",[d valueForKeyPath:@"Software.sw_type"]);
        
        // Create Path to download software to
        NSString *swLoc = NULL;
        NSString *swLocBase = [[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:@"sw"];
        swLoc = [NSString pathWithComponents:[NSArray arrayWithObjects:swLocBase, [d objectForKey:@"id"], nil]];
        
        // Verify Disk space requirements before downloading and installing
        NSScanner* scanner = [NSScanner scannerWithString:[d valueForKeyPath:@"Software.sw_size"]];
        long long stringToLong;
        if(![scanner scanLongLong:&stringToLong]) {
            logit(lcl_vError,@"Unable to convert size %@",[d valueForKeyPath:@"Software.sw_size"]);
            [self postInstallResults:99 resultText:@"Unable to calculate size." task:d];
            [self updateArrayControllerWithDictionary:d forActionType:@"error"];
            continue;
        }
        
        if ([mpd diskHasEnoughSpaceForPackage:stringToLong] == NO) 
        {
            logit(lcl_vError,@"This system does not have enough free disk space to install the following software %@",[d objectForKey:@"name"]);
            [self postInstallResults:99 resultText:@"Not enough free disk space." task:d];
            [self updateArrayControllerWithDictionary:d forActionType:@"error"];
            continue;
        }
        
        // Create Download URL
        [mpServerConnection refreshServerObject];
        NSString *_url = [NSString stringWithFormat:@"%@://%@:%@/mp-content%@",mpServerConnection.HTTP_PREFIX,mpServerConnection.HTTP_HOST,mpServerConnection.HTTP_HOST_PORT,[d valueForKeyPath:@"Software.sw_url"]];
        logit(lcl_vInfo,@"Download software from: %@",_url);
        
        BOOL isDir;
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
        if ([fm fileExistsAtPath:swLoc isDirectory:&isDir] == NO) {
            [fm createDirectoryAtPath:swLoc withIntermediateDirectories:YES attributes:attributes error:NULL];
        } else {
            if (isDir == NO) {
                // Item is not a directory so we need to remove it and create our dir structure
                [fm removeItemAtPath:swLoc error:NULL];
                [fm createDirectoryAtPath:swLoc withIntermediateDirectories:YES attributes:attributes error:NULL];
            }
        }
        
        [progressBar setDoubleValue:0.0];
        [progressBar setIndeterminate:NO];
        
        downloadTask = [[MPDLWrapper alloc] initWithController:self url:[NSURL URLWithString:[_url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        [self updateArrayControllerWithDictionary:d forActionType:@"download"];
        [downloadTask startDownloadAndSpecifyDownloadDirectory:swLoc];
        
        logit(lcl_vDebug,@"returnCode: %d",[downloadTask returnCode]);
        // Software was downloaded
        if ([downloadTask returnCode] == 0) 
        {
            logit(lcl_vDebug,@"Begin install for (%@).",[d objectForKey:@"name"]);
            int result = -1;
            int pResult = -1;
            [progressBar setIndeterminate:YES];
            [progressBar startAnimation:nil];
            [progressBar display];
            
            if ([self hasCanceledInstall:d]) break;
            [self updateArrayControllerWithDictionary:d forActionType:@"install"];
            result = [self installSoftwareViaProxy:d];
            
            if (result == 0) 
            {
                // Software has been installed, now flag for reboot
                if ([[d valueForKeyPath:@"Software.reboot"] isEqualTo:@"1"]) {
                    _needsReboot++;
                }
                if ([[d valueForKeyPath:@"Software.auto_patch"] isEqualTo:@"1"]) {
                    [statusTextStatus setStringValue:@"Auto Patching is enabled, begin patching..."];
                    [statusTextStatus display];
                    pResult = [self patchSoftwareViaProxy:d];
                    [NSThread sleepForTimeInterval:5];
                }
                
                [statusTextStatus setStringValue:[NSString stringWithFormat:@"Installing %@ completed.",[d objectForKey:@"name"]]];
                [statusTextStatus display];
                
                [self installSoftwareItem:d];
                [self updateArrayControllerWithDictionary:d];
            } else {
                [self updateArrayControllerWithDictionary:d forActionType:@"error"];
            }
            
            [self postInstallResults:result resultText:@"" task:d];
            [progressBar stopAnimation:nil];
            [progressBar display];
        }
        [downloadTask release];
        
    }
    
    [refreshButton setEnabled:YES];
    [cancelButton setEnabled:NO];
    [self setTableColEdit:YES];
    
    // Apps were installed that require a reboot
    if (_needsReboot >= 1) {
        [self showRebootPanel:nil];
    }
    
    [mpd release];
}

#pragma mark Helpers Methods

- (NSArray *)filterMandatorySoftwareContent
{
    NSArray *_a;
    int c = 0;
    NSMutableDictionary *d;
    NSDictionary *_SoftwareCriteria;
    NSMutableArray *_MandatorySoftware = [[NSMutableArray alloc] init];
    
    /* If there is content */
    if ([fm fileExistsAtPath:[[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:@"content.plist"]] == NO) {
        return nil;
    }
    
    _a = [NSKeyedUnarchiver unarchiveObjectWithFile:[[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:@"content.plist"]];
    for (id item in _a) 
    {
        d = [[NSMutableDictionary alloc] initWithDictionary:item];
        logit(lcl_vInfo,@"Checking %@",[d objectForKey:@"name"]);
        
        // Check for Mandatory apps
        if ([[d objectForKey:@"sw_task_type"] containsString:@"m" ignoringCase:YES] == NO) {
            logit(lcl_vInfo,@"%@ is not a mandatory application.",[d objectForKey:@"name"]);
            [d release];
            continue;
        }
        
        // Check Install Date Info
        NSDate *now = [NSDate date];
        NSDate *startDate = [NSDate dateFromString:[d objectForKey:@"sw_start_datetime"]];
        NSDate *endDate = [NSDate dateFromString:[d objectForKey:@"sw_end_datetime"]];
        
        if ([now timeIntervalSince1970] < [startDate timeIntervalSince1970]) {
            // Software is not ready for deployment
            [d release];
            continue;
        }
        
        // If it's a Optional / Mandatory App then we wait for the end date
        if ([[d objectForKey:@"sw_task_type"] containsString:@"o" ignoringCase:YES]) 
        {
            if ([now timeIntervalSince1970] >= [endDate timeIntervalSince1970]) 
            {
                logit(lcl_vInfo,@"Optional/Mandatory date has been reached for install.");
            } else {
                [d release];
                continue;
            }
        }
        
        // Check Simple Requirements
        c = 0;
        MPOSCheck *mpos = [[MPOSCheck alloc] init];
        _SoftwareCriteria = [item objectForKey:@"SoftwareCriteria"];
        // OSArch
        if ([mpos checkOSArch:[_SoftwareCriteria objectForKey:@"arch_type"]]) {
            logit(lcl_vInfo,@"OSArch=TRUE: %@",[_SoftwareCriteria objectForKey:@"arch_type"]);
        } else {
            logit(lcl_vInfo,@"OSArch=FALSE: %@",[_SoftwareCriteria objectForKey:@"arch_type"]);
            c++;
        }
        // OSType
        if ([mpos checkOSType:[_SoftwareCriteria objectForKey:@"os_type"]]) {
            logit(lcl_vInfo,@"OSType=TRUE: %@",[_SoftwareCriteria objectForKey:@"os_type"]);
        } else {
            logit(lcl_vInfo,@"OSType=FALSE: %@",[_SoftwareCriteria objectForKey:@"os_type"]);
            c++;
        }
        // OSVersion
        if ([mpos checkOSVer:[_SoftwareCriteria objectForKey:@"os_vers"]]) {
            logit(lcl_vInfo,@"OSVersion=TRUE: %@",[_SoftwareCriteria objectForKey:@"os_vers"]);
        } else {
            logit(lcl_vInfo,@"OSVersion=FALSE: %@",[_SoftwareCriteria objectForKey:@"os_vers"]);
            c++;
        }
        [mpos release];
        mpos = nil;
        // Did not pass the criteria check
        if (c >= 1) {
            [d release];
            continue;
        }
        
        // Check to see if it's installed
        if ([self softwareTaskInstalled:[d objectForKey:@"id"]] == NO) {
            // Has not been installed, and is mandatory
            logit(lcl_vInfo,@"Adding %@ to mandatory installs.",[d objectForKey:@"name"]);
            [_MandatorySoftware addObject:d];
        } else {
            logit(lcl_vInfo,@"%@ is already installed.",[d objectForKey:@"name"]);
        }
        
        [d release];
        d = nil;
    }
    
    // Echo which apps are going to be installed.
    for (id x in _MandatorySoftware) {
        logit(lcl_vInfo,@"Approved Mandatory Software task: %@",[x objectForKey:@"name"]);
    }
    NSArray *results = [NSArray arrayWithArray:_MandatorySoftware];
    [_MandatorySoftware release];
    return results;
}

- (BOOL)softwareItemInstalled:(NSDictionary *)dict
{
    NSString *installFile = [[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:MP_INSTALLED_DATA];
    NSMutableDictionary *installData = [[NSMutableDictionary alloc] init];
    [installData setObject:[NSDate date] forKey:@"installDate"];
    [installData setObject:[dict objectForKey:@"id"] forKey:@"id"];
    [installData setObject:[dict objectForKey:@"name"] forKey:@"name"];
    if ([dict objectForKey:@"sw_uninstall"]) {
        [installData setObject:[dict objectForKey:@"sw_uninstall"] forKey:@"sw_uninstall"];    
    } else {
        [installData setObject:@"" forKey:@"sw_uninstall"];
    }
    NSMutableArray *_data;
    if ([fm fileExistsAtPath:installFile]) {
        _data = [NSMutableArray arrayWithContentsOfFile:installFile];
    } else {
        if (![fm fileExistsAtPath:[mp_SOFTWARE_DATA_DIR path]]) {
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
            [fm createDirectoryAtPath:[mp_SOFTWARE_DATA_DIR path] withIntermediateDirectories:YES attributes:attributes error:NULL];
        }
        _data = [NSMutableArray array];
    }
    [_data addObject:installData];
    [_data writeToFile:installFile atomically:YES];
    [installData release];
    return YES;
}

- (BOOL)softwareTaskInstalled:(NSString *)aTaskID
{
    NSString *installFile = [[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:MP_INSTALLED_DATA];
    if ([fm fileExistsAtPath:installFile]) {
        NSArray *a = [NSArray arrayWithContentsOfFile:installFile];
        for (int i = 0; i < [a count];i++) {
            if ([[[a objectAtIndex:i] objectForKey:@"id"] isEqualTo:aTaskID]) {
                return YES; // It's installed ... no need to install
            }
        }
    }
    
    return NO;
}

#pragma mark - Install Software

- (IBAction)installSoftware:(id)sender
{
    [cancelButton setEnabled:YES];
	[self performSelectorInBackground:@selector(installSoftwareThread) withObject:nil];
}

- (void)installSoftwareThread
{
    NSAutoreleasePool *iPool = [[NSAutoreleasePool alloc] init];
    [self setTableColEdit:NO];
    [installButton setEnabled:NO];
    [cancelButton setEnabled:YES];
    [refreshButton setEnabled:NO];
    [swDistGroupsButton setEnabled:NO];
    [self setCancelInstalls:NO];
    
    MPDiskUtil      *mpd                = [[MPDiskUtil alloc] init];
    NSMutableArray  *swToInstallArray   = [NSMutableArray arrayWithArray:[arrayController arrangedObjects]];
    
    int _needsReboot = 0;
    for (NSDictionary *d in swToInstallArray) 
    {
        if (cancelInstalls == YES) 
        {
            [self setCancelInstalls:NO];
            break;
        }
        
        if ([d objectForKey:@"selected"]) {
            if ([[d objectForKey:@"selected"] intValue] == 1) {
                
                [statusTextStatus setStringValue:[NSString stringWithFormat:@"Installing %@ ...",[d objectForKey:@"name"]]];
                logit(lcl_vInfo,@"Installing %@ (%@).",[d objectForKey:@"name"],[d objectForKey:@"id"]);
                logit(lcl_vInfo,@"INFO: %@",[d valueForKeyPath:@"Software.sw_type"]);
                
                if ([self hasCanceledInstall:d]) break;
                
                // Create Path to download software to
                NSString *swLoc = NULL;
                NSString *swLocBase = [[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:@"sw"];
                swLoc = [NSString pathWithComponents:[NSArray arrayWithObjects:swLocBase, [d objectForKey:@"id"], nil]];
                
                // Verify Disk space requirements before downloading and installing
                NSScanner* scanner = [NSScanner scannerWithString:[d valueForKeyPath:@"Software.sw_size"]];
                long long stringToLong;
                if(![scanner scanLongLong:&stringToLong]) {
                    logit(lcl_vError,@"Unable to convert size %@",[d valueForKeyPath:@"Software.sw_size"]);
                    [self postInstallResults:99 resultText:@"Unable to calculate size." task:d];
                    [self updateArrayControllerWithDictionary:d forActionType:@"error"];
                    continue;
                }
                
                if ([mpd diskHasEnoughSpaceForPackage:stringToLong] == NO) 
                {
                    logit(lcl_vError,@"This system does not have enough free disk space to install the following software %@",[d objectForKey:@"name"]);
                    [self postInstallResults:99 resultText:@"Not enough free disk space." task:d];
                    [self updateArrayControllerWithDictionary:d forActionType:@"error"];
                    continue;
                }
                
                // Create Download URL
                [mpServerConnection refreshServerObject];
                NSString *_url = [NSString stringWithFormat:@"%@://%@:%@/mp-content%@",mpServerConnection.HTTP_PREFIX,mpServerConnection.HTTP_HOST,mpServerConnection.HTTP_HOST_PORT,[d valueForKeyPath:@"Software.sw_url"]];
                logit(lcl_vDebug,@"Download software from: %@",[d valueForKeyPath:@"Software.sw_type"]);
                
                [progressBar setDoubleValue:0.0];
                [progressBar setIndeterminate:NO];
                
                downloadTask = [[MPDLWrapper alloc] initWithController:self url:[NSURL URLWithString:[_url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                [self updateArrayControllerWithDictionary:d forActionType:@"download"];
                [downloadTask startDownloadAndSpecifyDownloadDirectory:swLoc];
                
                if ([self hasCanceledInstall:d]) break;
                
                logit(lcl_vDebug,@"returnCode: %d",[downloadTask returnCode]);
                // Software was downloaded
                if ([downloadTask returnCode] == 0) 
                {
                    logit(lcl_vDebug,@"Begin install for (%@).",[d objectForKey:@"name"]);
                    int result = -1;
                    int pResult = -1;

                    [progressBar setDoubleValue:0.0];
                    [progressBar setIndeterminate:NO];
                    [progressBar display];
                    
                    if ([self hasCanceledInstall:d]) break;
                    [self updateArrayControllerWithDictionary:d forActionType:@"install"];
                    result = [self installSoftwareViaProxy:d];
                    
                    if (result == 0) 
                    {
                        // Software has been installed, now flag for reboot
                        if ([[d valueForKeyPath:@"Software.reboot"] isEqualTo:@"1"]) {
                            _needsReboot++;
                        }
                        if ([[d valueForKeyPath:@"Software.auto_patch"] isEqualTo:@"1"]) {
                            
                        	[progressBar setIndeterminate:YES];
                            [progressBar startAnimation:nil];
                            [progressBar display];
                            
                            [statusTextStatus setStringValue:@"Auto Patching is enabled, begin patching..."];
                            [statusTextStatus display];
                            
                            pResult = [self patchSoftwareViaProxy:d];
                            [NSThread sleepForTimeInterval:5];
                        }
                        
                        [statusTextStatus setStringValue:[NSString stringWithFormat:@"Installing %@ completed.",[d objectForKey:@"name"]]];
                        [statusTextStatus display];
                        
                        [self installSoftwareItem:d];
                        [self updateArrayControllerWithDictionary:d];
                    } else {
                        [self updateArrayControllerWithDictionary:d forActionType:@"error"];
                    }
                    
                    [self postInstallResults:result resultText:@"" task:d];
                    [progressBar stopAnimation:nil];
                    [progressBar display];
                }
                [downloadTask release];
            }
        }
    }  
    [installButton setEnabled:YES];
    [refreshButton setEnabled:YES];
    [cancelButton setEnabled:NO];
    [swDistGroupsButton setEnabled:YES];
    [self setTableColEdit:YES];
    
    // Apps were installed that require a reboot
    if (_needsReboot >= 1) {
        [self showRebootPanel:nil];
    }
    
    [mpd release];
    [iPool release];
}

- (BOOL)installSoftwareItem:(NSDictionary *)dict
{
    NSString *installFile = [[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:MP_INSTALLED_DATA];
    NSMutableDictionary *installData = [[NSMutableDictionary alloc] init];
    [installData setObject:[NSDate date] forKey:@"installDate"];
    [installData setObject:[dict objectForKey:@"id"] forKey:@"id"];
    [installData setObject:[dict objectForKey:@"name"] forKey:@"name"];
    if ([dict objectForKey:@"sw_uninstall"]) {
        [installData setObject:[dict objectForKey:@"sw_uninstall"] forKey:@"sw_uninstall"];    
    } else {
        [installData setObject:@"" forKey:@"sw_uninstall"];
    }
    NSMutableArray *_data;
    if ([fm fileExistsAtPath:installFile]) {
        _data = [NSMutableArray arrayWithContentsOfFile:installFile];
    } else {
        if (![fm fileExistsAtPath:[mp_SOFTWARE_DATA_DIR path]]) {
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
            [fm createDirectoryAtPath:[mp_SOFTWARE_DATA_DIR path] withIntermediateDirectories:YES attributes:attributes error:NULL];
        }
        _data = [NSMutableArray array];
    }
    [_data addObject:installData];
    [_data writeToFile:installFile atomically:YES];
    [installData autorelease];
    return YES;
}

#pragma mark - Remove Software
- (IBAction)removeSoftware:(id)sender
{
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *d in [arrayController arrangedObjects]) {
        if ([d objectForKey:@"selected"] && [d objectForKey:@"installed"]) {
            if (([[d objectForKey:@"selected"] intValue] == 1) && ([[d objectForKey:@"installed"] intValue] == 1)) {
                [items addObject:[d objectForKey:@"name"]];
            }
        }
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Remove Software?"];
    [alert setInformativeText:[NSString stringWithFormat:@"Are you sure you want to uninstall/remove the following item(s). \n %@",[items componentsJoinedByString:@","]]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        // OK clicked, delete the record
        [self performSelectorInBackground:@selector(removeSoftwareThread) withObject:nil];
    }
    [alert release];
    
    
}

- (void)removeSoftwareThread
{
    NSAutoreleasePool *iPool = [[NSAutoreleasePool alloc] init];
    [refreshButton setEnabled:NO];
    [swDistGroupsButton setEnabled:NO];
    [self setTableColEdit:NO];
    
    [progressBar setIndeterminate:YES];
    [progressBar startAnimation:nil];
    [progressBar display];
    
    int _result = 0;
    
    NSString *uninstallScriptEnc, *uninstallScript;
    
	for (NSDictionary *d in [arrayController arrangedObjects]) {
        if ([d objectForKey:@"selected"] && [d objectForKey:@"installed"]) {
            if (([[d objectForKey:@"selected"] intValue] == 1) && ([[d objectForKey:@"installed"] intValue] == 1)) {
                [statusTextStatus setStringValue:[NSString stringWithFormat:@"Uninstalling %@ ...",[d objectForKey:@"name"]]];
                uninstallScriptEnc = [d valueForKeyPath:@"Software.sw_uninstall"];
                if ([uninstallScriptEnc length] > 0) {
                    uninstallScript = [uninstallScriptEnc decodeBase64WithNewLinesReturnString:NO];
                    logit(lcl_vDebug,@"Remove Script:\n%@",uninstallScript);
                    _result = [self removeSoftwareViaProxy:uninstallScript];   
                }
                
                if (_result == 0) {
                    [self removeSoftwareInstallStatus:[d objectForKey:@"id"]];
                    [self updateArrayControllerWithDictionary:d forActionType:@"remove"];
                    [statusTextStatus setStringValue:[NSString stringWithFormat:@"Uninstall competed."]];
                } else {
                    [self updateArrayControllerWithDictionary:d forActionType:@"error"];
                    [statusTextStatus setStringValue:[NSString stringWithFormat:@"Error uninstalling."]];
                }
                [self postUnInstallResults:_result resultText:@"" task:d];
            }
        }
    }
    
    [progressBar stopAnimation:nil];
    [progressBar display];
    [refreshButton setEnabled:YES];
    [swDistGroupsButton setEnabled:YES];
    [self setTableColEdit:YES];
    [iPool release];
}

#pragma mark MPDLWrapper Callbacks
- (void)appendDownloadProgress:(double)aNumber
{
	[progressBar setDoubleValue:aNumber];
}

- (void)appendDownloadProgressPercent:(NSString *)aPercent
{
	//[self setStatusDownloadPercent:[NSString stringWithFormat:@"%@%%",aPercent]];
    logit(lcl_vDebug,@"%@",[NSString stringWithFormat:@"%@%%",aPercent]);
}

- (void)downloadStarted
{	
	[statusTextStatus setStringValue:@"Downloading..."];
}

- (void)downloadFinished
{
    [statusTextStatus setStringValue:@"Done"];
	isDownloading = NO;
}

- (void)downloadError
{
	//[cancelButton setEnabled:YES];
    [statusTextStatus setStringValue:@"Download Error"];
	[progressBar setDoubleValue:0.0];
}

#pragma mark IBActions

- (IBAction)checkboxChanged:(id)sender
{
    [selectedItems removeAllObjects];
    
    int _selected = 0;
    int _installed = 0;
    for (NSDictionary *d in [arrayController arrangedObjects]) {
        if ([d objectForKey:@"selected"]) {
            if ([[d objectForKey:@"selected"] intValue] == 1) {
                [selectedItems addObject:d];
                _selected++;
                
                if ([d objectForKey:@"installed"]) {
                    if ([[d objectForKey:@"installed"] intValue] == 1) {
                        _installed++;
                        _selected--;
                    }
                }
            }
        }
    }
    if ((_selected == 1 || _installed == 1) && (_selected + _installed) == 1 ) {
        [infoButton setEnabled:YES];
    } else {
        [infoButton setEnabled:NO];
    }
    
    if (_selected >= 1) {
        [installButton setEnabled:YES];
    } else {
        [installButton setEnabled:NO];
    }
    
    if (_installed >= 1) {
        [removeButton setEnabled:YES];
    } else {
        [removeButton setEnabled:NO];
    }
}

- (IBAction)refreshSoftware:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(downloadSoftwareContent) toTarget:self withObject:nil];
}

- (IBAction)cancelSoftware:(id)sender
{
    [statusTextStatus setStringValue:@"Canceling software install task..."];
	[self setCancelInstalls:YES];
}

- (IBAction)getSoftwareDataFromFile:(id)sender
{
    NSArray *a = [NSKeyedUnarchiver unarchiveObjectWithFile:[[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:@"content.plist"]];
    
    if (a && [a count] > 0) {
		[arrayController removeObjects:[arrayController arrangedObjects]];
		[arrayController addObjects:a];	
		[tableView reloadData];
		[tableView deselectAll:self];
	}
}

#pragma mark Class Methods

- (IBAction)showMainLog:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/MPCatalog.log"] withApplication:@"Console"]; 
}
- (IBAction)showHelperLog:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:@"/Library/MacPatch/Client/Logs/MPWorker.log" withApplication:@"Console"]; 
}

- (void)updateArrayControllerWithDictionary:(NSDictionary *)dict
{
    [self updateArrayControllerWithDictionary:dict forActionType:@"installed"];
}

- (void)updateArrayControllerWithDictionary:(NSDictionary *)dict forActionType:(NSString *)type
{
    NSMutableArray *a = [[NSMutableArray alloc] initWithArray:[arrayController arrangedObjects]];
    
    [arrayController removeObjects:[arrayController arrangedObjects]];
    
    for (int i = 0; i < [a count]; i++) 
    {
        if ([[[a objectAtIndex:i] objectForKey:@"id"] isEqualTo:[dict objectForKey:@"id"]]) {
            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:dict];
            if ([type isEqualToString:@"installed"] == YES) {
                [d setObject:[NSNumber numberWithInt:1] forKey:@"installed"];
                [d setObject:[NSNumber numberWithBool:NO] forKey:@"selected"];
            } else if ([type isEqualToString:@"remove"] == YES) {
                [d setObject:[NSNumber numberWithInt:0] forKey:@"installed"];
                [d setObject:[NSNumber numberWithBool:NO] forKey:@"selected"];
                if ([dict hasKey:@"isReceipt"]) {
                    if ([[dict objectForKey:@"isReceipt"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                        [a removeObjectAtIndex:i];
                        break;
                    }
                }
            } else if ([type isEqualToString:@"install"] == YES) {
                [d setObject:[NSNumber numberWithInt:2] forKey:@"installed"];
            } else if ([type isEqualToString:@"error"] == YES) {
                [d setObject:[NSNumber numberWithInt:3] forKey:@"installed"];  
            } else if ([type isEqualToString:@"download"] == YES) {
                [d setObject:[NSNumber numberWithInt:4] forKey:@"installed"];      
            } else {
                [d setObject:[NSNumber numberWithInt:0] forKey:@"installed"];
            }
            [a replaceObjectAtIndex:i withObject:d];
        }
    }
    
    [arrayController addObjects:[a copy]];	
    [tableView reloadData];
    [tableView deselectAll:self];
    [tableView display];
    [a release];
    
    [self checkboxChanged:nil];
}

- (void)removeSoftwareInstallStatus:(NSString *)swID
{
    NSString *installFile = [[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:MP_INSTALLED_DATA];
    
    NSMutableArray *_data = nil;
    if ([fm fileExistsAtPath:installFile]) {
        _data = [NSMutableArray arrayWithContentsOfFile:installFile];
    }
    
    if (!_data) {
        return;
    }
    
    for (int i = 0; [_data count]; i++) {
        if ([[[_data objectAtIndex:i] objectForKey:@"id"] isEqualToString:swID]) {
            [_data removeObjectAtIndex:i];
            break;
        }
    }
    
    [_data writeToFile:installFile atomically:YES];
}

- (void)downloadSoftwareContent
{
    NSAutoreleasePool *iPool = [[NSAutoreleasePool alloc] init];
    
    [progressBar setHidden:NO];
    [progressBar setIndeterminate:YES];
    [progressBar startAnimation:self];
    [progressBar display];
    
    [statusTextStatus setStringValue:@"Downloading Software Distribution Content..."];
    [NSThread sleepForTimeInterval:2];
    
    MPSWTasks *sw = [[MPSWTasks alloc] init];
    [sw setGroupName:[[swDistGroupsButton selectedItem] title]];
    [self setSwDistCurrentTitle:[[swDistGroupsButton selectedItem] title]];
    NSError *err = nil;
    NSDictionary *_tasks = [sw getSWTasksForGroupFromServer:&err];
    window.title = [NSString stringWithFormat:@"MP - Software Catalog (%@)",[sw groupName]];
    
    if (err) {
        [statusTextStatus setStringValue:[NSString stringWithFormat:@"%@",[[err userInfo] objectForKey:@"NSLocalizedDescription"]]];
    } else {
        [self filterSoftwareContent:[_tasks objectForKey:@"Tasks"]];
        [statusTextStatus setStringValue:@"Done"];
    }
    
    [sw release];
    [progressBar stopAnimation:nil];
    
    [self checkAndInstallMandatoryApplications];
    
    [iPool release];
}

- (void)filterSoftwareContent:(NSArray *)content
{
    NSArray *_a;
    int c = 0;
    NSMutableDictionary *d;
    NSDictionary *_SoftwareCriteria;
    NSMutableArray *_SoftwareArray = [[NSMutableArray alloc] init];
    NSMutableArray *_MandatorySoftware = [[NSMutableArray alloc] init];
    NSError *err = nil;
    if (content) {
        /* If there is content */
        BOOL isDir;
        BOOL dirExists = [fm fileExistsAtPath:[mp_SOFTWARE_DATA_DIR path] isDirectory:&isDir];
        if (!dirExists) {
            [fm createDirectoryAtPath:[mp_SOFTWARE_DATA_DIR path] withIntermediateDirectories:YES attributes:nil error:&err];
            if (err) {
               logit(lcl_vError,@"%@",[err localizedDescription]);
                return;
            }
        }
        
        [self writeArrayFileViaProxy:[[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:@"content.plist"] data:content];
        _a = [NSKeyedUnarchiver unarchiveObjectWithFile:[[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:@"content.plist"]];
        for (id item in _a) 
        {
            d = [[NSMutableDictionary alloc] initWithDictionary:item];
            logit(lcl_vDebug,@"Checking %@",[d objectForKey:@"name"]);
            c = 0;
            MPOSCheck *mpos = [[MPOSCheck alloc] init];
            _SoftwareCriteria = [item objectForKey:@"SoftwareCriteria"];
            // OSArch
            if ([mpos checkOSArch:[_SoftwareCriteria objectForKey:@"arch_type"]]) {
                logit(lcl_vDebug,@"OSArch=TRUE: %@",[_SoftwareCriteria objectForKey:@"arch_type"]);
            } else {
                logit(lcl_vDebug,@"OSArch=FALSE: %@",[_SoftwareCriteria objectForKey:@"arch_type"]);
                c++;
            }
            // OSType
            if ([mpos checkOSType:[_SoftwareCriteria objectForKey:@"os_type"]]) {
                logit(lcl_vDebug,@"OSType=TRUE: %@",[_SoftwareCriteria objectForKey:@"os_type"]);
            } else {
                logit(lcl_vDebug,@"OSType=FALSE: %@",[_SoftwareCriteria objectForKey:@"os_type"]);
                c++;
            }
            // OSVersion
            if ([mpos checkOSVer:[_SoftwareCriteria objectForKey:@"os_vers"]]) {
                logit(lcl_vDebug,@"OSVersion=TRUE: %@",[_SoftwareCriteria objectForKey:@"os_vers"]);
            } else {
                logit(lcl_vDebug,@"OSVersion=FALSE: %@",[_SoftwareCriteria objectForKey:@"os_vers"]);
                c++;
            }
            [mpos release];
            mpos = nil;
            // Did not pass the criteria check
            if (c >= 1) {
            	[d release];
                continue;
            }
            // Check Start Date
            NSDate *now = [NSDate date];
            NSDate *startDate = [NSDate dateFromString:[d objectForKey:@"sw_start_datetime"]];
            NSDate *endDate = [NSDate dateFromString:[d objectForKey:@"sw_end_datetime"]];
            
            if ([now timeIntervalSince1970] < [startDate timeIntervalSince1970]) {
                // Software is not ready for deployment
                continue;
            }
            // Check for Mandatory apps
            BOOL isMandatory = NO;
            if ([now timeIntervalSince1970] >= [endDate timeIntervalSince1970]) {
                if ([[d objectForKey:@"sw_task_type"] containsString:@"m" ignoringCase:YES]) {
                    isMandatory = YES;
                }
            }
            
            // Check to see if it's installed
            NSString *installFile = [[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:MP_INSTALLED_DATA];
            if ([fm fileExistsAtPath:installFile]) {
                NSArray *a = [NSArray arrayWithContentsOfFile:installFile];
                for (int i = 0; i < [a count];i++) {
                    if ([[[a objectAtIndex:i] objectForKey:@"id"] isEqualTo:[item objectForKey:@"id"]]) {
                        [d setObject:[NSNumber numberWithInt:1] forKey:@"installed"];
                        isMandatory = NO; // It's installed ... no need to install
                    }
                }
            }
            
            // Has not been installed, and is mandatory
            if (isMandatory == YES) {
                logit(lcl_vInfo,@"Adding %@ to mandatory installs.",[d objectForKey:@"name"]);
                [_MandatorySoftware addObject:d];
            }
            
            // Populate install by date
            if ([[[d objectForKey:@"sw_task_type"] uppercaseString] containsString:@"m"]) {
                [d setObject:[d objectForKey:@"sw_end_datetime"] forKey:@"installBy"];
            }
            
            [_SoftwareArray addObject:d];
            [d release];
            d = nil;
        }
        
    } else {
        /* If there is no content, dosp[lay only installed items */
        _a = [NSKeyedUnarchiver unarchiveObjectWithFile:[[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:@"content.plist"]];
        if (_a) {
            
            for (id item in _a) 
            {
                d = [[NSMutableDictionary alloc] initWithDictionary:item];
                
                // Check to see if it's installed
                NSString *installFile = [[mp_SOFTWARE_DATA_DIR path] stringByAppendingPathComponent:MP_INSTALLED_DATA];
                if ([fm fileExistsAtPath:installFile]) {
                    NSArray *a = [NSArray arrayWithContentsOfFile:installFile];
                    for (int i = 0; i < [a count];i++) {
                        if ([[[a objectAtIndex:i] objectForKey:@"id"] isEqualTo:[item objectForKey:@"id"]]) {
                            [d setObject:[NSNumber numberWithInt:1] forKey:@"installed"];
                            [d setObject:[NSNumber numberWithInt:1] forKey:@"isReceipt"];
                            // Populate install by date
                            if ([[[d objectForKey:@"sw_task_type"] uppercaseString] containsString:@"m"]) {
                                [d setObject:[d objectForKey:@"sw_end_datetime"] forKey:@"installBy"];
                            }
                            
                            [_SoftwareArray addObject:d];
                        }
                    }
                }
                
                [d release];
                d = nil;
            }
            
        }
    }
    
    logit(lcl_vInfo,@"Approved/Installed Software tasks: %@",_SoftwareArray);
    [arrayController removeObjects:[arrayController arrangedObjects]];
    if (_SoftwareArray && [_SoftwareArray count] > 0) 
    {	
		[arrayController addObjects:_SoftwareArray];	
	}
    [tableView reloadData];
    [tableView deselectAll:self];
    
    if ([_MandatorySoftware count] >= 1) {
        logit(lcl_vDebug,@"Need to install mandatory apps");
    }
    
    [_MandatorySoftware release];
    [_SoftwareArray release];
}

#pragma mark WebService methods
- (void)postInstallResults:(int)resultNo resultText:(NSString *)resultString task:(NSDictionary *)taskDict
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    MPSWTasks *swt = [[[MPSWTasks alloc] init] autorelease];
    int result = -1;
    result = [swt postInstallResults:resultNo resultText:resultString task:taskDict];
    [pool release];
}

- (void)postUnInstallResults:(int)resultNo resultText:(NSString *)resultString task:(NSDictionary *)taskDict
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    MPSWTasks *swt = [[[MPSWTasks alloc] init] autorelease];
    int result = -1;
    result = [swt postUnInstallResults:resultNo resultText:resultString task:taskDict];
    [pool release];
}

#pragma mark Misc
- (BOOL)hasCanceledInstall:(NSDictionary *)task
{
    if (cancelInstalls == YES) 
    {
        [cancelButton setEnabled:NO];
        [statusTextStatus setStringValue:@"Cancel Install Tasks"];
        logit(lcl_vInfo,@"Install task has been canceled");
        [self setCancelInstalls:NO];
        [self updateArrayControllerWithDictionary:task forActionType:@"cancel"];
        [progressBar setHidden:YES];
        [statusTextStatus setStringValue:@" "];
        return YES;
    }
    
    return NO;
}

#pragma mark - Proxy Methods
-(int)installSoftwareViaProxy:(NSDictionary *)aInstallDict
{
	int results = -1;
	
	if (!proxy) {
        [self connect];
        if (!proxy) {
			logit(lcl_vError,@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		} 
    }
	
	@try {
		results = [proxy installSoftwareViaHelper:aInstallDict];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runTaskUsingHelper [Custom Scan] error: %@", e);
    }
	
done:
	[self cleanup];
	return results;
}

- (int)patchSoftwareViaProxy:(NSDictionary *)aInstallDict
{
    int results = -1;
	
	if (!proxy) {
        [self connect];
        if (!proxy) {
			logit(lcl_vError,@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		} 
    }
	
	@try {
		results = [proxy patchSoftwareViaHelper:aInstallDict];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runTaskUsingHelper [Custom Scan] error: %@", e);
    }
	
done:
	[self cleanup];
	return results;
}

- (int)removeSoftwareViaProxy:(NSString *)removeScript
{
    int results = -1;
	
	if (!proxy) {
        [self connect];
        if (!proxy) {
			logit(lcl_vError,@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		} 
    }
	
	@try {
		results = [proxy removeSoftwareViaHelper:removeScript];
        // Quick fix, script result is a bool
        if (results == 1) {
            results = 0;
        } else {
            results = 1;
        }
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runTaskUsingHelper [Remove Software] error: %@", e);
    }
	
done:
	[self cleanup];
	return results;
}

- (void)setLoggingState:(BOOL)aState
{
	if (!proxy) 
    {
        [self connect];
    }
    
	if (proxy) 
    {
        @try 
        {
            [proxy setLoggingState:aState];
        }
        @catch (NSException *e) {
            logit(lcl_vError,@"Trying to set the logging level, %@", e);
        }
    }
    
    [self cleanup];
	return;
}

- (int)writeToFileViaProxy:(NSString *)aFile data:(id)data
{
    int results = -1;
	
	if (!proxy) {
        [self connect];
        if (!proxy) {
			logit(lcl_vError,@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		}
    }
	
	@try {
		results = [proxy writeDataToFileViaHelper:data toFile:aFile];
        // Quick fix, script result is a bool
        if (results == 1) {
            results = 0;
        } else {
            results = 1;
        }
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"runTaskUsingHelper [writeDataToFileViaHelper] error: %@", e);
    }
	
done:
	[self cleanup];
	return results;
}

- (int)writeArrayFileViaProxy:(NSString *)aFile data:(NSArray *)data
{
    int results = -1;
	
	if (!proxy) {
        [self connect];
        if (!proxy) {
			logit(lcl_vError,@"Unable to connect to helper application. Functionality will be diminished.");
			goto done;
		}
    }
	
	@try {
		results = [proxy writeArrayToFileViaHelper:data toFile:aFile];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"writeArrayToFileViaHelper error: %@", e);
    }
	
done:
	[self cleanup];
	return results;
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(connectionDown:)
													 name:NSConnectionDidDieNotification
												   object:connection];
		
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
    logit(lcl_vInfo,@"helperd connection down");
    [self cleanup];
} 

#pragma mark Client Callbacks
- (void)statusData:(in bycopy NSString *)aData
{
    [statusTextStatus setStringValue:aData];
}
- (void)installData:(in bycopy NSString *)aData
{
    NSString *strTxt;
    strTxt = [aData replaceAll:@"installer:STATUS:" replaceString:@""];
    strTxt = [strTxt replaceAll:@"installer:PHASE:" replaceString:@""];
    if ([aData containsString:@"installer:"]) {
        if ([strTxt containsString:@"installer:%"]) {
            [progressBar setDoubleValue:[[[[strTxt replaceAll:@"installer:%" replaceString:@""] componentsSeparatedByString:@"."] objectAtIndex:0] floatValue]];
        } else {
            [statusTextStatus setStringValue:strTxt];
        }
    }
}

@end
