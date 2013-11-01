//
//  MPAuthWindow.h
//  MPAuthPlugin
//
//  Created by Heizer, Charles on 10/29/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPWorkerProtocol.h"

@class MPDefaults;
@class MPServerConnection;

@interface MPAuthWindow : NSWindow <MPWorkerClient,NSTableViewDelegate>
{
    NSPoint initialLocation;
    BOOL fullscreen;

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
    IBOutlet NSTextField *statusText;
    IBOutlet NSProgressIndicator *progressBarStatus;
    int progressCount;
    int progressCountTotal;
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

@property (nonatomic, assign) IBOutlet NSTextField *title;
@property (nonatomic, strong) MPServerConnection *mpServerConnection;
@property (nonatomic, strong) NSThread *taskThread;
@property (nonatomic, assign) BOOL killTaskThread;
@property (nonatomic, assign) int progressCount;
@property (nonatomic, assign) int progressCountTotal;
@property (nonatomic, assign) int currentPatchInstallIndex;

- (void)centerOurWindow;
- (void)awakeFromNib;
- (void)countDownToClose;

@end
