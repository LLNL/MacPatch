//
//  AppDelegate.m
//  MPServerAdmin
//
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

#import "AppDelegate.h"
#import "TomcatService.h"
#import "AdminServiceVC.h"
#import "WebServiceVC.h"
#import "ApplePatchSyncVC.h"
#import "ContentSyncVC.h"
#import "AVSyncVC.h"
#import "DatabaseVC.h"
#import "WebServerVC.h"
#import "AuthenticationVC.h"

#import "Constants.h"
#import "Common.h"
#import "HelperTool.h"
#include <ServiceManagement/ServiceManagement.h>
#import "AHLaunchCtl.h"
#import "MPServerAdmin.h"


#undef  ql_component
#define ql_component lcl_cMain

@interface AppDelegate () {
    MPServerAdmin *mpsa;
}

- (NSString *)javaHome;

@end

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)awakeFromNib
{
    [self checkServerVersion];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    // put the views into the tabview

    mpsa = [MPServerAdmin sharedInstance];
    if ([self helperIsInstalled] == NO) {
        [mpsa installHelperApp];
    }
    [mpsa connectToHelperTool];

    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSUserDomainMask, YES );
    NSString *logFile = [[paths firstObject] stringByAppendingPathComponent:@"Logs/MPServerAdmin.log"];
    [LCLLogFile setPath:logFile];
    lcl_configure_by_name("*", lcl_vDebug);
    [LCLLogFile setAppendsToExistingLogFile:YES];
    [LCLLogFile setMirrorsToStdErr:YES];
    
    NSTabViewItem *item;
    //item = [[self tabView] tabViewItemAtIndex:0];
    //[item setView:[[self webServerVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:0];
    [item setView:[[self tomcatService] view]];
    
    //item = [[self tabView] tabViewItemAtIndex:1];
    //[item setView:[[self adminServiceVC] view]];
    
    //item = [[self tabView] tabViewItemAtIndex:2];
    //[item setView:[[self webServiceVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:1];
    [item setView:[[self applePatchSyncVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:2];
    [item setView:[[self contentSyncVC] view]];
    
    // Not Implemented Yet
    //item = [[self tabView] tabViewItemAtIndex:5];
    //[item setView:[[self avSyncVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:3];
    [item setView:[[self databaseVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:4];
    [item setView:[[self authenticationVC] view]];
    
    /*
    [[self tabView] selectFirstTabViewItem:self.adminServiceVC];
     */
    
    [self.window makeKeyAndOrderFront:self];
    [self checkForJava:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (BOOL)helperIsInstalled
{
    BOOL result = NO;
    NSArray *jobs = (__bridge NSArray *)SMCopyAllJobDictionaries(kSMDomainSystemLaunchd);
    if (!jobs) {
        return result;
    }
    for (NSDictionary *s in jobs)
    {
        
        if ([[s objectForKey:@"Label"] isEqualToString:@"gov.llnl.mp.admin.helper"])
        {
            NSLog(@"%@",s);
            NSError *error = nil;
            if ([s objectForKey:@"Program"] != nil) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:[s objectForKey:@"Program"]]) {
                    [mpsa installHelperApp];
                }
            }
            
            if ([s objectForKey:@"PID"] == nil) {
                if (![[AHLaunchCtl sharedController] start:@"gov.llnl.mp.admin.helper" inDomain:kAHGlobalLaunchDaemon error:&error]) {
                    NSLog(@"Error Starting Job: %@", error.localizedDescription);
                }
            }

            return YES;
            break;
        }
    }
    
    return result;
}

#pragma mark - IBActions

- (IBAction)tabButtonPressed:(id)sender
{
    static int cycle = 0; // assume initial tab was first
    
    cycle++;
    if (cycle >= [[self tabView] numberOfTabViewItems])
        cycle = 0;
    
    [[self tabView] selectTabViewItemAtIndex:cycle];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    //NSLog(@"push %@",tabViewItem);
}

- (IBAction)installHelperApp:(id)sender
{
    [self helperIsInstalled];
}

- (IBAction)installHelperAppAlt:(id)sender
{
    NSError *error;
    NSString *kYourHelperToolReverseDomain = @"gov.llnl.mp.admin.helper";
    [AHLaunchCtl installHelper:kYourHelperToolReverseDomain prompt:@"Install Helper?" error:&error];
    if(error) {
        NSLog(@"error: %@",error);
    }
}

- (IBAction)checkForJava:(id)sender
{
    // /usr/libexec/java_home
    NSString *jResult = [self javaHome];
    if ([jResult rangeOfString:@"No Java runtime"].location == NSNotFound) {
        qltrace(@"Java Home was found.");
    } else {
        qlerror(@"%@",jResult);
        // Show Dialog
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert setMessageText:@"Error, Java does not appear to be installed."];
        [alert setInformativeText:@"Please download and install the JAVA JDK."];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Oracle (Java JDK)"];
        [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (void)checkServerVersion
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:SERVER_VER_FILE]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert setMessageText:@"Error, Server Version Not Supported"];
        [alert setInformativeText:@"The server version of MacPatch installed is not supported by this app. Please upgrade the MacPatch server software."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        [NSApp terminate:nil];
    } else {

        NSError *err = nil;
        NSData *siteConfigData = [NSData dataWithContentsOfFile:SERVER_VER_FILE options:NSDataReadingUncached error:&err];
        if (err) {
            return;
        }
        err = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:siteConfigData options:NSJSONReadingMutableContainers error:&err];
        if (err) {
            return;
        }
        
        if ([result objectForKey:@"server"] != nil) {
            if ([[result objectForKey:@"server"] objectForKey:@"version"] != nil) {
                NSString *serverVer = [[result objectForKey:@"server"] objectForKey:@"version"];
                NSString *minVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"MinServerVer"];
                NSComparisonResult res = [self compareVersion:serverVer to:minVersion];
                if (res == NSOrderedAscending) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setAlertStyle:NSCriticalAlertStyle];
                    [alert setMessageText:@"Error, Server Version Not Supported"];
                    [alert setInformativeText:@"The server version of MacPatch installed is not supported by this app. Please upgrade the MacPatch server software."];
                    [alert addButtonWithTitle:@"OK"];
                    [alert runModal];
                    [NSApp terminate:nil];
                }
            }
        }
        
    }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
    switch(returnCode) {
        case NSAlertFirstButtonReturn:
            // First
            break;
        case NSAlertSecondButtonReturn:
            // Next
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html"]];
            break;
    }
}

