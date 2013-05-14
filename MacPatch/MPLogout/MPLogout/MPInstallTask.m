//
//  MPInstallTask.m
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

#import "MPInstallTask.h"
#import "MacPatch.h"
#import "MPLogout.h"
#include <stdlib.h>
#include <unistd.h>


NSLock *lock;

@interface NSFileHandle (MyOwnAdditions)
- (NSData *)availableDataOrError:(NSException **)returnError;
@end

@implementation NSFileHandle (MyOwnAdditions)
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
				if ([[e reason] isEqualToString:@"*** -[NSConcreteFileHandle availableData]: Interrupted system call"])
					continue;
				
				if (returnError)
					*returnError = e;
				
				return nil;
			}
			@throw;
        }
    }
}
@end

@implementation MPInstallTask

@synthesize _timeoutTimer;
@synthesize taskTimeoutValue;
@synthesize taskTimedOut;
@synthesize osMajor;
@synthesize osMinor;

-(id)init
{
    if (self = [super init])
    {
		//lock = [[NSLock alloc] init];
		[self setTaskTimeoutValue:10];
		[self getOSVersion];
		[self setTaskIsRunning:NO];
		[self setTaskResult:-1];
    }
    
    return self;
}

- (void)dealloc 
{
    // Clean-up code here.
    //[lock release];
	[_task release];
    [super dealloc];
}

#pragma mark -

//=========================================================== 
//  Getters & Setters 
//=========================================================== 
- (BOOL)taskIsRunning
{
    return taskIsRunning;
}
- (void)setTaskIsRunning:(BOOL)flag
{
    taskIsRunning = flag;
}

- (int)taskResult
{
    return taskResult;
}
- (void)setTaskResult:(int)aTaskResult
{
    taskResult = aTaskResult;
}

#pragma mark -

- (void)getOSVersion
{
	[self setOsMajor:0];
	[self setOsMinor:0];
	
	NSData *plistData;
	NSString *error;
	NSPropertyListFormat format;
	id plist;
	
	NSString *localizedPath = @"/System/Library/CoreServices/SystemVersion.plist";
	plistData = [NSData dataWithContentsOfFile:localizedPath];
	
	plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
	if (!plist) {
		logit(lcl_vError,@"Error reading plist from file '%s', error = '%s'", [localizedPath UTF8String], [error UTF8String]);
		[error release];
		return;
	}
	
	if ([plist class] != [NSDictionary class]) {
		return;
	}
	NSArray *osVers = [[plist objectForKey:@"ProductVersion"] componentsSeparatedByString: @"."];
	[self setOsMajor:[[osVers objectAtIndex:0] intValue]];
	[self setOsMinor:[[osVers objectAtIndex:1] intValue]];
	
	return;
}

