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
#import <ServiceManagement/ServiceManagement.h>
#import "Constants.h"
#import "Common.h"
#import "HelperTool.h"

@interface AuthenticationVC () {
    AuthorizationRef    _authRef;
    BOOL _textChanged;
}

@property (atomic, copy,   readwrite) NSData *authorization;
@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;

@property (strong) NSDictionary *dbConfig;
@property (strong) NSDictionary *dbConfigRO;

- (void)readLDAPSettings;

@end

@implementation AuthenticationVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _textChanged = FALSE;
    
    OSStatus                    err;
    AuthorizationExternalForm   extForm;
    
    // Create our connection to the authorization system.
    //
    // If we can't create an authorization reference then the app is not going to be able
    // to do anything requiring authorization.  Generally this only happens when you launch
    // the app in some wacky, and typically unsupported, way.  In the debug build we flag that
    // with an assert.  In the release build we continue with self->_authRef as NULL, which will
    // cause all authorized operations to fail.
    
    err = AuthorizationCreate(NULL, NULL, 0, &self->_authRef);
    if (err == errAuthorizationSuccess) {
        err = AuthorizationMakeExternalForm(self->_authRef, &extForm);
    }
    if (err == errAuthorizationSuccess) {
        self.authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
    }
    assert(err == errAuthorizationSuccess);
    
    // If we successfully connected to Authorization Services, add definitions for our default
    // rights (unless they're already in the database).
    
    if (self->_authRef) {
        [Common setupAuthorizationRights:self->_authRef];
    }
    
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

#pragma mark - Helper Tool
- (void)connectToHelperTool
// Ensures that we're connected to our helper tool.
{
    assert([NSThread isMainThread]);
    
    if (self.helperToolConnection == nil) {
        self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperToolMachServiceName options:NSXPCConnectionPrivileged];
        self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        // We can ignore the retain cycle warning because a) the retain taken by the
        // invalidation handler block is released by us setting it to nil when the block
        // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
        // will be released when that operation completes and the operation itself is deallocated
        // (notably self does not have a reference to the NSBlockOperation).
        self.helperToolConnection.invalidationHandler = ^{
            // If the connection gets invalidated then, on the main thread, nil out our
            // reference to it.  This ensures that we attempt to rebuild it the next time around.
            self.helperToolConnection.invalidationHandler = nil;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.helperToolConnection = nil;
                NSLog(@"connection invalidated");
            }];
        };
#pragma clang diagnostic pop
        [self.helperToolConnection resume];
    }
}

- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock
// Connects to the helper tool and then executes the supplied command block on the
// main thread, passing it an error indicating if the connection was successful.
{
    assert([NSThread isMainThread]);
    
    // Ensure that there's a helper tool connection in place.
    
    [self connectToHelperTool];
    
    // Run the command block.  Note that we never error in this case because, if there is
    // an error connecting to the helper tool, it will be delivered to the error handler
    // passed to -remoteObjectProxyWithErrorHandler:.  However, I maintain the possibility
    // of an error here to allow for future expansion.
    
    commandBlock(nil);
}

#pragma mark - Main

- (void)readLDAPSettings
{
    [self connectAndExecuteCommandBlock:^(NSError * connectError)
     {
         if (connectError != nil)
         {
             NSLog(@"Error: %@",connectError.localizedDescription);
         }
         else
         {
             [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                 NSLog(@"Error: %@",proxyError.localizedDescription);
             }] readLDAPConf:self.authorization withReply:^(NSError * commandError, NSDictionary *ldapDict) {
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
        
        [self connectAndExecuteCommandBlock:^(NSError * connectError)
         {
             if (connectError != nil) {
                 NSLog(@"Error: %@",connectError.localizedDescription);
             } else {
                 [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                     NSLog(@"Error: %@",proxyError.localizedDescription);
                 }] writeLDAPConf:self.authorization ldapConf:lDict withReply:^(NSError * commandError, NSString *licenseKey) {
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
