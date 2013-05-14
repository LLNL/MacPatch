//
//  MPPatchLoaderConfAppDelegate.h
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

@class MPManager;

@interface MPPatchLoaderConfAppDelegate : NSObject <NSApplicationDelegate> {
@private
	NSWindow *window;
	IBOutlet NSTextField *mpSrvName;
	IBOutlet NSTextField *mpSrvPort;
	IBOutlet NSButton *useSSLCheckBox;
	IBOutlet NSTextField *asusSrvName;
	IBOutlet NSTextField *asusSrvPort;
	
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSButton *addNewCat;
	IBOutlet NSButton *removeCat;
	IBOutlet NSButton *saveButton;
	IBOutlet NSButton *clearButton;
	
	MPManager *sm;
	NSString  *confFile;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSTextField *mpSrvName;
@property (nonatomic, retain) IBOutlet NSTextField *mpSrvPort;
@property (nonatomic, retain) IBOutlet NSButton *useSSLCheckBox;
@property (nonatomic, retain) IBOutlet NSTextField *asusSrvName;
@property (nonatomic, retain) IBOutlet NSTextField *asusSrvPort;
@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain) IBOutlet NSButton *addNewCat;
@property (nonatomic, retain) IBOutlet NSButton *removeCat;
@property (nonatomic, retain) IBOutlet NSButton *saveButton;
@property (nonatomic, retain) IBOutlet NSButton *clearButton;

@property (nonatomic, retain) NSString *confFile;

- (IBAction)populateFieldsFromFile:(id)sender;
- (void)openFilePanel;
- (void)populateFields;

@end
