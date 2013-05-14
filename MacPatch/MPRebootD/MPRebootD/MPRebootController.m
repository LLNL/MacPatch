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

#define WATCH_PATH			@"/Users/Shared/.mpReboot"
#define WATCH_PATH_FILE		@".needsReboot"
#define MP_REBOOT			@"/Library/MacPatch/Client/MPReboot.app"
#define MP_REBOOT_ALT		@"/Library/MacPatch/Client/MPReboot.app/Contents/MacOS/MPReboot"

@implementation MPRebootController

- (NSDictionary *)file_attr
{
    return [[file_attr retain] autorelease];
}

- (void)setFile_attr:(NSDictionary *)aFile_attr
{
    if (file_attr != aFile_attr) {
        [file_attr release];
        file_attr = [aFile_attr copy];
    }
}

-(id)init
{
	self = [super init];
    
	// Create the watch Path Dir
	NSFileManager *fm = [NSFileManager defaultManager];
	[self setFile_attr:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:0777],@"NSFilePosixPermissions",nil]];
	
	BOOL isDir;
	if ([fm fileExistsAtPath:WATCH_PATH isDirectory:&isDir]) {
		[fm removeItemAtPath:WATCH_PATH error:NULL];
		[fm createDirectoryAtPath:WATCH_PATH withIntermediateDirectories:YES attributes:file_attr error:NULL];
	} else {
        [fm createDirectoryAtPath:WATCH_PATH withIntermediateDirectories:YES attributes:file_attr error:NULL];
	}
	
	[self startWatchPathTimer];
	
	return self;
}

- (void)dealloc
{
    [file_attr release];
    [super dealloc];
}

- (void)openRebootApp:(int)aType
{
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:MP_REBOOT] == FALSE) {
		logit(lcl_vError,@"%@, does not exist. No reboot will occur.",MP_REBOOT);
		return;
	}
	
	NSString *identifier = [[NSBundle bundleWithPath:MP_REBOOT] bundleIdentifier];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSArray *apps = [ws valueForKeyPath:@"launchedApplications.NSApplicationBundleIdentifier"];
	if ([apps containsObject:identifier] == NO)
    {
        if (aType == 0) {
            [[NSWorkspace sharedWorkspace] openFile:MP_REBOOT];
        } else {
            [NSTask launchedTaskWithLaunchPath:MP_REBOOT_ALT arguments:[NSArray arrayWithObjects:@"-type", @"swReboot", nil]];
        }
        
	} else {
		logit(lcl_vInfo,@"%@, is already running.",MP_REBOOT);
	}
}

- (void)startWatchPathTimer
{
	[NSThread detachNewThreadSelector:@selector(startWatchPathTimerThread) toTarget:self withObject:nil];
}

//the thread starts by sending this message
- (void)startWatchPathTimerThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	[NSTimer scheduledTimerWithTimeInterval: 0.5
									 target: self
								   selector: @selector(watchPathTimerRun:)
								   userInfo: nil
									repeats: YES];
	
	[runLoop run];
	[pool release];
}

- (void)watchPathTimerRun:(NSTimer *)timer
{
	BOOL isDir;
	if (([[NSFileManager defaultManager] fileExistsAtPath:WATCH_PATH isDirectory:&isDir] && isDir) == FALSE) {
		logit(lcl_vInfo,@"%@ is missing or is not a directory. Now creating directory.",WATCH_PATH);
		[[NSFileManager defaultManager] createDirectoryAtPath:WATCH_PATH withIntermediateDirectories:YES attributes:file_attr error:NULL];
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString pathWithComponents:[NSArray arrayWithObjects:WATCH_PATH,WATCH_PATH_FILE,nil]]] == TRUE) {
		logit(lcl_vInfo,@"Opening reboot application. %@ was found.",[NSString pathWithComponents:[NSArray arrayWithObjects:WATCH_PATH,WATCH_PATH_FILE,nil]]);
        NSString *fileContents;
        fileContents = [NSString stringWithContentsOfFile:[NSString pathWithComponents:[NSArray arrayWithObjects:WATCH_PATH,WATCH_PATH_FILE,nil]] encoding:NSUTF8StringEncoding error:NULL];
        NSRange textRange =[fileContents rangeOfString:@"swReboot"];
		[[NSFileManager defaultManager] removeItemAtPath:[NSString pathWithComponents:[NSArray arrayWithObjects:WATCH_PATH,WATCH_PATH_FILE,nil]] error:NULL];
        if(textRange.location == NSNotFound) {
            [self openRebootApp:0];
        } else {
            [self openRebootApp:1];
        }
	}
}

@end
