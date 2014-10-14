//
//  MPAuthController.m
//  MPAuthPlugin
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

#import "MPAuthController.h"
#include <Security/AuthorizationPlugin.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include <CoreFoundation/CoreFoundation.h>
#include <syslog.h>
#include "MacPatch.h"

#include <stdlib.h>
#include <unistd.h>
#include <sys/reboot.h>

#undef  ql_component
#define ql_component lcl_cMain

static MPAuthController *mpAuthController = nil;
static void *lastMechanismRef;

#pragma mark ----------------- C Interface ----------------------

OSStatus setResult(AuthorizationMechanismRef inMechanism);
OSStatus initializeWindow(AuthorizationMechanismRef inMechanism, int modal);
OSStatus finalizeWindow(AuthorizationMechanismRef inMechanism);

OSStatus initializeWindow(AuthorizationMechanismRef inMechanism, int modal)
{

	if (!mpAuthController)
	{
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/tmp/.MPAuthRun"] == NO)
        {
            setResult(0);
            return 0;
        }

		mpAuthController = [[MPAuthController alloc] init];
		[NSApp activateIgnoringOtherApps:YES];
		[mpAuthController showWindow:nil];
	}
    
	[mpAuthController setRef:inMechanism];
	return 0;
}

OSStatus finalizeWindow(AuthorizationMechanismRef inMechanism)
{
	return 0;
}

#pragma mark ----------------- Objective-C Interface ----------------------

@implementation MPAuthController

- (id)init
{
	if ([super init])
	{
        [MPLog setupLogging:@"/private/var/tmp/MPAuth.log" level:lcl_vDebug];
        lcl_configure_by_name("*", lcl_vDebug);
        logit(lcl_vInfo,@"***** MPAuthPlugin started -- Debug Enabled *****");

		self = [super initWithWindowNibName:@"MPAuthController"];
	}
    return self;
}

- (void)dealloc
{
	mpAuthController = nil;
	lastMechanismRef = 0;
}

- (void)setRef:(void *)ref
{
	mMechanismRef = ref;
	lastMechanismRef = ref;
}

- (void)awakeFromNib
{
    [MPLog setupLogging:@"/private/var/tmp/MPAuth.log" level:lcl_vDebug];
    lcl_configure_by_name("*", lcl_vDebug);
    qlinfo(@"***** MPAuth started -- Debug Enabled *****");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeWindowNotification:)
                                                 name:@"closeWindowNotification"
                                               object:nil];

	[mpAuthWindow setCanBecomeVisibleWithoutLogin:YES];
	[mpAuthWindow setMovableByWindowBackground:FALSE];
	[mpAuthWindow performSelector:@selector(makeKeyAndOrderFront:)
                         withObject:mpAuthWindow
                         afterDelay:2.0];
}

- (void)redisplayWindow
{
    SCDynamicStoreRef   store;
    CFStringRef			consoleUserName;
    store = SCDynamicStoreCreate(NULL, NULL, NULL, NULL);
    consoleUserName = SCDynamicStoreCopyConsoleUser(store, NULL, NULL);
    if (consoleUserName != NULL)
    {
        if ([(__bridge NSString *)consoleUserName isEqualToString:@"loginwindow"])
        {
            CFRelease(consoleUserName);
            [[self window] makeKeyAndOrderFront:nil];
            [[self window] display];
        }
    }
    CFRelease(consoleUserName);
}

- (void)dismissWindow
{
/* Moved to worker
#ifdef DEBUG
    NSLog(@"Reboot would happen ...");
#else
    int rb = 0;
	rb = reboot(RB_AUTOBOOT);
    NSLog(@"MPAuthPlugin issued a reboot (%d)",rb);
    if (rb == -1) {
        // Try Forcing it :-)
        execve("/sbin/reboot",0,0);
    }
#endif
*/
    // Hide window in either case
    [[self window] orderOut:nil];
}

- (void)closeWindowNotification:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissWindow];
}

- (IBAction)closeWindow:(id)sender
{
	[self dismissWindow];
}

@end
