//
//  MPRebootAppDelegate.h
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
#import "EventToSend.h"

extern NSString * const kRBPatchTitle;
extern NSString * const kRBPatchBody;
extern NSString * const kRBSWInstallTitle;
extern NSString * const kRBSWInstallBody;
extern NSString * const kRBPatchAlertTitle;
extern NSString * const kRBPatchAlertBody;
extern NSString * const kRBSWInstallAlertTitle;
extern NSString * const kRBSWInstallAlertBody;


@interface AppDelegate : NSObject {
    NSWindow *window;
	BOOL _confirmed;
    BOOL isPatchReboot;
    
    IBOutlet NSTextField *wTitle;
    IBOutlet NSTextField *wBody;
}

@property (nonatomic, assign) BOOL _confirmed;
@property (nonatomic, assign) BOOL isPatchReboot;

@property (nonatomic, strong) IBOutlet NSTextField *wTitle;
@property (nonatomic, strong) IBOutlet NSTextField *wBody;

- (IBAction)logoutNowButton:(id)sender;
- (IBAction)confirmAppTerminate:(id)sender;

- (void)quitAppAndMakeUserLogout;
- (void)terminateSelfIfAlreadyRunning;

@end
