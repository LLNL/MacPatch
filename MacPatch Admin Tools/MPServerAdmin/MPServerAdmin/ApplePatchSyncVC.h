//
//  ApplePatchSyncVC.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/8/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ApplePatchSyncVC : NSViewController <NSTableViewDelegate, NSTableViewDataSource, NSTextViewDelegate>
{
    @private
    IBOutlet NSTableView *cTableView;
    NSMutableArray *catalogs;
}

@property (weak) IBOutlet NSTextField *susServerField;
@property (weak) IBOutlet NSTextField *hostField;
@property (weak) IBOutlet NSTextField *portField;
@property (weak) IBOutlet NSTextField *intervalField;
@property (weak) IBOutlet NSTextField *serviceStatusText;
@property (weak) IBOutlet NSButton *serviceButton;
@property (weak) IBOutlet NSImageView *serviceStatusImage;
@property (weak) IBOutlet NSButton *useSSLCheckBox;
@property (weak) IBOutlet NSButton *startOnBootCheckBox;

@property (weak) IBOutlet NSTextField *serviceConfText;
@property (weak) IBOutlet NSImageView *serviceConfImage;

@property (assign) int serviceState;

- (IBAction)toggleService:(id)sender;

@end
