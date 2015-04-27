//
//  AuthenticationVC.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 4/13/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AuthenticationVC : NSViewController <NSTextViewDelegate>

@property (weak) IBOutlet NSTextField *notifyString;
@property (weak) IBOutlet NSTextField *host;
@property (weak) IBOutlet NSTextField *port;
@property (weak) IBOutlet NSTextField *searchBase;
@property (weak) IBOutlet NSTextField *attributes;
@property (weak) IBOutlet NSTextField *loginAttributes;
@property (weak) IBOutlet NSTextField *loginUserPrefix;
@property (weak) IBOutlet NSTextField *loginUserSuffix;
@property (weak) IBOutlet NSPopUpButton *secureConnection;
@property (weak) IBOutlet NSButton *enableLDAP;

@end
