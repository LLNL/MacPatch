//
//  InstallPackage.m
//  MPLoginAgent
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

#import "InstallPackage.h"
#import "MacPatch.h"

#undef  ql_component
#define ql_component lcl_cMain

@interface NSFileHandle (MPNSFileHandleAdditions)
- (NSData *)availableDataOrError:(NSException **)returnError;
@end

@implementation NSFileHandle (MPNSFileHandleAdditions)
- (NSData *)availableDataOrError:(NSException **)returnError
{
    for(;;)
    {
        @try
        {
            return [self availableData];
        }
        @catch (NSException *e)
        {
            if ([[e name] isEqualToString:NSFileHandleOperationException]) {
                if ([[e reason] isEqualToString:@"*** -[NSConcreteFileHandle availableData]: Interrupted system call"]) {
                    continue;
                }
                if (returnError) {
                    *returnError = e;
                }
                return nil;
            }
            @throw;
        }
    }
}
@end

@implementation InstallPackage

@synthesize taskTimedOut;
@synthesize taskIsRunning;
@synthesize installtaskResult;

- (int)installPkgToRoot:(NSString *)pkgPath
{
    return [self installPkg:pkgPath target:@"/" env:nil];
}

- (int)installPkgToRoot:(NSString *)pkgPath env:(NSString *)aEnv;
{
    return [self installPkg:pkgPath target:@"/" env:aEnv];
}

- (int)installPkg:(NSString *)pkgPath target:(NSString *)aTarget env:(NSString *)aEnv
{
    [self setTaskIsRunning:NO];
    [self setInstalltaskResult:99];
    
    [self runInstallPkgTask:pkgPath target:aTarget env:aEnv];
    
    while (taskIsRunning && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    return self.installtaskResult;
}

-(void)runInstallPkgTask:(NSString *)pkg target:(NSString *)target env:(NSString *)aEnv
{
    
    NSArray *appArgs = [NSArray arrayWithObjects:@"-verboseR", @"-pkg", pkg, @"-target", target, nil];
    logit(lcl_vInfo,@"Pkg Install Args: %@",appArgs);
    
    task = [[NSTask alloc] init];
    [task setLaunchPath: INSTALLER_BIN_PATH];
    [task setArguments: appArgs];
    
    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [environment setObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
    
    if (aEnv) {
        if ([aEnv isEqualToString:@"NA"] == NO && [[aEnv trim] length] > 0) {
            NSArray *l_envArray;
            NSArray *l_envItems;
            l_envArray = [aEnv componentsSeparatedByString:@","];
            for (id item in l_envArray) {
                l_envItems = nil;
                l_envItems = [item componentsSeparatedByString:@"="];
                if ([l_envItems count] == 2) {
                    logit(lcl_vDebug,@"Setting env variable(%@=%@).",[l_envItems objectAtIndex:0],[l_envItems objectAtIndex:1]);
                    [environment setObject:[l_envItems objectAtIndex:1] forKey:[l_envItems objectAtIndex:0]];
                } else {
                    logit(lcl_vError,@"Unable to set env variable. Variable not well formed %@",item);
                }
            }
        }
    }
    
    [task setEnvironment:environment];
    
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];
    
    fh = [pipe fileHandleForReading];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskCompleted:)
                                                 name:NSTaskDidTerminateNotification
                                               object:task];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskDataAvailable:)
                                                 name: NSFileHandleReadCompletionNotification
                                               object: fh];
    
    [self setTaskIsRunning:YES];
    [task launch];
    [fh readInBackgroundAndNotify];
}

#pragma mark - Notifications

- (void)taskDataAvailable:(NSNotification *)aNotification
{
    NSData *incomingData = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length])
    {
        NSString *incomingText = [[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding];
        logit(lcl_vDebug,@"%@",incomingText);
        
        [fh readInBackgroundAndNotify];
        incomingText = nil;
        return;
    }
}

- (void)taskCompleted:(NSNotification *)aNotification
{
    [self setTaskIsRunning:NO];
    int exitCode = [[aNotification object] terminationStatus];
    [self setInstalltaskResult:exitCode];
}

@end
