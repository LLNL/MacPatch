//
//  MinScanAndPatchVC.h
//  MPLoginAgent
//
//  Created by Charles Heizer on 6/30/17.
//  Copyright © 2017 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPScanner.h"
#import "MPPatchScan.h"
#import "InstallAppleUpdate.h"

@interface MinScanAndPatchVC : NSViewController <NSTableViewDelegate,MPScannerDelegate,MPPatchScanDelegate,InstallAppleUpdateDelegate>
{
    NSFileManager                   *fm;
    MPScanner                       *mpScanner;
    
    // Main Window
    IBOutlet NSImageView            *logoImageView;
    IBOutlet NSButton               *cancelButton;
    
    NSThread                        *taskThread;
    BOOL                            killTaskThread;
    
    // Status
    IBOutlet NSTextField            *progressText;
    IBOutlet NSTextField            *progressCountText;
    IBOutlet NSProgressIndicator    *progressBar;
    IBOutlet NSTextField            *installStatusText;
    
    int                             progressCount;
    int                             progressCountTotal;
    
}

@property (nonatomic, strong) NSThread *taskThread;
@property (nonatomic, assign) BOOL killTaskThread;
@property (nonatomic, assign) BOOL cancelTask;

@property (nonatomic, assign) int progressCount;
@property (nonatomic, assign) int progressCountTotal;

@end
