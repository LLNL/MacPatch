//
//  AppDelegate.h
//  MPServerAdmin
//
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


@class TomcatService;
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
@property (assign) IBOutlet TomcatService *tomcatService;
@property (assign) IBOutlet AdminServiceVC *adminServiceVC;
@property (assign) IBOutlet WebServiceVC *webServiceVC;
@property (assign) IBOutlet ApplePatchSyncVC *applePatchSyncVC;
@property (assign) IBOutlet ContentSyncVC *contentSyncVC;
@property (assign) IBOutlet AVSyncVC *avSyncVC;
@property (assign) IBOutlet DatabaseVC *databaseVC;
@property (assign) IBOutlet WebServerVC *webServerVC;
@property (assign) IBOutlet AuthenticationVC *authenticationVC;

@end

