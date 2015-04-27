//
//  AppDelegate.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/7/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class AdminServiceVC;
@class WebServiceVC;
@class ApplePatchSyncVC;
@class ContentSyncVC;
@class AVSyncVC;
@class DatabaseVC;
@class WebServerVC;
@class AuthenticationVC;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTabViewDelegate>

@property (assign) IBOutlet NSTabView *tabView;
@property (assign) IBOutlet AdminServiceVC *adminServiceVC;
@property (assign) IBOutlet WebServiceVC *webServiceVC;
@property (assign) IBOutlet ApplePatchSyncVC *applePatchSyncVC;
@property (assign) IBOutlet ContentSyncVC *contentSyncVC;
@property (assign) IBOutlet AVSyncVC *avSyncVC;
@property (assign) IBOutlet DatabaseVC *databaseVC;
@property (assign) IBOutlet WebServerVC *webServerVC;
@property (assign) IBOutlet AuthenticationVC *authenticationVC;

@end

