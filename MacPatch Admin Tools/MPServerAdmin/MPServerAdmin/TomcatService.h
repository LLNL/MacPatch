//
//  TomcatService.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/21/16.
//  Copyright © 2016 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TomcatService : NSViewController <NSTextFieldDelegate>

@property (weak) IBOutlet NSTextField *serviceStatusText;
@property (weak) IBOutlet NSButton *serviceButton;
@property (weak) IBOutlet NSImageView *serviceStatusImage;
@property (weak) IBOutlet NSButton *startOnBootCheckBox;

@property (weak) IBOutlet NSButton *consoleServiceCheckBox;
@property (weak) IBOutlet NSButton *webServiceCheckBox;

@property (weak) IBOutlet NSTextField *serviceConfText;
@property (weak) IBOutlet NSImageView *serviceConfImage;

@property (assign) int serviceState;

- (IBAction)toggleService:(id)sender;
- (IBAction)openAdminConsole:(id)sender;

@end