- (NSString *)javaHome
{
    
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    NSString* returnValue = nil;
    
    NSTask * unixTask = [[NSTask alloc] init];
    [unixTask setStandardOutput:newPipe];
    [unixTask setLaunchPath:@"/usr/libexec/java_home"];
    [unixTask launch];
    [unixTask waitUntilExit];
    int status = [unixTask terminationStatus];
    
    while ((inData = [readHandle availableData]) && [inData length]) {
        
        returnValue= [[NSString alloc]
                      initWithData:inData encoding:[NSString defaultCStringEncoding]];
        
        returnValue = [returnValue substringToIndex:[returnValue length]-1];
        qldebug(@"[%d]: %@",status, returnValue);
    }
    
    return returnValue;
}

- (NSComparisonResult)compareVersion:(NSString *)versionA to:(NSString *)versionB
{
    NSArray *versionAComp = [versionA componentsSeparatedByString:@"."];
    NSArray *versionBComp = [versionB componentsSeparatedByString:@"."];
    
    __block NSComparisonResult result = NSOrderedSame;
    
    [versionAComp enumerateObjectsUsingBlock:
     ^(NSString *obj, NSUInteger idx, BOOL *stop)
     {
         // handle abbreviated versions.
         if (idx > versionBComp.count -1)
         {
             *stop = YES;
             return;
         }
         
         NSInteger verAInt = [versionAComp[idx] integerValue];
         NSInteger verBInt = [versionBComp[idx] integerValue];
         
         if (verAInt != verBInt)
         {
             if (verAInt < verBInt)
                 result = NSOrderedAscending;
             else
                 result = NSOrderedDescending;
             
             *stop = YES;
             return;
         }
     }];
    return result; 
}

@end
