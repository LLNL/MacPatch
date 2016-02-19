//
//  TomcatService.m
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/21/16.
//  Copyright © 2016 Charles Heizer. All rights reserved.
//

#import "TomcatService.h"
#import "MPServerAdmin.h"
#import <ServiceManagement/ServiceManagement.h>
#import "Common.h"
#import "Constants.h"
#import "HelperTool.h"

#define SRVS_ON         @"Service is running."
#define SRVS_OFF        @"Service is not running."

#undef  ql_component
#define ql_component lcl_cMain

@interface TomcatService () {
    MPServerAdmin *mpsa;
}

- (void)showServiceState;
- (void)readStartonBootValue;
- (void)checkServiceState;
- (void)toggleAppsCheckBoxes;

@end

@implementation TomcatService

@synthesize serviceState = _serviceState;

- (void)viewDidLoad
{
    qldebug(@"Tomcat Server View Did Load");
    
    [super viewDidLoad];
    [self checkServiceState];
    
    _serviceButton.title = @"Start Service";
    _serviceState = -1;
    
    mpsa = [MPServerAdmin sharedInstance];
    
    [self showServiceState];
}

- (void)viewDidAppear
{
    [self checkServiceState];
    [self showServiceState];
    [self readStartonBootValue];
    [self toggleAppsCheckBoxes];
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
        if ([[s objectForKey:@"Label"] isEqualToString:SERVICE_TOMCAT])
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
                 }] startTomcatServer:mpsa.authorization  startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
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
                 }] stopTomcatServer:mpsa.authorization startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
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

- (IBAction)toggleWebService:(id)sender
{
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
             [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                 NSLog(@"Error: %@",proxyError.localizedDescription);
             }] toggleWebServiceApp:mpsa.authorization  startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
                 if (commandError != nil) {
                     NSLog(@"Error: %@",commandError.localizedDescription);
                     _serviceButton.enabled = TRUE;
                 } else {
                     [NSThread sleepForTimeInterval:5.0];
                 }
             }];
         }
     }];
}

- (IBAction)toggleConsoleService:(id)sender
{
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
             [[mpsa.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                 NSLog(@"Error: %@",proxyError.localizedDescription);
             }] toggleConsoleApp:mpsa.authorization  startOnBoot:onOff withReply:^(NSError * commandError, NSString * licenseKey) {
                 if (commandError != nil) {
                     NSLog(@"Error: %@",commandError.localizedDescription);
                     _serviceButton.enabled = TRUE;
                 } else {
                     [NSThread sleepForTimeInterval:5.0];
                 }
             }];
         }
     }];
}

- (void)readStartonBootValue
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
             }] readLaunchDFile:LAUNCHD_FILE_TOMCAT withReply:^(NSDictionary *dict) {
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
    if ([fm fileExistsAtPath:TOMCAT_SERVER] == NO) {
        self.serviceConfText.stringValue = @"Could not locate Tomcat Server. Please verify that it's installed.";
        self.serviceConfText.hidden = NO;
        self.serviceConfImage.hidden = NO;
        self.serviceButton.enabled = NO;
    } else {
        self.serviceConfText.hidden = YES;
        self.serviceConfImage.hidden = YES;
        self.serviceButton.enabled = YES;
    }
}

- (IBAction)openAdminConsole:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://%@.local/admin",[[NSHost currentHost] localizedName]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void)toggleAppsCheckBoxes
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
             }] readSiteConf:mpsa.authorization withReply:^(NSError * error, NSDictionary * siteConfDict) {
                 if (error != nil) {
                     NSLog(@"Error: %@",error.localizedDescription);
                 } else {
                     [self.consoleServiceCheckBox setState:[[siteConfDict valueForKeyPath:@"settings.services.console"] integerValue]];
                     [self.webServiceCheckBox setState:[[siteConfDict valueForKeyPath:@"settings.services.mpwsl"] integerValue]];
                 }
             }];
         }
     }];
}

@end
