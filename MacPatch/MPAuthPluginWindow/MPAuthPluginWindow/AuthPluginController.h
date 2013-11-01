//
//  AuthPluginController.h
//  MPAuthPluginWindow
//
//  Created by Heizer, Charles on 10/30/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPWorkerProtocol.h"

@class MPDefaults;
@class MPServerConnection;

@interface AuthPluginController : NSWindowController <MPWorkerClient,NSTableViewDelegate>
{
    MPServerConnection *mpServerConnection;
    // Helper
	id                 proxy;

    // Main Window
    IBOutlet NSButton *cancelButton;
    IBOutlet NSTextField *appVerText;

    NSThread            *taskThread;
	BOOL                killTaskThread;

    // Patch Table
    IBOutlet NSTableView *patchesTableView;
    IBOutlet NSArrayController *patchesArrayController;

    // Status
    int progressCount;
    int progressCountTotal;

    IBOutlet NSTextField *statusText;
    IBOutlet NSProgressIndicator *progressBarStatus;
    IBOutlet NSTextField *progressCountText;
    IBOutlet NSTextField *progressText;
    IBOutlet NSProgressIndicator *progressBarProgress;

    // Restart Window
    IBOutlet NSWindow *restartWindow;
	IBOutlet NSTextField *restartWindowText;

@private
    NSFileManager *fm;
    int currentPatchInstallIndex;
}

@property (nonatomic, strong) MPServerConnection *mpServerConnection;
@property (nonatomic, strong) NSThread *taskThread;
@property (nonatomic, assign) BOOL killTaskThread;
@property (nonatomic, assign) int progressCount;
@property (nonatomic, assign) int progressCountTotal;
@property (nonatomic, assign) int currentPatchInstallIndex;

@end
