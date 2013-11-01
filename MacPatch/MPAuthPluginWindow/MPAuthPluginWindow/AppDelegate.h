//
//  AppDelegate.h
//  MPAuthPluginWindow
//
//  Created by Heizer, Charles on 10/30/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AuthPluginController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    AuthPluginController *authPluginController;
}
@property (assign) IBOutlet NSWindow *window;

@end
