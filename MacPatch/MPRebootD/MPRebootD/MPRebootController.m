//
//  MPRebootController.m
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

#import "MPRebootController.h"

#define WATCH_PATH              @"/Users/Shared"
#define WATCH_PATH_FILE         @".needsReboot"
#define WATCH_PATH_ALT			@"/private/tmp"
#define WATCH_PATH_FILE_ALT		@".MPRebootRun.plist"
#define MP_REBOOT               @"/Library/MacPatch/Client/MPReboot.app"
#define MP_REBOOT_ALT           @"/Library/MacPatch/Client/MPReboot.app/Contents/MacOS/MPReboot"

#undef  ql_component
#define ql_component lcl_cMain

@interface MPRebootController ()

// Helper
- (void)connect;
- (int)connect:(NSError **)err;
- (void)cleanup;
- (void)connectionDown:(NSNotification *)notification;

// Worker Methods
- (void)removeRebootFileViaProxy;

@end

@implementation MPRebootController

#pragma mark -
#pragma mark MPWorker
- (void)connect
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

- (int)connect:(NSError **)err
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
    logit(lcl_vInfo,@"MPWorker connection down");
    [self cleanup];
}

#pragma mark - Worker Methods

- (void)removeRebootFileViaProxy
{
    NSError *error = nil;
	if (!proxy) {
        [self connect:&error];
        if (error) {
            logit(lcl_vError,@"cleanUpRebootFileViaHelper error 1001: %@",[error localizedDescription]);
        }
        if (!proxy) {
            logit(lcl_vError,@"cleanUpRebootFileViaHelper error 1002: Unable to get proxy object.");
            goto done;
        }
    }

    @try
	{
		logit(lcl_vDebug,@"[proxy run cleanUpRebootFileViaHelper]");
		[proxy cleanUpRebootFileViaHelper];
    }
    @catch (NSException *e) {
        logit(lcl_vError,@"cleanUpRebootFileViaHelper error: %@", e);
    }

done:
	[self cleanup];
}

#pragma mark - main

- (NSDictionary *)file_attr
{
    return file_attr;
}

- (void)setFile_attr:(NSDictionary *)aFile_attr
{
    if (file_attr != aFile_attr) {
        file_attr = [aFile_attr copy];
    }
}

- (NSArray *)watchFiles
{
    return watchFiles;
}

- (void)setWatchFiles:(NSArray *)aWatchFiles
{
    if (watchFiles != aWatchFiles) {
        watchFiles = [aWatchFiles copy];
    }
}

-(id)init
{
	self = [super init];

    NSArray *a = [NSArray arrayWithObjects:[WATCH_PATH stringByAppendingPathComponent:WATCH_PATH_FILE],[WATCH_PATH_ALT stringByAppendingPathComponent:WATCH_PATH_FILE_ALT], nil];
    [self setWatchFiles:a];

	// Create the watch Path Dir
	NSFileManager *fm = [NSFileManager defaultManager];
	[self setFile_attr:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:0777],@"NSFilePosixPermissions",nil]];
	
	BOOL isDir = NO;
	if ([fm fileExistsAtPath:WATCH_PATH isDirectory:&isDir])
    {
        if (!isDir)
        {
            NSError *err = nil;
            [fm removeItemAtPath:WATCH_PATH error:&err];
            if (err) {
                logit(lcl_vError, @"%@",err.localizedDescription);
            }
            err = nil;
            [fm createDirectoryAtPath:WATCH_PATH withIntermediateDirectories:YES attributes:file_attr error:&err];
            if (err) {
                logit(lcl_vError, @"%@",err.localizedDescription);
            }
        }
	} else {
        [fm createDirectoryAtPath:WATCH_PATH withIntermediateDirectories:YES attributes:file_attr error:NULL];
	}
	
	[self startWatchPathTimer];
	
	return self;
}


- (void)openRebootApp:(int)aType
{
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:MP_REBOOT] == FALSE) {
		logit(lcl_vError,@"%@, does not exist. No reboot will occur.",MP_REBOOT);
		return;
	}
	
	NSString *identifier = [[NSBundle bundleWithPath:MP_REBOOT] bundleIdentifier];
    logit(lcl_vInfo,@"Getting rebot app bundle id (%@)",identifier);
    if (!identifier)
    {
        logit(lcl_vError,@"Bundle retured empty identifier, using gov.llnl.MPReboot.");
        identifier = @"gov.llnl.MPReboot";
    }

	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSArray *apps = [ws valueForKeyPath:@"launchedApplications.NSApplicationBundleIdentifier"];
    logit(lcl_vDebug,@"Gattering launched applications array\n%@",apps);
    
    if (apps)
    {
        if ([apps containsObject:identifier] == NO)
        {
            if (aType == 0) {
                [[NSWorkspace sharedWorkspace] openFile:MP_REBOOT];
                [self removeRebootFileViaProxy];
            } else {
                [NSTask launchedTaskWithLaunchPath:MP_REBOOT_ALT arguments:[NSArray arrayWithObjects:@"-type", @"swReboot", nil]];
                [self removeRebootFileViaProxy];
            }
            
        } else {
            logit(lcl_vInfo,@"%@, is already running.",MP_REBOOT);
        }
    }
}

- (void)startWatchPathTimer
{
	[NSThread detachNewThreadSelector:@selector(startWatchPathTimerThread) toTarget:self withObject:nil];
}

//the thread starts by sending this message
- (void)startWatchPathTimerThread
{
	@autoreleasepool {
		NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
		[NSTimer scheduledTimerWithTimeInterval: 0.5
										 target: self
									   selector: @selector(watchPathTimerRun:)
									   userInfo: nil
										repeats: YES];
		
		[runLoop run];
	}
}

- (void)watchPathTimerRun:(NSTimer *)timer
{
    for (NSString *wp in self.watchFiles)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:wp] == TRUE)
        {
            // This is left in to remove older reboot files
            @try {
                NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:wp];
                if (d) {
                    if ([d objectForKey:@"reboot"]) {
                        if ([[d objectForKey:@"reboot"] boolValue] == YES) {
                            [self openRebootApp:1];
                            logit(lcl_vInfo,@"Opening reboot application. %@ was found.",wp);
                            break;
                        }
                    }
                }
            }
            @catch (NSException *exception) {
                logit(lcl_vError,@"Opening reboot application. %@",exception);
            }
        }
    }
}

@end
