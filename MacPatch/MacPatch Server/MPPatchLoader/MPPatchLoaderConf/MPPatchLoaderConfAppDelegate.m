//
//  MPPatchLoaderConfAppDelegate.m
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

#import "MPPatchLoaderConfAppDelegate.h"
#import "NSFileManager+DirectoryLocations.h"
#import "MPManager.h"

#define	MP_ROOT		@"/Library/MacPatch"
#define	MP_SRV_ROOT	@"/Library/MacPatch/Server"


@implementation MPPatchLoaderConfAppDelegate

@synthesize mpSrvName;
@synthesize mpSrvPort;
@synthesize useSSLCheckBox;
@synthesize asusSrvName;
@synthesize asusSrvPort;
@synthesize arrayController;
@synthesize addNewCat;
@synthesize removeCat;
@synthesize saveButton;
@synthesize clearButton;

@synthesize confFile;

- (void)awakeFromNib 
{
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	sm = [MPManager sharedManager];
	confFile = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutablePath"] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"gov.llnl.mp.patchloader.plist"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:confFile]) {
		[sm setG_Defaults:[NSDictionary dictionaryWithContentsOfFile:confFile]];
	} else {
		[self openFilePanel];
	}
	[self populateFields];
}

- (void)openFilePanel
{
	// Create the File Open Dialog class.
	NSOpenPanel *openDlg = [NSOpenPanel openPanel];
	
	// Enable the selection of files in the dialog.
	[openDlg setCanChooseFiles:YES];
	
	// Enable the selection of directories in the dialog.
	[openDlg setCanChooseDirectories:NO];
	[openDlg setAllowsMultipleSelection:NO];

	// Display the dialog.
	if ( [openDlg runModalForDirectory:MP_ROOT file:nil types:[NSArray arrayWithObject:@"plist"]] == NSOKButton )
	{
		NSString *errorDesc = nil;
		NSPropertyListFormat format;
		NSData *pData = [NSData dataWithContentsOfFile:[openDlg filename]];
		NSDictionary *sucatalogPlist = [NSPropertyListSerialization propertyListFromData:pData
																		mutabilityOption:NSPropertyListImmutable
																				  format:&format
																		errorDescription:&errorDesc];
		NSLog(@"Error: %@",errorDesc);
		[sm setG_Defaults:[NSDictionary dictionaryWithDictionary:sucatalogPlist]];
	}
}

- (IBAction)populateFieldsFromFile:(id)sender
{
	[self openFilePanel];
	[self populateFields];
}

- (void)populateFields
{
	NSDictionary *x = [NSDictionary dictionaryWithDictionary:[sm g_Defaults]];
	if ([x objectForKey:@"MPServerAddress"])
		[mpSrvName setStringValue:[x objectForKey:@"MPServerAddress"]];
	if ([x objectForKey:@"MPServerPort"])
		[mpSrvPort setStringValue:[x objectForKey:@"MPServerPort"]];
	if ([x objectForKey:@"MPServerUseSSL"]) {
		if ([[x objectForKey:@"MPServerUseSSL"] booleanValue] == YES) {
			[useSSLCheckBox setState:NSOnState];
		} else {
			[useSSLCheckBox setState:NSOffState];
		}
	} else {
		[useSSLCheckBox setState:NSOffState];
	}
		
	if ([x objectForKey:@"ASUSServer"]) {
		NSURL *xURL = [NSURL URLWithString:[x objectForKey:@"ASUSServer"]];
		[asusSrvName setStringValue:[xURL host]];
		[asusSrvPort setStringValue:[xURL port]];
	}	
}


@end
