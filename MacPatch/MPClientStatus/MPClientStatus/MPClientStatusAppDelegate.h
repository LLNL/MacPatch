//
//  MPClientStatusAppDelegate.h
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
#import "MPWorkerProtocol.h"

@class MPDefaults, MPAsus, MPSoap, MPAppUsage, ASIHTTPRequest;
@class MPServerConnection;

@interface MPClientStatusAppDelegate : NSObject <MPWorkerClient>
{
	NSWindow *window;
    
    // Helper
	id       proxy;
	
	// Status Menu
	IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
	IBOutlet NSMenuItem *checkInStatusMenuItem;
	IBOutlet NSMenuItem *checkPatchStatusMenuItem;
	IBOutlet NSMenuItem *selfVersionInfoMenuItem;
	IBOutlet NSMenuItem *MPVersionInfoMenuItem;
	IBOutlet NSMenuItem *checkAgentAndUpdateMenuItem;
	BOOL	openASUS;
	BOOL	asusAlertOpen;
	
	// Client Info
	NSWindow *clientInfoWindow;
	IBOutlet NSTextField *clientInfoTextField;
	NSTableView *clientInfoTableView;
	NSArrayController *clientArrayController;
	
	// About Window
	NSWindow *aboutWindow;
	NSWindow *mpClientStatusAboutWindow;
	IBOutlet NSImageView *appIcon;
	IBOutlet NSTextField *appName;
	IBOutlet NSTextField *appVersion;
	
	// New CheckIn Methods
	NSOperationQueue *queue;
	NSURLConnection *showLastCheckInConnection;
	NSMutableData *showLastCheckInResultsData;
	
@private
	MPDefaults *defaults;
	MPAsus *asus;
	MPSoap *soap;
	MPAppUsage *mpAppUsage;
    MPServerConnection *mpServerConnection;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenuItem *checkInStatusMenuItem;
@property (assign) IBOutlet NSMenuItem *checkPatchStatusMenuItem;
@property (assign) IBOutlet NSMenuItem *selfVersionInfoMenuItem;
@property (assign) IBOutlet NSMenuItem *MPVersionInfoMenuItem;
@property (assign) IBOutlet NSMenuItem *checkAgentAndUpdateMenuItem;
@property (nonatomic, assign) BOOL openASUS;
@property (nonatomic, assign) BOOL asusAlertOpen;

// Client Info
@property (assign) IBOutlet NSWindow *clientInfoWindow;
@property (assign) IBOutlet NSTableView *clientInfoTableView;
@property (assign) IBOutlet NSArrayController *clientArrayController;

// About Window
@property (assign) IBOutlet NSWindow *aboutWindow;
@property (assign) IBOutlet NSImageView *appIcon;
@property (nonatomic, retain) IBOutlet NSTextField *appName;
@property (nonatomic, retain) IBOutlet NSTextField *appVersion;

// Client CheckIn String
@property (nonatomic, retain) NSOperationQueue *queue;

#pragma mark -
#pragma mark Methods

- (IBAction)getMPClientVersionInfo:(id)sender;
- (IBAction)closeClientInfoWindow:(id)sender;

// About Window
- (IBAction)showAboutWindow:(id)sender;

// Client Checkin
- (IBAction)showCheckinWindow:(id)sender;
- (void)performClientCheckInThread;
- (BOOL)performClientCheckInMethod;

// Checkin Data
- (NSDictionary *)systemVersionDictionary;
- (NSDictionary *)getOSInfo;
- (NSString *)getHostSerialNumber;

// Show Last CheckIn Info
- (void)showLastCheckIn;
- (void)showLastCheckInThread;
- (void)showLastCheckInMethod;
- (void)lastCheckInDone:(ASIHTTPRequest *)request;
- (void)lastCheckInFailed:(ASIHTTPRequest *)request;

// Show Patch Status
- (void)getClientPatchStatus;
- (void)getClientPatchStatusThread;
- (void)getClientPatchStatusMethod;
- (void)clientPatchStatusDone:(ASIHTTPRequest *)request;
- (void)clientPatchStatusFailed:(ASIHTTPRequest *)request;

// Patch Status Icon Update, via File
- (void)updatePatchStatusThread;
- (void)updatePatchStatusMethod;

- (IBAction)openSelfPatchApplications:(id)sender;
- (IBAction)openSoftwareCatalogApplications:(id)sender;

// Kill SoftwareUpdate GUI App
- (void)notificationReceived:(NSNotification *)aNotification;
- (void)killApplication:(NSNumber *)aPID;
- (void)openSoftwareUpdateApplication:(id)sender;

// App Usage Info
- (void)appLaunchNotificationReceived:(NSNotification *)aNotification;

- (void)turnOffSoftwareUpdateSchedule;
- (void)checkAgentStatus:(id)sender;

@end

