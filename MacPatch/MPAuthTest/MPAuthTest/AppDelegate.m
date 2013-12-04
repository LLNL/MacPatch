//
//  AppDelegate.m
//  MPAuthTest
//
//  Created by Heizer, Charles on 10/31/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "AppDelegate.h"
#import "AuthPluginController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    authPluginController = [[AuthPluginController alloc] initWithWindowNibName:@"AuthPluginController"];
    [authPluginController showWindow:self];
}

@end
