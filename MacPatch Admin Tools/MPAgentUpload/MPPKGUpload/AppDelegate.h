//
//  AppDelegate.h
//  MPPKGUpload
//
//  Created by Heizer, Charles on 4/16/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSURLSessionDelegate>
{
    NSFileManager *fm;
    __weak NSImageView *extractImage;
    __weak NSImageView *agentConfigImage;
    __weak NSImageView *writeConfigImage;
    __weak NSImageView *flattenPackagesImage;
    __weak NSImageView *compressPackgesImage;
    __weak NSImageView *postPackagesImage;
    __weak NSProgressIndicator *progressBar;
    __weak NSTextField *serverAddress;
    __weak NSTextField *serverPort;
    __weak NSButton *useSSL;
    __weak NSTextField *extratContentsStatus;
    __weak NSTextField *getAgentConfStatus;
    __weak NSTextField *writeConfStatus;
    __weak NSTextField *flattenPkgStatus;
    __weak NSTextField *compressPkgStatus;
    __weak NSTextField *postPkgStatus;
    __weak NSButton *uploadButton;

    IBOutlet NSPanel *authSheet;
    __weak NSTextField *authUserName;
    __weak NSSecureTextField *authUserPass;
    __weak NSTextField *authStatus;
    __weak NSProgressIndicator *authProgressWheel;
    __weak NSButton *authRequestButton;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *chooseButton;
@property (weak) IBOutlet NSButton *uploadButton;
@property (weak) IBOutlet NSTextField *packagePathField;
@property (weak) IBOutlet NSImageView *extractImage;
@property (weak) IBOutlet NSImageView *agentConfigImage;
@property (weak) IBOutlet NSImageView *writeConfigImage;
@property (weak) IBOutlet NSImageView *flattenPackagesImage;
@property (weak) IBOutlet NSImageView *compressPackgesImage;
@property (weak) IBOutlet NSImageView *postPackagesImage;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *serverAddress;
@property (weak) IBOutlet NSTextField *serverPort;
@property (weak) IBOutlet NSButton *useSSL;

@property (weak) IBOutlet NSTextField *extratContentsStatus;
@property (weak) IBOutlet NSTextField *getAgentConfStatus;
@property (weak) IBOutlet NSTextField *writeConfStatus;
@property (weak) IBOutlet NSTextField *flattenPkgStatus;
@property (weak) IBOutlet NSTextField *compressPkgStatus;
@property (weak) IBOutlet NSTextField *postPkgStatus;



@property (nonatomic, strong) NSString *tmpDir;
@property (nonatomic, strong) NSString *agentID;
@property (nonatomic, strong) NSDictionary *agentDict;
@property (nonatomic, strong) NSDictionary *updaterDict;

@property (nonatomic, strong) NSString *authToken;
@property (weak) IBOutlet NSTextField *authUserName;
@property (weak) IBOutlet NSSecureTextField *authUserPass;
@property (weak) IBOutlet NSTextField *authStatus;
@property (weak) IBOutlet NSProgressIndicator *authProgressWheel;
@property (weak) IBOutlet NSButton *authRequestButton;

@end
