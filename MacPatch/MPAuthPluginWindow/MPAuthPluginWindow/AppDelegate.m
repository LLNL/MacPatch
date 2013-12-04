//
//  AppDelegate.m
//  MPAuthPluginWindow
//
//  Created by Heizer, Charles on 10/30/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "AppDelegate.h"
#import "AuthPluginController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    authPluginController = [[AuthPluginController alloc] init];
    [authPluginController showWindow:self];
}

@end
