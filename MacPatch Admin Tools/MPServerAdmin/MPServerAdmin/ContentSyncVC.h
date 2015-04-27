//
//  ContentSyncVC.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/8/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ContentSyncVC : NSViewController <NSTextViewDelegate>

@property (weak) IBOutlet NSTextField *masterHostName;
@property (weak) IBOutlet NSTextField *masterSyncInterval;
@property (weak) IBOutlet NSTextField *serviceStatusText1;
@property (weak) IBOutlet NSButton *serviceButton1;
@property (weak) IBOutlet NSImageView *serviceStatusImage1;
@property (weak) IBOutlet NSButton *startOnBootCheckBox1;

@property (weak) IBOutlet NSTextField *serviceStatusText2;
@property (weak) IBOutlet NSButton *serviceButton2;
@property (weak) IBOutlet NSImageView *serviceStatusImage2;
@property (weak) IBOutlet NSButton *startOnBootCheckBox2;

@property (assign) int serviceState1;
@property (assign) int serviceState2;

@property (weak) IBOutlet NSTextField *serviceConfText;
@property (weak) IBOutlet NSImageView *serviceConfImage;

// RSYNCD
@property (strong) IBOutlet NSTextView *hostsAllow;
@property (strong) IBOutlet NSTextView *hostsDeny;
@property (weak) IBOutlet NSTextField *maxConnextions;

- (IBAction)toggleSyncFromMasterService:(id)sender;
- (IBAction)toggleMasterServerSyncService:(id)sender;

@end
