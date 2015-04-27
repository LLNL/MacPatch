//
//  AdminServiceVC.m
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/8/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import "AdminServiceVC.h"
#import <ServiceManagement/ServiceManagement.h>
#import "Constants.h"
#import "Common.h"
#import "HelperTool.h"

#define SRVS_ON         @"Service is running."
#define SRVS_OFF        @"Service is not running."

@interface AdminServiceVC () {
    AuthorizationRef    _authRef;
    BOOL                _textChanged;
}

@property (atomic, copy,   readwrite) NSData *authorization;
@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;

- (void)readXMLConfig;
- (void)showServiceState;
- (void)readPlistForStartOnLaunch;
- (void)checkServiceState;

@end

@implementation AdminServiceVC

@synthesize serviceState = _serviceState;

- (void)viewDidLoad
{
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
}

- (void)viewDidAppear
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd:)
                                                 name:NSControlTextDidEndEditingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidChange:)
                                                 name:NSControlTextDidChangeNotification object:nil];
    
    
    [self checkServiceState];
    [self readXMLConfig];
    [self showServiceState];
    [self readPlistForStartOnLaunch];
    [self readStartonBootValue];
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

- (void)readXMLConfig
{
    __block NSDictionary *d;
    [self connectAndExecuteCommandBlock:^(NSError * connectError)
     {
         if (connectError != nil) {
             NSLog(@"Error: %@",connectError.localizedDescription);
         } else {
             [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                 NSLog(@"Error: %@",proxyError.localizedDescription);
             }] readSiteData:self.authorization withReply:^(NSError *commandError, NSDictionary *siteDict) {
                 d = [siteDict copy];
                 if ([d objectForKey:@"port"])
                 {
                     _portField.stringValue = [d objectForKey:@"port"];
                 }
             }];
         }
     }];
}

- (void)writeConfChanges:(NSDictionary *)aConf launchdConf:(NSDictionary *)lConf
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
             }] writeSiteConfig:self.authorization siteConf:aConf launchDConf:lConf withReply:^(NSError * commandError, NSString *licenseKey) {
                 if (commandError != nil) {
                     NSLog(@"Error: %@",commandError.localizedDescription);
                 } else {
                     //NSLog(@"%@",licenseKey);
                 }
             }];
         }
     }];
}

- (void)showServiceState
{
    NSArray *jobs = (__bridge NSArray *)SMCopyAllJobDictionaries(kSMDomainSystemLaunchd);
    if (!jobs) {
        return;
    }
    for (NSDictionary *s in jobs)
    {
        if ([[s objectForKey:@"Label"] isEqualToString:SERVICE])
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
                 }] startService:self.authorization startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
                     if (commandError != nil) {
                         NSLog(@"Error: %@",commandError.localizedDescription);
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
                 }] stopService:self.authorization startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
                     if (commandError != nil) {
                         NSLog(@"Error: %@",commandError.localizedDescription);
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

- (IBAction)openAdminConsole:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://%@.local/admin",[[NSHost currentHost] localizedName]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (IBAction)toggleStartServiceOnBootCheckbox:(id)sender
{
    _textChanged = TRUE;
    NSNotification *note = [NSNotification notificationWithName:@"StartOnLoad" object:nil];
    [self editingDidEnd:note];
}

- (void)readPlistForStartOnLaunch
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:LAUNCHD_FILE])
    {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:LAUNCHD_FILE];
        if (d) {
            if ([d objectForKey:@"RunAtLoad"])
            {
                BOOL isOn = [[d objectForKey:@"RunAtLoad"] boolValue];
                if (isOn) {
                    _startOnBootCheckBox.state = NSOnState;
                } else {
                    _startOnBootCheckBox.state = NSOffState;
                }
            }
        }
    } else {
        _startOnBootCheckBox.state = NSOnState;
    }
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
    if ([fm fileExistsAtPath:TOMCAT_ADMIN] == NO) {
        self.serviceConfText.stringValue = @"Could not locate Tomcat Admin Console. Please verify that it's installed.";
        self.serviceConfText.hidden = NO;
        self.serviceConfImage.hidden = NO;
        self.serviceButton.enabled = NO;
    } else {
        self.serviceConfText.hidden = YES;
        self.serviceConfImage.hidden = YES;
        self.serviceButton.enabled = YES;
    }
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
        if (([notification object] == self.portField) || [[notification name] isEqualTo:@"StartOnLoad"])
        {
            NSDictionary *siteDict = @{@"port": _portField.stringValue};
            BOOL lDEnabled = ([self.startOnBootCheckBox state] == NSOnState);
            NSDictionary *launchDDict = @{@"RunAtLoad": [NSNumber numberWithBool:lDEnabled]};
            [self writeConfChanges:siteDict launchdConf:launchDDict];
        }
        _textChanged = FALSE;
    }
}

@end
