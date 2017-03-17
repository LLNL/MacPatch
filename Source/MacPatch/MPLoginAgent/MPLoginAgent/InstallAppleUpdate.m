//
//  InstallAppleUpdate.m
//  MPLoginAgent
/*
 Copyright (c) 2017, Lawrence Livermore National Security, LLC.
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

#import "InstallAppleUpdate.h"
#import "MacPatch.h"

#undef  ql_component
#define ql_component lcl_cMain

enum {
    kMPInstallStatus = 0,
    kMPProcessStatus = 1
};
typedef NSUInteger MPPostDataType;

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

@implementation InstallAppleUpdate

@synthesize taskTimedOut;
@synthesize taskIsRunning;
@synthesize installtaskResult;
@synthesize taskTimeoutValue;
@synthesize timeoutTimer;

- (id)init
{
    if (self = [super init])
    {
        [self setTaskTimeoutValue:1800];
        [self setTaskIsRunning:NO];
        [self setTaskTimedOut:NO];
    }
    
    return self;
}

- (int)installAppleSoftwareUpdate:(NSString *)aUpdate
{
    [self setTaskIsRunning:YES];
    [self setTaskTimedOut:NO];

    int taskResult = -1;

    if (task) {
        task = nil;
    }
    task = [[NSTask alloc] init];
    NSPipe *aPipe = [NSPipe pipe];

    [task setStandardOutput:aPipe];
    [task setStandardError:aPipe];

    NSArray *appArgs;
    // Parse the Environment variables for the install
    if ((int)NSAppKitVersionNumber >= 1187 /* 10.8 */) {
        appArgs = [NSArray arrayWithObjects:@"-v",@"-i", aUpdate, nil];
    } else {
        appArgs = [NSArray arrayWithObjects:@"-i", aUpdate, nil];
    }

    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [environment setObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];

    [task setEnvironment:environment];
    [task setLaunchPath:ASUS_BIN_PATH];
    [task setArguments:appArgs];

    // Launch The NSTask
    @try {
        [task launch];
        // If timeout is set start it ...
        if (taskTimeoutValue != 0) {
            [NSThread detachNewThreadSelector:@selector(taskTimeoutThread) toTarget:self withObject:nil];
        }
    }
    @catch (NSException *e)
    {
        logit(lcl_vError,@"Install returned error. %@\n%@",[e reason],[e userInfo]);
        taskResult = 1;
        if(timeoutTimer) {
            [timeoutTimer invalidate];
        }
        [self setTaskIsRunning:NO];
        return taskResult;
    }

    BOOL            foundDone = NO;
    NSString		*tmpStr;
    NSMutableData	*data = [[NSMutableData alloc] init];
    NSData			*dataChunk = nil;
    NSException		*error = nil;

    while(taskTimedOut == NO && ((dataChunk = [[aPipe fileHandleForReading] availableDataOrError:&error]) && [dataChunk length] && error == nil))
    {
        // If the data is not null, then post the data back to the client and log it locally
        tmpStr = [[NSString alloc] initWithData:dataChunk encoding:NSUTF8StringEncoding];
        if ([[tmpStr trim] length] != 0)
        {
            if ([tmpStr containsString:@"PackageKit: Missing bundle path"] == NO) {
                if ([tmpStr containsString:@"Done."] == YES) {
                    foundDone = YES;
                }
                logit(lcl_vDebug,@"%@",tmpStr);
                [_delegate installData:self data:tmpStr type:kMPInstallStatus];
                //[self postDataToClient:tmpStr type:kMPInstallStatus];
            } else {
                logit(lcl_vDebug,@"%@",tmpStr);
            }
        }
        
        [data appendData:dataChunk];
        tmpStr = nil;
    }

    [[aPipe fileHandleForReading] closeFile];

    if (taskTimedOut == YES) {
        logit(lcl_vError,@"Task was terminated due to timeout.");
        [NSThread sleepForTimeInterval:2.0];
        taskResult = 1;
        goto done;
    }

    // A number of Apple Patches have a termination status other than 0
    // Using "Done."
    if (foundDone == YES) {
        taskResult = 0;
    } else {
        if([data length] && error == nil)
        {
            if ([task terminationStatus] == 0) {
                taskResult = 0;
            } else {
                taskResult = 1;
            }
        } else {
            logit(lcl_vError,@"Install returned error. Code:[%d]",[task terminationStatus]);
            taskResult = 1;
        }
    }

    done:
    if(timeoutTimer) {
        [timeoutTimer invalidate];
    }
    if (data) {
        data = nil;
    }
    [self setTaskIsRunning:NO];
    return taskResult;
}

- (void)postDataToClient:(id)data type:(MPPostDataType)dataType
{
    /*
    @try {
        if (dataType == kMPProcessStatus) {
            [_client statusData:data];
        } else if (dataType == kMPInstallStatus) {
            [_client installData:data];
        } else {
            logit(lcl_vError,@"MPPostDataType not supported.");
        }
    }
    @catch (NSException *exception) {
        logit(lcl_vError,@"%@",exception);
    }
    logit(lcl_vInfo,@"%@",data);
     */
}

- (void)taskTimeoutThread
{
    @autoreleasepool {
        logit(lcl_vDebug,@"Timeout is set to %d",taskTimeoutValue);
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:taskTimeoutValue
                                                          target:self
                                                        selector:@selector(taskTimeout:)
                                                        userInfo:nil
                                                         repeats:NO];
        [self setTimeoutTimer:timer];
        
        while (taskTimedOut == NO && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    }
}

- (void)taskTimeout:(NSNotification *)aNotification
{
    logit(lcl_vInfo,@"Task timedout, killing task.");
    [timeoutTimer invalidate];
    [self setTaskTimedOut:YES];
    [task terminate];
}

@end
