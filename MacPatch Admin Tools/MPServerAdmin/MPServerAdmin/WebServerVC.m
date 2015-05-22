//
//  WebServerVC.m
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

#import "WebServerVC.h"
#import <ServiceManagement/ServiceManagement.h>
#import "Common.h"
#import "Constants.h"
#import "HelperTool.h"

#define SRVS_ON         @"Service is running."
#define SRVS_OFF        @"Service is not running."

#undef  ql_component
#define ql_component lcl_cMain

@interface WebServerVC () {
    AuthorizationRef    _authRef;
}

@property (atomic, copy,   readwrite) NSData *authorization;
@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;

- (void)showServiceState;
- (void)readStartonBootValue;
- (void)checkServiceState;

@end

@implementation WebServerVC

@synthesize serviceState = _serviceState;

- (void)viewDidLoad
{
    qldebug(@"Web Server View Did Load");
    
    [super viewDidLoad];
    [self checkServiceState];
    
    _serviceButton.title = @"Start Service";
    _serviceState = -1;
    
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
    
    [self showServiceState];
}

- (void)viewDidAppear
{
    [self checkServiceState];
    [self showServiceState];
    [self readStartonBootValue];
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

- (void)showServiceState
{
    NSArray *jobs = (__bridge NSArray *)SMCopyAllJobDictionaries(kSMDomainSystemLaunchd);
    if (!jobs) {
        return;
    }
    for (NSDictionary *s in jobs)
    {
        qltrace(@"Looking at jobs, %@", [s objectForKey:@"Label"]);
        if ([[s objectForKey:@"Label"] isEqualToString:SERVICE_WEBSERVER])
        {
            qltrace(@"Job found %@", [s objectForKey:@"Label"]);
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
    
    [self connectAndExecuteCommandBlock:^(NSError * connectError)
     {
         if (connectError != nil)
         {
             NSLog(@"Error: %@",connectError.localizedDescription);
         }
         else
         {
             // If Service State is Off
             if (_serviceState == 0) {
                 [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                     NSLog(@"Error: %@",proxyError.localizedDescription);
                 }] startWebServer:self.authorization  startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
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
                 [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                     NSLog(@"Error: %@",proxyError.localizedDescription);
                 }] stopWebServer:self.authorization startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
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

- (void)readStartonBootValue
{
    __block NSDictionary *d;
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
             }] readLaunchDFile:LAUNCHD_FILE withReply:^(NSDictionary *dict) {
                 d = [dict copy];
                 if ([d objectForKey:@"RunAtLoad"])
                 {
                     if ([[d objectForKey:@"RunAtLoad"] boolValue]) {
                         [self.startOnBootCheckBox setState:NSOnState];
                     } else {
                         [self.startOnBootCheckBox setState:NSOffState];
                     }
                 }
             }];
         }
     }];
}

- (void)checkServiceState
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:APACHE_WEBSERVER] == NO) {
        self.serviceConfText.stringValue = @"Could not locate Apache Web Server. Please verify that it's installed.";
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
