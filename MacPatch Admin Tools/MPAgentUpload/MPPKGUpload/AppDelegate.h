//
//  AppDelegate.h
/*
 Copyright (c) 2013, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.

 This file is part of MacPatch, a program for installing and patching
 software.

 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.

 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.

 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import <Cocoa/Cocoa.h>

@class PreferenceController;

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
    // Options
    __weak NSTextField *identityName;
    __weak NSButton *signPKG;

    IBOutlet NSPanel *authSheet;
    __weak NSTextField *authUserName;
    __weak NSSecureTextField *authUserPass;
    __weak NSTextField *authStatus;
    __weak NSProgressIndicator *authProgressWheel;
    __weak NSButton *authRequestButton;
    
    PreferenceController *preferenceController;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *chooseButton;
@property (weak) IBOutlet NSButton *uploadButton;
@property (weak) IBOutlet NSTextField *packagePathField;
@property (weak) IBOutlet NSTextField *pluginsPathField;
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
@property (weak) IBOutlet NSTextField *postPkgTitle;
@property (weak) IBOutlet NSTextField *postPkgStatus;

@property (weak) IBOutlet NSTextField *identityName;
@property (weak) IBOutlet NSButton *signPKG;



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
