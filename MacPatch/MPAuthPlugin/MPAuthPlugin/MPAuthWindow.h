//
//  MPAuthWindow.h
//  MPAuthPlugin
//
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

@class MPDefaults;

@interface MPAuthWindow : NSWindow <MPWorkerClient,NSTableViewDelegate>
{
    NSPoint initialLocation;
    BOOL fullscreen;
    MPDefaults *mpDefauts;

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

@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *title;
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
