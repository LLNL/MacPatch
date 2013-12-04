//
//  MPAuthController.m
//  MPAuthPlugin
//
//  Created by Heizer, Charles on 10/29/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "MPAuthController.h"
#include <Security/AuthorizationPlugin.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include <CoreFoundation/CoreFoundation.h>
#include <syslog.h>
#include "MacPatch.h"

#include <stdlib.h>
#include <unistd.h>
#include <sys/reboot.h>

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
	[mpAuthController release];
	return 0;
}

#pragma mark ----------------- Objective-C Interface ----------------------

@implementation MPAuthController

- (id)init
{
	if ([super init])
	{
        [MPLog setupLogging:@"/Library/Logs/MPAuthPlugin.log" level:lcl_vDebug];
        lcl_configure_by_name("*", lcl_vDebug);
        logit(lcl_vInfo,@"***** MPAuthPlugin started -- Debug Enabled *****");

		self = [super initWithWindowNibName:@"MPAuthController"];
	}
    return self;
}

- (void)dealloc
{
    [super dealloc];
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
    [MPLog setupLogging:@"/Library/Logs/MPAuth.log" level:lcl_vDebug];
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
        if ([(NSString *)consoleUserName isEqualToString:@"loginwindow"])
        {
            [[self window] makeKeyAndOrderFront:nil];
            [[self window] display];
        }
    }
}

- (void)dismissWindow
{

#ifdef DEBUG
    NSLog(@"Reboot would happen ...");
#else
    int rb = 0;
	rb = reboot(RB_AUTOBOOT);
    NSLog(@"MPAuthPlugin issued a reboot (%d)",rb);
#endif

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
