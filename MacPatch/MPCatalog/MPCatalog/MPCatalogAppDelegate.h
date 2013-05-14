//
//  MPCatalogAppDelegate.h
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
#import "MacPatch.h"
#import "MPDLWrapper.h"
#import "MPWorkerProtocol.h"

@class PreferenceController;
@class SWDistInfoController;
@class MPServerConnection;

@interface MPCatalogAppDelegate : NSObject <NSApplicationDelegate,MPDLWrapperController,MPWorkerClient, NSTabViewDelegate> 
{
    NSWindow *window;
	
	IBOutlet NSTableView			*tableView;
	IBOutlet NSArrayController		*arrayController;
	IBOutlet NSTextField			*statusTextTitle;
	IBOutlet NSTextField			*statusTextStatus;
	IBOutlet NSProgressIndicator	*progressBar;
	IBOutlet NSToolbarItem			*installButton;
	IBOutlet NSToolbarItem			*removeButton;
	IBOutlet NSToolbarItem			*cancelButton;
	IBOutlet NSToolbarItem			*refreshButton;
    IBOutlet NSToolbarItem			*infoButton;
    IBOutlet NSPopUpButton          *swDistGroupsButton;
    
    IBOutlet NSPanel                *rebootPanel;
    IBOutlet NSPanel                *swDistInfoPanel;

    MPServerConnection              *mpServerConnection;
	PreferenceController			*preferenceController;
    SWDistInfoController            *swDistInfoController;
    
    NSOperationQueue                *queue;
    NSMutableArray                  *selectedItems;
    NSArray                         *swDistGroupsArray;
    NSFileManager                   *fm;
    
    // Helper
	id                              proxy;

@private
    MPDLWrapper				*downloadTask;
	BOOL					isDownloading;
    BOOL                    cancelInstalls;
    NSDictionary            *_defaults;
    NSTableColumn           *_selectionColumn;
    BOOL                    tableColEdit;
    
    NSURL                   *mp_SOFTWARE_DATA_DIR;
    NSDictionary            *swDistInfoPanelDict;
    NSString                *swDistCurrentTitle;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSTableView			*tableView;
@property (nonatomic, retain) IBOutlet NSArrayController	*arrayController;
@property (nonatomic, retain) IBOutlet NSTextField			*statusTextTitle;
@property (nonatomic, retain) IBOutlet NSTextField			*statusTextStatus;
@property (nonatomic, retain) IBOutlet NSProgressIndicator	*progressBar;
@property (nonatomic, retain) IBOutlet NSToolbarItem		*installButton;
@property (nonatomic, retain) IBOutlet NSToolbarItem		*removeButton;
@property (nonatomic, retain) IBOutlet NSToolbarItem		*cancelButton;
@property (nonatomic, retain) IBOutlet NSToolbarItem		*refreshButton;
@property (nonatomic, retain) IBOutlet NSToolbarItem		*infoButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton		*swDistGroupsButton;
@property (nonatomic, retain)          NSOperationQueue     *queue;
@property (nonatomic, retain)          NSMutableArray       *selectedItems;
@property (nonatomic, retain)          NSArray              *swDistGroupsArray;

@property (nonatomic, retain) IBOutlet NSPanel              *rebootPanel;
@property (nonatomic, retain) IBOutlet NSPanel              *swDistInfoPanel;

@property (nonatomic, assign) BOOL                          cancelInstalls;
@property (nonatomic, retain)          NSDictionary         *_defaults;
@property (nonatomic, retain) IBOutlet NSTableColumn        *_selectionColumn;
@property (nonatomic, assign) BOOL                          tableColEdit;
@property (nonatomic, retain)          NSURL                *mp_SOFTWARE_DATA_DIR;
@property (nonatomic, retain)          NSDictionary         *swDistInfoPanelDict;
@property (nonatomic, retain)          NSString             *swDistCurrentTitle;

- (IBAction)showRebootPanel:(id)sender;
- (IBAction)showPreferencePanel:(id)sender;

- (IBAction)installSoftware:(id)sender;
- (IBAction)checkboxChanged:(id)sender;
- (IBAction)removeSoftware:(id)sender;
- (IBAction)refreshSoftware:(id)sender;
- (IBAction)cancelSoftware:(id)sender;

// Test Actions
- (IBAction)getSoftwareDataFromFile:(id)sender;

@end
