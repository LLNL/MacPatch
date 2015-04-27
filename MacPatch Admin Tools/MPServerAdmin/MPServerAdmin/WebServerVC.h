//
//  WebServerVC.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/9/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WebServerVC : NSViewController

@property (weak) IBOutlet NSTextField *serviceStatusText;
@property (weak) IBOutlet NSButton *serviceButton;
@property (weak) IBOutlet NSImageView *serviceStatusImage;
@property (weak) IBOutlet NSButton *startOnBootCheckBox;

@property (assign) int serviceState;

@property (weak) IBOutlet NSTextField *serviceConfText;
@property (weak) IBOutlet NSImageView *serviceConfImage;

- (IBAction)toggleService:(id)sender;

@end
