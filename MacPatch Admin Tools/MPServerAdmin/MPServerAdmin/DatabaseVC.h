//
//  DatabaseVC.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/8/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DatabaseVC : NSViewController <NSTextViewDelegate>

@property (weak) IBOutlet NSTextField *dbHostName;
@property (weak) IBOutlet NSTextField *dbPort;
@property (weak) IBOutlet NSTextField *dbName;
@property (weak) IBOutlet NSTextField *dbUser;
@property (weak) IBOutlet NSTextField *dbUserRO;
@property (weak) IBOutlet NSTextField *dbMaxConnections;
@property (weak) IBOutlet NSSecureTextField *dbUserPass;
@property (weak) IBOutlet NSSecureTextField *dbUserROPass;

@end