- (int)installAppleSoftwareUpdate:(NSString *)approvedUpdate
{
	int result = 0;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSRunLoop currentRunLoop];
	
	NSArray *appArgs;
	if (osMinor >= 6) {
		appArgs = [NSArray arrayWithObjects:@"-i", approvedUpdate, @"-v", nil];
	} else {
		appArgs = [NSArray arrayWithObjects:@"-i", approvedUpdate, nil];
	}
	
	logit(lcl_vDebug,@"Install ASUS Args: %@",appArgs);
	
	// Define Install Environment Variables
	NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *environment = [[[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment] autorelease];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[environment setObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
	[environment setObject:@"CM_BUILD" forKey:@"CM_BUILD"];
	[environment setObject:@"/Users/Shared" forKey:@"HOME"];
	
	result = [self runTask:ASUS_BIN_PATH binArgs:appArgs environment:environment];
	
	if (result != 0)
		logit(lcl_vError,@"Error %d, %@",result, approvedUpdate);
	
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	
	[pool release];
	return result;
}

- (void)installAppleSoftwareUpdateFromDictionary:(NSDictionary *)approvedUpdate
{
	[self setTaskIsRunning:YES];
	
	int result = 0;
	BOOL sResult;
	MPScript *mps;
	NSDictionary *criteriaDictPre, *criteriaDictPost;
	NSData *scriptData;
	NSString *scriptText;
	
	
	if ([[approvedUpdate objectForKey:@"hasCriteria"] boolValue] == NO) {
		[self installAppleSoftwareUpdate:[approvedUpdate objectForKey:@"patch"]];
	} else {
		logit(lcl_vInfo,@"%@ has install criteria assigned to it.",[approvedUpdate objectForKey:@"patch"]);
		[approvedUpdate writeToFile:@"/private/tmp/approvedUpdate.plist" atomically:YES];
		
		int i = 0;
		// PreInstall First
		if ([approvedUpdate objectForKey:@"criteria_pre"]) {
			logit(lcl_vInfo,@"Processing pre-install criteria."); 
			for (i=0;i<[[approvedUpdate objectForKey:@"criteria_pre"] count];i++)
			{
				criteriaDictPre = [[approvedUpdate objectForKey:@"criteria_pre"] objectAtIndex:i]; 
				
				scriptData = [[criteriaDictPre objectForKey:@"data"] decodeBase64WithNewlines:NO];		
				scriptText = [[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding];
				
				mps = [[MPScript alloc] init];
				sResult = [mps runScript:scriptText];
				if (sResult == NO) {
					[self setTaskResult:1];
					logit(lcl_vError,@"Pre-install script returned false for %@. No install will occure.",[approvedUpdate objectForKey:@"patch"]); 
					[mps release];
					[scriptText release];
					goto done;
				} else {
					logit(lcl_vInfo,@"Pre-install script returned true.");
				}

				[mps release];
				[scriptText release];
				criteriaDictPre = nil;
			}
		}	
		// Run the patch install, now that the install has occured.
		result = [self installAppleSoftwareUpdate:[approvedUpdate objectForKey:@"patch"]];
		
		// If Install retuened anything but 0, the dont run post criteria
		if (result != 0) {
			logit(lcl_vError,@"The install for %@ returned an error.",[approvedUpdate objectForKey:@"patch"]); 
			goto done;
		}
		
		if ([approvedUpdate objectForKey:@"criteria_post"]) {
			logit(lcl_vInfo,@"Processing post-install criteria.");  
			for (i=0;i<[[approvedUpdate objectForKey:@"criteria_post"] count];i++)
			{
				criteriaDictPost = [[approvedUpdate objectForKey:@"criteria_post"] objectAtIndex:i];
				
				scriptData = [[criteriaDictPost objectForKey:@"data"] decodeBase64WithNewlines:NO];		
				scriptText = [[NSString alloc] initWithData:scriptData encoding:NSASCIIStringEncoding];
				
				mps = [[MPScript alloc] init];
				sResult = [mps runScript:scriptText];
				if (sResult == NO) {
					[self setTaskResult:1];
					logit(lcl_vError,@"Pre-install script returned false for %@. No install will occure.",[approvedUpdate objectForKey:@"patch"]); 
					[mps release];
					[scriptText release];
					goto done;
				} else {
					logit(lcl_vInfo,@"Post-install script returned true.");	
				}
				[mps release];
				[scriptText release];
				criteriaDictPost = nil;
			}
		}
	}
	
done:
	[self setTaskIsRunning:NO];
	return;
}

- (void)installPkg:(NSString *)approvedUpdate
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSRunLoop currentRunLoop];
	
	NSArray *appArgs = [NSArray arrayWithObjects:@"-verboseR", @"-allow", @"-pkg", approvedUpdate, @"-target", @"/", nil];
	logit(lcl_vDebug,@"installPkg Args: %@",appArgs);
	
	// Define Install Environment Variables
	NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *environment = [[[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment] autorelease];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[environment setObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
	[environment setObject:@"CM_BUILD" forKey:@"CM_BUILD"];
	[environment setObject:@"/Users/Shared" forKey:@"HOME"];
	
	[self setTaskIsRunning:YES];
	int result;
	result = [self runTask:INSTALLER_BIN_PATH binArgs:appArgs environment:environment];
	if (result != 0)
		logit(lcl_vError,@"Error %d, %@",result, approvedUpdate);
	
	[self setTaskIsRunning:NO];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	[pool release];
}

- (int)runTask:(NSString *)aBinPath binArgs:(NSArray *)aBinArgs environment:(NSDictionary *)env
{   
	[self setTaskIsRunning:YES];
	[self setTaskTimedOut:NO];
	
	MPLogout *sm = [MPLogout sharedManager];
	
	int l_result = -1;		
    _task = [[[NSTask alloc] init] autorelease];
    NSPipe *aPipe = [NSPipe pipe];
    
	[_task setStandardOutput:aPipe];
	[_task setStandardError:aPipe];
	[_task setEnvironment:env];
    [_task setLaunchPath:aBinPath];
	logit(lcl_vDebug,@"[task][setLaunchPath]: %@",aBinPath);
    [_task setArguments:aBinArgs];
	logit(lcl_vDebug,@"[task][setArguments]: %@",aBinArgs);
	
	if (taskTimeoutValue != 0) {
		
		[NSThread detachNewThreadSelector:@selector(taskTimeoutThread) toTarget:self withObject:nil];
	}
	
	@try {
		[_task launch];
	} 
	@catch (NSException *e) {
		logit(lcl_vError,@"Install returned error. %@\n%@",[e reason],[e userInfo]);
		
		[self setTaskResult:1];
		
		l_result = 1;
	}
	
	NSString		*tmpStr;
    NSMutableData	*data = [[NSMutableData alloc] init];
    NSData			*dataChunk = nil;
    NSException		*error = nil;
    
	while(taskTimedOut == NO && ((dataChunk = [[aPipe fileHandleForReading] availableDataOrError:&error]) && [dataChunk length] && error == nil))
	{
		tmpStr = [[NSString alloc] initWithData:dataChunk encoding:NSUTF8StringEncoding];
		
		if ([[tmpStr trim] length] != 0)
			logit(lcl_vInfo,@"tmpStr=%@",tmpStr);
		
		if ([tmpStr containsString:@"PackageKit: Missing bundle path"] == NO)
			[sm setG_InstallStatusStr:tmpStr];
		
		[data appendData:dataChunk];
		[tmpStr release];
		tmpStr = nil;
	}
    
	[[aPipe fileHandleForReading] closeFile];
	
	if (taskTimedOut == YES) {
		logit(lcl_vError,@"Task was terminated due to timeout.");
		[NSThread sleepForTimeInterval:2.0];
		[self setTaskResult:1];
		l_result = 1;
		goto done;
	}
	
    if([data length] && error == nil){
        [self setTaskResult:0];
		l_result = 0;
    } else {
		logit(lcl_vError,@"Install returned error. Code:[%d]",[_task terminationStatus]);
		[self setTaskResult:1];
		l_result = 1;
	}
	
done:
	if(_timeoutTimer)
		[_timeoutTimer invalidate];
	
	if (data)
		[data autorelease];
	
	[self setTaskIsRunning:NO];
    return l_result;
}

- (void)taskTimeoutThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	logit(lcl_vDebug,@"Timeout is set to %d",taskTimeoutValue);
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:taskTimeoutValue
													  target:self
													selector:@selector(taskTimeout:)
													userInfo:nil
													 repeats:NO];
	[self set_timeoutTimer:timer];
	
	while (taskTimedOut == NO && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
	
	[pool drain];
	
}

- (void)taskTimeout:(NSNotification *)aNotification 
{
	logit(lcl_vError,@"Task timedout, killing task.");
	[_timeoutTimer invalidate];
	[self setTaskTimedOut:YES];
	[_task terminate];
}

@end
