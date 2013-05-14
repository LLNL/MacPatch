//
//  AppDelegate.h
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

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import "MPInstallTask.h"
#import "TaskWrapper.h"

@class MPServerConnection;
@class MPSoap, MPDefaults, MPASUSCatalogs;


@interface AppDelegate : NSObject <TaskWrapperController> 
{
	MPServerConnection *mpServerConnection;
    
    IBOutlet NSWindow *window;
	NSTextField *status;
	
	IBOutlet NSTableView *tableView;
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSTextField *appVerText;
	IBOutlet NSTextField *statusText;
	IBOutlet NSTextField *numberOfUpdates;
	
	IBOutlet NSProgressIndicator *progressBar;
	IBOutlet NSProgressIndicator *progressWheel;
	
	IBOutlet NSButton		*quitRestartButton;
	IBOutlet NSButton		*debugButton;
	
	IBOutlet NSWindow		*restartWindow;
	IBOutlet NSTextField	*restartWindowText;
	
	int numberOfUpdatesInstalled;
	int numberOfUpdatesNeeded;
	BOOL installTaskIsRunning;
	
	int secondsTilReboot;
	NSTimer *restartTimer;
	
	// Run Install task
	NSTask *task;
	NSPipe *install_pipe;
	NSFileHandle *fh_installTask;
	NSString *installStatusText;
	
	BOOL killTasks;
	
	MPSoap *mps;
	MPASUSCatalogs *catObj;
	MPInstallTask *mpiTask;
	
	IBOutlet NSButton *disclosureTriangle;
	IBOutlet NSDrawer *infoDrawer;
	IBOutlet NSTextView *installStatusOutput;
	
    // New 	
	BOOL		installIsRunning;
	TaskWrapper	*installTask;
}

@property (nonatomic, retain) NSString *installStatusText;
@property (nonatomic, retain) IBOutlet NSTextView *installStatusOutput;
@property (nonatomic, assign) int numberOfUpdatesNeeded;
@property (nonatomic, assign) int numberOfUpdatesInstalled;
@property (nonatomic, assign) int secondsTilReboot;
@property (nonatomic, assign) BOOL installTaskIsRunning;
@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;

//Class Methods
- (NSArray *)scanHostForPatches;
- (NSArray *)scanForAppleUpdates;
- (void)scanForNotification:(NSNotification *)notification;
- (void)scanForNotificationFinished:(NSNotification *)notification;

- (void)runSwuai;
- (int)installCustomUpdate:(NSDictionary *)aUpdate;
- (void)postInstallToWebService:(NSString *)aPatch type:(NSString *)aType;

- (void)updateTableAndArrayController:(int)idx status:(int)aStatusImage;
- (void)exitTheApp;

- (IBAction)sendAppQuit:(id)sender;
- (IBAction)sendCancel:(id)sender;
- (void)incrementTimer:(id)sender;
- (void)restartLocalSystem;
- (void)removeLogOutHook;
- (void)RebootDialog;
- (void)sendBasicSOAP:(NSString *)aMethod content:(NSDictionary *)aDict;

- (void)setupDrawer;
- (void)openDrawer:(id)sender;
- (void)closeDrawer:(id)sender;
- (void)toggleDrawer:(id)sender;
- (IBAction)disclosureTrianglePressed:(id)sender;

- (void)appendStatusString:(NSString *)aStr;
- (void)installStatusNotify:(NSNotification *)aNotification;

//Test Methods
- (void)beginWatchStringThread;
- (void)watchStringThread;

// New MPInstaller Methods
- (void)installProcessStarted;
- (void)installProcessFinished;
- (void)appendOutput:(NSString *)output;
- (void)realAppendOutput:(NSString *)output;
- (void)scrollToVisible:(id)ignore;

// Apple Pre/Post Install Criteria
- (int)startCriteria:(NSDictionary *)aPatch type:(int)criteriaType;

@end
