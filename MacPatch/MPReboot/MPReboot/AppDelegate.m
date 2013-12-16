//
//  MPRebootAppDelegate.m
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

NSString * const WATCH_PATH_ALT =			@"/private/tmp";
NSString * const WATCH_PATH_FILE_ALT =		@".MPRebootRun.plist";

NSString * const kRBPatchTitle = @"Install and Restart";
NSString * const kRBPatchBody = @"MacPatch needs to finish installing updates that require a reboot. Please save your work and exit all applications before continuing.\n\nTo finish the installation and restart your computer, click Restart.";

NSString * const kRBSWInstallTitle = @"Restart Required";
NSString * const kRBSWInstallBody = @"MacPatch has installed software that requires a reboot. Please save your work and exit all applications and then click the restart button.";

NSString * const kRBPatchAlertTitle = @"Restart Required";
NSString * const kRBPatchAlertBody = @"Quiting this application will log you out of this system and start the patching process.";

NSString * const kRBSWInstallAlertTitle = @"Restart Required";
NSString * const kRBSWInstallAlertBody = @"Quiting this application will restart this system and complete the necessary reboot.";


@implementation AppDelegate

@synthesize _confirmed;
@synthesize isPatchReboot;
@synthesize wTitle;
@synthesize wBody;

-(void)awakeFromNib
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
	window.title = @"MacPatch Reboot Notification";
	[window center];
	[self set_confirmed:NO];
    [self setIsPatchReboot:YES];
    
    [wTitle setStringValue:kRBPatchTitle];
    [wBody setStringValue:kRBPatchBody];
    
    NSDictionary *arguments = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];
    NSString *rbType = [arguments objectForKey:@"type"];
    if (rbType) {
        if ([rbType isEqualToString:@"swReboot"]) {
            [self setIsPatchReboot:NO];
            [wTitle setStringValue:kRBSWInstallTitle];
            [wBody setStringValue:kRBSWInstallBody];
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSApplication sharedApplication]requestUserAttention:NSCriticalRequest];
}

- (void)applicationShouldTerminate:(NSApplication *)sender
{
	// Set return Value to void, that way the quit does not happen 
	if (_confirmed == NO) {
		[self confirmAppTerminate:nil];
	}	
}


// Bounce in the dock until user accepts
- (void)windowDidResignMain:(NSNotification *)notification
{
	[[NSApplication sharedApplication]requestUserAttention:NSCriticalRequest];
}

- (IBAction)logoutNowButton:(id)sender
{
    
	/* reboot the system using Apple supplied code
     error = SendAppleEventToSystemProcess(kAERestart);
     error = SendAppleEventToSystemProcess(kAELogOut);
     error = SendAppleEventToSystemProcess(kAEReallyLogOut);
     */
	[self set_confirmed:YES];
	
	OSStatus error = noErr;
#ifdef DEBUG
	error = SendAppleEventToSystemProcess(kAELogOut);
#else
	error = SendAppleEventToSystemProcess(kAEReallyLogOut);
#endif
    NSError *err = nil;
    NSString *rebootFilePath = [WATCH_PATH_ALT stringByAppendingPathComponent:WATCH_PATH_FILE_ALT];
    NSMutableDictionary *rebootFileDict = [NSMutableDictionary dictionaryWithContentsOfFile:rebootFilePath];
    if (rebootFileDict) {
        if ([[NSFileManager defaultManager] isWritableFileAtPath:rebootFilePath]) {
            [rebootFileDict setObject:[NSNumber numberWithBool:NO] forKey:@"reboot"];
            [rebootFileDict writeToFile:rebootFilePath atomically:NO];
        } else {
            NSLog(@"Error, unable to write changes to %@",rebootFilePath);
        }
    }

    if (err) {
        NSLog(@"Error removing %@",rebootFilePath);
        NSLog(@"%@",err.localizedDescription);
    }
	if (error == noErr) {
		NSLog(@"Computer is going to logout!");
		[NSApp terminate:self];
		exit(0);
	} else {
		NSLog(@"Computer wouldn't logout: %d", (int)error);
		[self quitAppAndMakeUserLogout];
	}
}

- (void)quitAppAndMakeUserLogout
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Warning: Issue attempting to logout."];
	[alert setInformativeText:@"There was an issue attempting to logout. Click \"OK\" to quit this application and please choose \"Logout\" or \"Restart\" from the Apple menu."];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		[NSApp terminate:self];
		exit(0);
	}
	[alert release];
}

- (IBAction)confirmAppTerminate:(id)sender
{
	// Display an alert dialog warning the user of the
	// reboot situation...
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
    if (isPatchReboot == YES) {
        [alert setMessageText:kRBPatchAlertTitle];
        [alert setInformativeText:kRBPatchAlertBody];
    } else {
        [alert setMessageText:kRBSWInstallAlertTitle];
        [alert setInformativeText:kRBSWInstallAlertBody];
    }
	
	[alert setAlertStyle:NSCriticalAlertStyle];
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		// OK clicked, ignore the reboot dialog
		[self logoutNowButton:nil];
	}
	
	[alert release];
}


@end
