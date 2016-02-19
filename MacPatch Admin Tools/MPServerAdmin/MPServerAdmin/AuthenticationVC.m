//
//  AuthenticationVC.m
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

#import "AuthenticationVC.h"
#import "MPServerAdmin.h"
#import <ServiceManagement/ServiceManagement.h>
#import "Constants.h"
#import "Common.h"
#import "HelperTool.h"

@interface AuthenticationVC () {
    MPServerAdmin *mpsa;
    BOOL _textChanged;
}

@property (strong) NSDictionary *dbConfig;
@property (strong) NSDictionary *dbConfigRO;

- (void)readLDAPSettings;

@end

@implementation AuthenticationVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mpsa = [MPServerAdmin sharedInstance];
    
    _textChanged = FALSE;
    
    [self readLDAPSettings];
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
    
    [self readLDAPSettings];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Main

- (void)readLDAPSettings
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
             }] readLDAPConf:mpsa.authorization withReply:^(NSError * commandError, NSDictionary *ldapDict) {
                 if (commandError != nil) {
                     NSLog(@"Error: %@",commandError.localizedDescription);
                 } else {
                     
                     self.host.stringValue = [ldapDict objectForKey:@"server"] ? : @"localhost";
                     self.port.stringValue = [ldapDict objectForKey:@"port"] ? : @"389";
                     self.searchBase.stringValue = [ldapDict objectForKey:@"searchbase"] ? : @"";
                     self.attributes.stringValue = [ldapDict objectForKey:@"attributes"] ? : @"givenname,initials,sn,mail,memberOf,dn,samAccountName,userPrincipalName";
                     self.loginAttributes.stringValue = [ldapDict objectForKey:@"loginAttr"] ? : @"userPrincipalName";
                     self.loginUserPrefix.stringValue = [ldapDict objectForKey:@"loginUsrPrefix"] ? : @"";
                     self.loginUserSuffix.stringValue = [ldapDict objectForKey:@"loginUsrSufix"] ? : @"";
                     if ([[[ldapDict objectForKey:@"enabled"] lowercaseString] isEqualToString:@"yes"]) {
                         [self.enableLDAP setState:NSOnState];
                     } else {
                         [self.enableLDAP setState:NSOffState];
                     }
                     if ([[[ldapDict objectForKey:@"secure"] uppercaseString] isEqualToString:@"CFSSL_BASIC"]) {
                         [self.secureConnection selectItemAtIndex:0]; // Yes
                         [self.notifyString setHidden:NO];
                     } else {
                         [self.secureConnection selectItemAtIndex:1]; // No
                         [self.notifyString setHidden:YES];
                     }
                 }
                 
                 dispatch_async(dispatch_get_main_queue(),^{[self.view display];});
             }];
         }
     }];
}

-(IBAction)enableState:(id)sender
{
    _textChanged = TRUE;
    NSNotification *note = [NSNotification notificationWithName:@"ChangedEnableState" object:nil];
    [self editingDidEnd:note];
}

-(IBAction)secureState:(id)sender
{
    _textChanged = TRUE;
    NSNotification *note = [NSNotification notificationWithName:@"ChangedSecureState" object:nil];
    [self editingDidEnd:note];
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
        NSMutableDictionary *lDict = [NSMutableDictionary new];
        [lDict setObject:self.host.stringValue forKey:@"server"];
        [lDict setObject:self.port.stringValue forKey:@"port"];
        [lDict setObject:self.searchBase.stringValue forKey:@"searchbase"];
        [lDict setObject:self.attributes.stringValue forKey:@"attributes"];
        [lDict setObject:self.loginAttributes.stringValue forKey:@"loginAttr"];
        [lDict setObject:self.loginUserPrefix.stringValue forKey:@"loginUsrPrefix"];
        [lDict setObject:self.loginUserSuffix.stringValue forKey:@"loginUsrSufix"];

        if ((int)[self.secureConnection indexOfSelectedItem] == 0) {
            [lDict setObject:@"CFSSL_BASIC" forKey:@"secure"]; //Yes
            [self.notifyString setHidden:NO];
        } else {
            [lDict setObject:@"" forKey:@"secure"]; //No
            [self.notifyString setHidden:YES];
        }
        
        if ([self.enableLDAP state] == NSOnState)
        {
            [lDict setObject:@"YES" forKey:@"enabled"];
        } else {
            [lDict setObject:@"NO" forKey:@"enabled"];
        }
        
        [mpsa connectAndExecuteCommandBlock:^(NSError * connectError)
         {
             if (connectError != nil) {
                 NSLog(@"Error: %@",connectError.localizedDescription);
             } else {
                 [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                     NSLog(@"Error: %@",proxyError.localizedDescription);
                 }] writeLDAPConf:mpsa.authorization ldapConf:lDict withReply:^(NSError * commandError, NSString *licenseKey) {
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
