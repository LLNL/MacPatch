//
//  ApplePatchSyncVC.m
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

#import "ApplePatchSyncVC.h"
#import "MPServerAdmin.h"
#import "SUSCatalog.h"
#import <ServiceManagement/ServiceManagement.h>
#import "Constants.h"
#import "Common.h"
#import "HelperTool.h"

#define SRVS_ON         @"Service is running."
#define SRVS_OFF        @"Service is not running."

@interface ApplePatchSyncVC () {
    BOOL                _textChanged;
    MPServerAdmin       *mpsa;
}

- (void)showServiceState;
- (void)readLaunchDFile;
- (void)checkServiceState;

@end

@implementation ApplePatchSyncVC

@synthesize serviceState = _serviceState;

- (void)viewDidLoad
{
    [super viewDidLoad];
    mpsa = [MPServerAdmin sharedInstance];
    
    [self checkServiceState];
    catalogs = [[NSMutableArray alloc] init];
    
    _textChanged = FALSE;
    _serviceButton.title = @"Start Service";
    _serviceState = -1;
}

- (void)viewDidAppear
{
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd:)
                                                 name:NSControlTextDidEndEditingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidChange:)
                                                 name:NSControlTextDidChangeNotification object:nil];
    
    [self checkServiceState];
    [self showServiceState];
    [self readLaunchDFile];
    [self readSUSConf];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [catalogs count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ((cTableView == nil) || ([[tableColumn identifier] length] == 0))
        return nil;
    
    SUSCatalog *s = [catalogs objectAtIndex:row];
    NSString *colID = [tableColumn identifier];
    return [s valueForKey:colID];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    
    NSString *colID = [tableColumn identifier];
    if ([colID length] == 0)
        return;
    
    SUSCatalog *s = [catalogs objectAtIndex:rowIndex];
    [s setValue:value forKey:colID];
    
    if (_textChanged == TRUE)
    {
        NSMutableDictionary *cDict = [[NSMutableDictionary alloc] init];
        NSMutableArray *cats = [[NSMutableArray alloc] init];
        for (SUSCatalog *s in catalogs) {
            [cats addObject:[s returnAsDictionary]];
        }
        [cDict setObject:cats forKey:@"Catalogs"];
        [cDict setObject:self.susServerField.stringValue forKey:@"ASUSServer"];
        [cDict setObject:self.hostField.stringValue forKey:@"MPServerAddress"];
        [cDict setObject:self.portField.stringValue forKey:@"MPServerPort"];
        BOOL enabled = [self.useSSLCheckBox state] == NSOnState;
        [cDict setObject:[NSNumber numberWithBool:enabled] forKey:@"MPServerUseSSL"];
        
        BOOL enabled1 = [self.startOnBootCheckBox state] == NSOnState;
        NSDictionary *lDict = @{@"RunAtLoad": [NSNumber numberWithBool:enabled1],@"StartInterval": [NSNumber numberWithInt:[self.intervalField.stringValue intValue]]};
        
        [self writeConfChanges:cDict launchdConf:lDict];
    }
}

- (IBAction)addRow:(id)sender
{
    [catalogs addObject:[[SUSCatalog alloc] init]];
    [cTableView reloadData];
}

- (IBAction)deleteRow:(id)sender
{
    NSInteger row = [cTableView selectedRow];
    [cTableView abortEditing];
    if (row != -1) {
        [catalogs removeObjectAtIndex:row];
    }
    [cTableView reloadData];
}

