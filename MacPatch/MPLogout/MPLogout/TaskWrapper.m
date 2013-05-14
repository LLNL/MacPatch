//
//  TaskWrapper.m
//	Code taken from:
//	http://developer.apple.com/library/mac/#samplecode/Moriarity/Introduction/Intro.html
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

#import "TaskWrapper.h"
#import "MacPatch.h"

typedef enum
{
	ATASK_SUCCESS_VALUE = 0
}
SUCCESS_STATUS;

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

@implementation TaskWrapper

@synthesize taskResult;
@synthesize approvedPatch;

// Do basic initialization
- (id)initWithController:(id <TaskWrapperController>)cont patch:(NSDictionary *)aPatch;
{
    self = [super init];
	
    controller = cont;
    approvedPatch = [aPatch retain];
	[self getOSVersion];
    
    return self;
}

// tear things down
- (void)dealloc
{
    [self stopProcess];
	
    [task release];
    [super dealloc];
}

- (void)getOSVersion
{
	osMajor=0;
	osMinor=0;
	
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
	osMajor=[[osVers objectAtIndex:0] intValue];
	osMinor=[[osVers objectAtIndex:1] intValue];
	
	return;
}

- (void)startProcessCustomUsingDictionary:(NSDictionary *)aDict
{
	approvedPatch = [NSDictionary dictionaryWithDictionary:aDict];
	[self startProcess];
}

- (void)startProcessCustom:(NSString *)aPkg
{
	NSDictionary *l_approvedUpdate = [NSDictionary dictionaryWithObjectsAndKeys:aPkg,@"patch",@"Third",@"type",nil];
	approvedPatch = [NSDictionary dictionaryWithDictionary:l_approvedUpdate];
	[self startProcess];
}

