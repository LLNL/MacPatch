//
//  DatabaseVC.m
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

#import "DatabaseVC.h"
#import "MPServerAdmin.h"
#import <ServiceManagement/ServiceManagement.h>
#import "Constants.h"
#import "Common.h"
#import "HelperTool.h"

@interface DatabaseVC () {
    MPServerAdmin *mpsa;
    BOOL _textChanged;
}

@property (strong) NSDictionary *dbConfig;
@property (strong) NSDictionary *dbConfigRO;

- (void)readDBSettings;

@end

@implementation DatabaseVC

@synthesize dbConfig = _dbConfig;
@synthesize dbConfigRO = _dbConfigRO;

- (void)viewDidLoad
{
    [super viewDidLoad];
    mpsa = [MPServerAdmin sharedInstance];
    
    _textChanged = FALSE;
    
    [self readDBSettings];
}

- (void)viewDidAppear
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd:)
                                                 name:NSControlTextDidEndEditingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidChange:)
                                                 name:NSControlTextDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:)
                                                 name:NSTextDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:)
                                                 name:NSTextDidEndEditingNotification
                                               object:nil];
    
    [self readDBSettings];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Main

- (void)readDBSettings
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
             }] readDBConf:mpsa.authorization withReply:^(NSError * commandError, NSDictionary *dbDict) {
                 if (commandError != nil) {
                     NSLog(@"Error: %@",commandError.localizedDescription);
                 } else {
                     if ([dbDict objectForKey:@"prod"]) {
                         NSDictionary *prd = [dbDict objectForKey:@"prod"];
                         self.dbHostName.stringValue = [prd objectForKey:@"dbHost"] ? : @"localhost";
                         self.dbPort.stringValue = [prd objectForKey:@"dbPort"] ? : @"3306";
                         self.dbName.stringValue = [prd objectForKey:@"dbName"] ? : @"MacPatchDB";
                         self.dbUser.stringValue = [prd objectForKey:@"username"] ? : @"mpdbadm";
                         self.dbUserPass.stringValue = [prd objectForKey:@"password"] ? : @"";
                         self.dbMaxConnections.stringValue = [prd objectForKey:@"maxconnections"] ? : @"500";
                     }
                     if ([dbDict objectForKey:@"ro"]) {
                         NSDictionary *ro = [dbDict objectForKey:@"ro"];
                         self.dbUserRO.stringValue = [ro objectForKey:@"username"];
                         self.dbUserROPass.stringValue = [ro objectForKey:@"password"] ? : @"";
                     }
                 }
                 
                 dispatch_async(dispatch_get_main_queue(),^{[self.view display];});
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
        NSMutableDictionary *database = [NSMutableDictionary new];
        NSMutableDictionary *prdDict = [NSMutableDictionary new];
        [prdDict setObject:self.dbHostName.stringValue forKey:@"dbHost"];
        [prdDict setObject:self.dbPort.stringValue forKey:@"dbPort"];
        [prdDict setObject:self.dbName.stringValue forKey:@"dbName"];
        [prdDict setObject:self.dbUser.stringValue forKey:@"username"];
        [prdDict setObject:self.dbUserPass.stringValue forKey:@"password"];
        [prdDict setObject:self.dbMaxConnections.stringValue forKey:@"maxconnections"];
        [database setObject:prdDict forKey:@"prod"];
        
        NSMutableDictionary *roDict = [NSMutableDictionary new];
        [roDict setObject:self.dbHostName.stringValue forKey:@"dbHost"];
        [roDict setObject:self.dbPort.stringValue forKey:@"dbPort"];
        [roDict setObject:self.dbName.stringValue forKey:@"dbName"];
        [roDict setObject:self.dbUserRO.stringValue forKey:@"username"];
        [roDict setObject:self.dbUserROPass.stringValue forKey:@"password"];
        [database setObject:roDict forKey:@"ro"];
        
        [mpsa connectAndExecuteCommandBlock:^(NSError * connectError)
         {
             if (connectError != nil) {
                 NSLog(@"Error: %@",connectError.localizedDescription);
             } else {
                 [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                     NSLog(@"Error: %@",proxyError.localizedDescription);
                 }] writeDBConf:mpsa.authorization dbConf:database withReply:^(NSError * commandError, NSString *licenseKey) {
                     if (commandError != nil) {
                         NSLog(@"Error: %@",commandError.localizedDescription);
                     } else {
                         //NSLog(@"%@",licenseKey);
                     }
                 }];
             }
         }];
        
        _textChanged = FALSE;
    }
}

- (void)textDidChange:(NSNotification *)notification
{
    _textChanged = TRUE;
}

- (void)textDidEndEditing:(NSNotification *)notification
{
   
}

@end
