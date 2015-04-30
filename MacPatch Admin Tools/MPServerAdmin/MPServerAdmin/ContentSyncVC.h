//
//  ContentSyncVC.h
//  MPServerAdmin
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

@interface ContentSyncVC : NSViewController <NSTextViewDelegate>

@property (weak) IBOutlet NSTextField *masterHostName;
@property (weak) IBOutlet NSTextField *masterSyncInterval;
@property (weak) IBOutlet NSTextField *serviceStatusText1;
@property (weak) IBOutlet NSButton *serviceButton1;
@property (weak) IBOutlet NSImageView *serviceStatusImage1;
@property (weak) IBOutlet NSButton *startOnBootCheckBox1;

@property (weak) IBOutlet NSTextField *serviceStatusText2;
@property (weak) IBOutlet NSButton *serviceButton2;
@property (weak) IBOutlet NSImageView *serviceStatusImage2;
@property (weak) IBOutlet NSButton *startOnBootCheckBox2;

@property (assign) int serviceState1;
@property (assign) int serviceState2;

@property (weak) IBOutlet NSTextField *serviceConfText;
@property (weak) IBOutlet NSImageView *serviceConfImage;

// RSYNCD
@property (strong) IBOutlet NSTextView *hostsAllow;
@property (strong) IBOutlet NSTextView *hostsDeny;
@property (weak) IBOutlet NSTextField *maxConnextions;

- (IBAction)toggleSyncFromMasterService:(id)sender;
- (IBAction)toggleMasterServerSyncService:(id)sender;

@end