#pragma mark - Main
- (void)showServiceState
{
    NSArray *jobs = (__bridge NSArray *)SMCopyAllJobDictionaries(kSMDomainSystemLaunchd);
    if (!jobs) {
        return;
    }
    for (NSDictionary *s in jobs)
    {
        if ([[s objectForKey:@"Label"] isEqualToString:SERVICE_SUS])
        {
            if (![s objectForKey:@"PID"])
            {
                _serviceStatusText.stringValue = SRVS_OFF;
                _serviceState = 0;
                _serviceButton.title = @"Start Service";
                _serviceStatusImage.image = [NSImage imageNamed:@"NSStatusUnavailable"];
            } else {
                _serviceStatusText.stringValue = SRVS_ON;
                _serviceState = 1;
                _serviceButton.title = @"Stop Service";
                _serviceStatusImage.image = [NSImage imageNamed:@"NSStatusAvailable"];
            }
            break;
        } else {
            _serviceStatusText.stringValue = SRVS_OFF;
            _serviceState = 0;
            _serviceButton.title = @"Start Service";
            _serviceStatusImage.image = [NSImage imageNamed:@"NSStatusUnavailable"];
        }
    }
}

- (IBAction)toggleService:(id)sender
{
    _serviceButton.enabled = FALSE;
    NSInteger onOff = 0;
    if ([self.startOnBootCheckBox state] == NSOnState) {
        onOff = 1;
    }
    
    [mpsa connectAndExecuteCommandBlock:^(NSError * connectError)
     {
         if (connectError != nil)
         {
             NSLog(@"Error: %@",connectError.localizedDescription);
         }
         else
         {
             // If Service State is Off
             if (_serviceState == 0) {
                 [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                     NSLog(@"Error: %@",proxyError.localizedDescription);
                 }] startSUSService:mpsa.authorization  startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
                     if (commandError != nil) {
                         NSLog(@"Error: %@",commandError.localizedDescription);
                         _serviceButton.enabled = TRUE;
                     } else {
                         //NSLog(@"license = %@\n", licenseKey);
                         [NSThread sleepForTimeInterval:5.0];
                         [self showServiceState];
                         _serviceButton.enabled = TRUE;
                     }
                 }];
             } else {
                 [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                     NSLog(@"Error: %@",proxyError.localizedDescription);
                 }] stopSUSService:mpsa.authorization startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
                     if (commandError != nil) {
                         NSLog(@"Error: %@",commandError.localizedDescription);
                         _serviceButton.enabled = TRUE;
                     } else {
                         //NSLog(@"license = %@\n", licenseKey);
                         [NSThread sleepForTimeInterval:5.0];
                         [self showServiceState];
                         _serviceButton.enabled = TRUE;
                     }
                 }];
             }
         }
     }];
    
    [self showServiceState];
}

- (void)readLaunchDFile
{
    __block NSDictionary *d;
    [mpsa connectAndExecuteCommandBlock:^(NSError * connectError)
     {
         if (connectError != nil)
         {
             NSLog(@"Error: %@",connectError.localizedDescription);
         }
         else
         {
             [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                 NSLog(@"Error: %@",proxyError.localizedDescription);
             }] readLaunchDFile:LAUNCHD_SUS_FILE withReply:^(NSDictionary *dict) {
                 d = [dict copy];
                 if ([d objectForKey:@"RunAtLoad"])
                 {
                     if ([[d objectForKey:@"RunAtLoad"] boolValue])
                         [self.startOnBootCheckBox setState:([[d objectForKey:@"RunAtLoad"] boolValue] ? NSOnState:NSOffState)];
                 }
                 if ([d objectForKey:@"StartInterval"])
                     self.intervalField.stringValue = [[d objectForKey:@"StartInterval"] stringValue];
             }];
         }
     }];
}

