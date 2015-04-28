//
//  AppDelegate.m
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/7/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import "AppDelegate.h"
#import "AdminServiceVC.h"
#import "WebServiceVC.h"
#import "ApplePatchSyncVC.h"
#import "ContentSyncVC.h"
#import "AVSyncVC.h"
#import "DatabaseVC.h"
#import "WebServerVC.h"
#import "AuthenticationVC.h"

#import "Common.h"
#import "HelperTool.h"
#include <ServiceManagement/ServiceManagement.h>

#undef  ql_component
#define ql_component lcl_cMain

@interface AppDelegate () {
    AuthorizationRef    _authRef;
}

@property (atomic, copy,   readwrite) NSData *authorization;
@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;

- (NSString *)javaHome;

@end

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    // put the views into the tabview
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSUserDomainMask, YES );
    NSString *logFile = [[paths firstObject] stringByAppendingPathComponent:@"Logs/MPServerAdmin.log"];
    [LCLLogFile setPath:logFile];
    lcl_configure_by_name("*", lcl_vDebug);
    [LCLLogFile setAppendsToExistingLogFile:YES];
    [LCLLogFile setMirrorsToStdErr:YES];
    
    NSTabViewItem *item;
    item = [[self tabView] tabViewItemAtIndex:0];
    [item setView:[[self webServerVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:1];
    [item setView:[[self adminServiceVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:2];
    [item setView:[[self webServiceVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:3];
    [item setView:[[self applePatchSyncVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:4];
    [item setView:[[self contentSyncVC] view]];
    
    // Not Implemented Yet
    //item = [[self tabView] tabViewItemAtIndex:5];
    //[item setView:[[self avSyncVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:5];
    [item setView:[[self databaseVC] view]];
    
    item = [[self tabView] tabViewItemAtIndex:6];
    [item setView:[[self authenticationVC] view]];
    
    /*
    [[self tabView] selectFirstTabViewItem:self.adminServiceVC];
     */
    
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
    
    // Install the Helper
    if ([self helperIsInstalled] == NO) {
        [self installHelper];
    }
    
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

- (void)installHelper
{
    Boolean             success;
    CFErrorRef          error;
    success = SMJobBless(kSMDomainSystemLaunchd,CFSTR("gov.llnl.mp.admin.helper"),self->_authRef,&error);
    if (success) {
        //NSLog(@"success");
    } else {
        NSLog(@"Error: %@",(__bridge NSError *)error);
        CFRelease(error);
    }
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
            return YES;
            break;
        }
    }
    
    return result;
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
    [self installHelper];
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

@end