// Here's where we actually kick off the process via an NSTask.
- (void)startProcess
{
	logit(lcl_vDebug, @"Approved Patch Info [Install]: %@",approvedPatch);
	
	taskIsRunning=YES;
    // We first let the controller know that we are starting
    [controller installProcessStarted];
	
    task = [[NSTask alloc] init];
    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]];
	
	NSArray *appArgs;
	if ([[approvedPatch objectForKey:@"type"] isEqualToString:@"Apple"]) {
		// The path to the binary is the first argument that was passed in
		[task setLaunchPath:ASUS_BIN_PATH];
		if (osMinor >= 6) {
			appArgs = [NSArray arrayWithObjects:@"-i", [approvedPatch objectForKey:@"patch"], @"-v", nil];
		} else {
			appArgs = [NSArray arrayWithObjects:@"-i", [approvedPatch objectForKey:@"patch"], nil];
		}
		[task setArguments: appArgs];
	} else {
		[task setLaunchPath:INSTALLER_BIN_PATH];
		appArgs = [NSArray arrayWithObjects:@"-verboseR", @"-allow", @"-pkg", [approvedPatch objectForKey:@"patch"], @"-target", @"/", nil];
		[task setArguments: appArgs];
	}
	
	
	NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *environment = [[[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment] autorelease];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[environment setObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
	
	if ([[approvedPatch objectForKey:@"type"] isEqualToString:@"Apple"]) {
		[environment setObject:@"CM_BUILD" forKey:@"CM_BUILD"];
		[environment setObject:@"/Users/Shared" forKey:@"HOME"];
	} else {
		if ([approvedPatch objectForKey:@"env"]) {
			if ([[approvedPatch objectForKey:@"env"] isEqualToString:@"NA"] == NO && [[[approvedPatch objectForKey:@"env"] trim] length] > 0) {
				NSArray *l_envArray;
				NSArray *l_envItems;
				l_envArray = [[approvedPatch objectForKey:@"env"] componentsSeparatedByString:@","];
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
	}
	logit(lcl_vDebug,@"Env: %@",environment); 
	[task setEnvironment:environment];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(getData:) 
												 name: NSFileHandleReadCompletionNotification 
											   object: [[task standardOutput] fileHandleForReading]];
    
    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    [task launch];    
}

- (int)startPreCriteria
{
	int result = 0;
	MPScript		*mps;
	NSDictionary	*criteriaDict;
	NSData			*scriptData;
	NSString		*scriptText;
	
	if ([[approvedPatch objectForKey:@"hasCriteria"] boolValue] == NO) {
		goto done;
		
	} else {
		logit(lcl_vInfo,@"%@ has install criteria assigned to it.",[approvedPatch objectForKey:@"patch"]);
		
		int i = 0;
		// PreInstall First
		if ([approvedPatch objectForKey:@"criteria_pre"]) {
			logit(lcl_vInfo,@"Processing pre-install criteria."); 
			for (i=0;i<[[approvedPatch objectForKey:@"criteria_pre"] count];i++)
			{
				@try {
					criteriaDict = [[approvedPatch objectForKey:@"criteria_pre"] objectAtIndex:i]; 
					logit(lcl_vDebug,@"criteriaDict=%@",criteriaDict);
					
					scriptData = [[criteriaDict objectForKey:@"data"] decodeBase64WithNewlines:NO];
					scriptText = [[[NSString alloc] initWithData:scriptData encoding:NSUTF8StringEncoding] autorelease];
					logit(lcl_vDebug,@"scriptText=%@",scriptText);
					
					if (mps!=nil)
						[mps release];
					
					mps = [[MPScript alloc] init];
					
					if ([mps runScript:scriptText]) {
						logit(lcl_vInfo,@"Pre-install script returned true.");
						result = 0;
					} else {
						logit(lcl_vError,@"Pre-install script returned false for %@. No install will occure.",[approvedPatch objectForKey:@"patch"]); 
						result = 1;
						goto done;
					}
					
					criteriaDict = nil;
				}
				@catch (NSException * e) {
					logit(lcl_vError,@"Pre-install script returned false for %@. No install will occure.",[approvedPatch objectForKey:@"patch"]); 
					logit(lcl_vError,@"%@",[e description]); 
					result = 1;
					goto done;
				}
			}
		}
	}	
	
done:
	if (mps!=nil)
		[mps release];
	
	return result;
}

- (int)startPostCriteria
{
	int result = 0;
	MPScript		*mps;
	NSDictionary	*criteriaDict;
	NSData			*scriptData;
	NSString		*scriptText;
	
	if ([[approvedPatch objectForKey:@"hasCriteria"] boolValue] == NO) {
		goto done;
		
	} else {
		logit(lcl_vInfo,@"%@ has install criteria assigned to it.",[approvedPatch objectForKey:@"patch"]);
		
		int i = 0;
		if ([approvedPatch objectForKey:@"criteria_post"]) {
			logit(lcl_vInfo,@"Processing post-install criteria."); 
			for (i=0; i<[[approvedPatch objectForKey:@"criteria_post"] count]; i++)
			{
				@try {
					criteriaDict = [[approvedPatch objectForKey:@"criteria_post"] objectAtIndex:i]; 
					logit(lcl_vDebug,@"criteriaDict=%@",criteriaDict);
					
					scriptData = [[criteriaDict objectForKey:@"data"] decodeBase64WithNewlines:NO];		
					scriptText = [[[NSString alloc] initWithData:scriptData encoding:NSUTF8StringEncoding] autorelease];
					logit(lcl_vDebug,@"scriptText=%@",scriptText);
					
					if (mps!=nil)
						[mps release];
					
					mps = [[MPScript alloc] init];
					
					if ([mps runScript:scriptText]) {
						logit(lcl_vInfo,@"Post-install script returned true.");
					} else {
						logit(lcl_vError,@"Post-install script returned false for %@. No install will occure.",[approvedPatch objectForKey:@"patch"]); 
						result = 1;
						goto done;
					}
					
					criteriaDict = nil;
				}	
				@catch (NSException * e) {
					logit(lcl_vError,@"Post-install script returned false for %@.",[approvedPatch objectForKey:@"patch"]); 
					logit(lcl_vError,@"%@",[e description]); 
					result = 1;
					goto done;
				}		
			}
		}
	}	
	
done:	
	if (mps!=nil)
		[mps release];
	
	return result;
}

- (void)preProcessFailed
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    taskResult=1;
	
	[controller appendOutput:[NSString stringWithFormat:@"Pre-criteria script failed for %@. No install will occure.",[approvedPatch objectForKey:@"patch"]]];
	
	// we tell the controller that we finished, via the callback, and then blow away our connection
	// to the controller.  NSTasks are one-shot (not for reuse), so we might as well be too.
	taskIsRunning=NO;
	[controller installProcessFinished];
	controller = nil;
	
}

- (void)stopProcess
{
    NSData *data;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object: [[task standardOutput] fileHandleForReading]];
    
	
	if (![task isRunning]) {
		int status = [task terminationStatus];
		if (status == ATASK_SUCCESS_VALUE)
			taskResult=0;
		else
			taskResult=1;
	} else {
		// Make sure the task has actually stopped!
		[task terminate];
		taskResult=1;
	}

	NSException	*error = nil;
	
	while ((data = [[[task standardOutput] fileHandleForReading] availableDataOrError:&error]) && [data length] && error == nil)
	{
		[controller appendOutput: [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
	}

	// we tell the controller that we finished, via the callback, and then blow away our connection
	// to the controller.  NSTasks are one-shot (not for reuse), so we might as well be too.
	taskIsRunning=NO;
	[controller installProcessFinished];
	controller = nil;
}

- (void)getData:(NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    // If the length of the data is zero, then the task is basically over - there is nothing
    // more to get from the handle so we may as well shut down.
    if ([data length])
    {
        // Send the data on to the controller; we can't just use +stringWithUTF8String: here
        // because -[data bytes] is not necessarily a properly terminated string.
        // -initWithData:encoding: on the other hand checks -[data length]
        [controller appendOutput: [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
    } else {
        // We're finished here
        [self stopProcess];
    }
    
    // we need to schedule the file handle go read more data in the background again.
    [[aNotification object] readInBackgroundAndNotify];  
}

@end