- (void)readSUSConf
{
    [mpsa connectAndExecuteCommandBlock:^(NSError * connectError)
     {
         if (connectError != nil)
         {
             NSLog(@"Error: %@",connectError.localizedDescription);
         }
         else
         {

             [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                 NSLog(@"Error: %@",proxyError.localizedDescription);
             }] readSUSConf:mpsa.authorization withReply:^(NSError * commandError, NSDictionary *susDict) {
                 if (commandError != nil) {
                     NSLog(@"Error: %@",commandError.localizedDescription);
                 } else {
                     if ([susDict objectForKey:@"ASUSServer"])
                         self.susServerField.stringValue = [susDict objectForKey:@"ASUSServer"];
                     
                     if ([susDict objectForKey:@"MPServerAddress"])
                         self.hostField.stringValue = [susDict objectForKey:@"MPServerAddress"];
                     
                     if ([susDict objectForKey:@"MPServerPort"])
                         self.portField.stringValue = [susDict objectForKey:@"MPServerPort"];
                     
                     if ([susDict objectForKey:@"MPServerUseSSL"]) {
                         BOOL useSSL = [[susDict objectForKey:@"MPServerUseSSL"] boolValue];
                         [self.useSSLCheckBox setState:(useSSL? NSOnState : NSOffState)];
                     }

                     if ([susDict objectForKey:@"Catalogs"])
                     {
                         if ([[susDict objectForKey:@"Catalogs"] isKindOfClass:[NSArray class]])
                         {
                             // Empty the array
                             [catalogs removeAllObjects];
                             
                             for (NSDictionary *s in [susDict objectForKey:@"Catalogs"]) {
                                 SUSCatalog *sus = [[SUSCatalog alloc] init];
                                 sus.catalogurl = [s objectForKey:@"catalogurl"];
                                 sus.osver = [s objectForKey:@"osver"];
                                 [catalogs addObject:sus];
                             }
                             
                             dispatch_async(dispatch_get_main_queue(),^{[cTableView reloadData];});
                         }
                     }
                 }
             }];
         }
     }];
}

- (void)writeConfChanges:(NSDictionary *)aConf launchdConf:(NSDictionary *)lConf
{
    [mpsa connectAndExecuteCommandBlock:^(NSError * connectError)
     {
         if (connectError != nil)
         {
             NSLog(@"Error: %@",connectError.localizedDescription);
         }
         else
         {
             
             [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                 NSLog(@"Error: %@",proxyError.localizedDescription);
             }] writeSUSConf:mpsa.authorization susConf:aConf launchDConf:lConf withReply:^(NSError * commandError, NSString *licenseKey) {
                 if (commandError != nil) {
                     NSLog(@"Error: %@",commandError.localizedDescription);
                 } else {
                    // NSLog(@"%@",licenseKey);
                 }
             }];
         }
     }];
}

#pragma mark - Notifications

// somewhere else in the .m file
- (void)editingDidChange:(NSNotification *)notification
{
    _textChanged = TRUE;
}

- (void)editingDidEnd:(NSNotification *)notification
{
    if (_textChanged == TRUE)
    {
        NSMutableDictionary *cDict = [[NSMutableDictionary alloc] init];
        NSMutableArray *cats = [[NSMutableArray alloc] init];
        for (SUSCatalog *s in catalogs) {
            [cats addObject:[s returnAsDictionary]];
        }
        [cDict setObject:cats forKey:@"Catalogs"];
        [cDict setObject:self.susServerField.stringValue forKey:@"ASUSServer"];
        [cDict setObject:self.hostField.stringValue forKey:@"MPServerAddress"];
        [cDict setObject:self.portField.stringValue forKey:@"MPServerPort"];
        BOOL enabled = [self.useSSLCheckBox state] == NSOnState;
        [cDict setObject:[NSNumber numberWithBool:enabled] forKey:@"MPServerUseSSL"];
        
        BOOL enabled1 = [self.startOnBootCheckBox state] == NSOnState;
        NSDictionary *lDict = @{@"RunAtLoad": [NSNumber numberWithBool:enabled1],@"StartInterval": [NSNumber numberWithInt:[self.intervalField.stringValue intValue]]};
        
        [self writeConfChanges:cDict launchdConf:lDict];
        _textChanged = FALSE;
    }
}

- (void)checkServiceState
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:SUS_SYNC_FILE] == NO) {
        self.serviceConfText.stringValue = @"Could not locate ASUS Sync script.";
        self.serviceConfText.hidden = NO;
        self.serviceConfImage.hidden = NO;
        self.serviceButton.enabled = NO;
    } else {
        self.serviceConfText.hidden = YES;
        self.serviceConfImage.hidden = YES;
        self.serviceButton.enabled = YES;
    }
}

@end
