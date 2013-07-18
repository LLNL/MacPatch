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
#import "MPWorkerProtocol.h"

@class MPDefaults, MPAsus, MPSoap;
@class PrefsController;
@class MPServerConnection;

@interface MPSelfPatchAppDelegate : NSObject <MPWorkerClient> 
{    
    NSWindow *window;
	NSTableView *tableView;
	NSArrayController *arrayController;
	IBOutlet NSTextField *spStatusText;
	IBOutlet NSTextField *patchGroupLabel;
	IBOutlet NSButton *spScanAndPatchButton;
	IBOutlet NSButton *spCancelButton;
	IBOutlet NSButton *spUpdateButton;
	IBOutlet NSProgressIndicator *spStatusProgress;
	
	// Helper
	id                  proxy;
	
	// Preferences
	PrefsController     *prefsController;
	
@private
    
    NSFileManager      *fm;
    MPServerConnection *mpServerConnection;
    
	NSThread            *runTaskThread;
	BOOL                killTaskThread;
	MPAsus              *asus;
	MPSoap              *soap;
	
	NSString            *mpHost;
	NSString            *mpHostPort;
	
}

@property (nonatomic, retain) NSString *mpHost;
@property (nonatomic, retain) NSString *mpHostPort;

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain) IBOutlet NSButton *spUpdateButton;
@property (nonatomic, retain) IBOutlet NSButton *spCancelButton;

@property (nonatomic, assign) NSThread *runTaskThread;
@property (nonatomic, assign) BOOL killTaskThread;

- (IBAction)scanForPatches:(id)sender;
- (IBAction)installPatches:(id)sender;
- (IBAction)stopAndCloseSelfPatch:(id)sender;
- (IBAction)showLogInConsole:(id)sender;
- (IBAction)showPrefsPanel:(id)sender;

- (void)runPatchScan;
- (void)runPatchUpdates;
- (void)openRebootApp;

// Misc
- (NSDictionary *)getClientPatchState;
- (BOOL)checkPatchPreAndPostForRebootRequired:(NSArray *)aDictArray;
- (void)postInstallToWebService:(NSString *)aPatch type:(NSString *)aType;
- (void)updateTableAndArrayController:(int)objectAtIntex status:(int)aStatusImage;

// Test
-(void)handleColStateToggle:(NSNotification *)note;
-(void)handleColSizeToggle:(NSNotification *)note;
-(void)handleColBaselineToggle:(NSNotification *)note;

@end
