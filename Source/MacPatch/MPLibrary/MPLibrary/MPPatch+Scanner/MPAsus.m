//
//  MPAsus.m
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

#import "MPAsus.h"
#import "MPASUSCatalogs.h"
#import "Constants.h"

#undef  ql_component
#define ql_component lcl_cMPAsus

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

@interface MPAsus ()
{
    NSFileManager	*fm;
    MPSettings		*settings;
    Agent 			*agent;
	
	NSTask			*task;
	NSPipe 			*install_pipe;
}

@property (strong)              NSTimer     *asusTimeoutTimer;
@property (nonatomic, assign)   int         taskTimeoutValue;
@property (nonatomic, assign)   BOOL        taskTimedOut;
@property (nonatomic, assign)   BOOL        taskIsRunning;
@property (nonatomic, assign)   int         taskResult;

@property (nonatomic, assign, readwrite) BOOL patchMustShutdown; // Patch Install Reboot Status

- (NSString *)getSizeFromDescription:(NSString *)aDesc;
- (NSString *)getRecommendedFromDescription:(NSString *)aDesc;

@end

@implementation MPAsus

@synthesize allowClient;
@synthesize allowServer;
@synthesize taskIsRunning;
@synthesize taskResult;
@synthesize patchMustShutdown;

#pragma mark -
#pragma mark init

//=========================================================== 
//  init 
//=========================================================== 

- (id)init
{
    self = [super init];
	if (self)
    {
        fm		 = [NSFileManager defaultManager];
        settings = [MPSettings sharedInstance];
        agent 	 = settings.agent;
		
		[self setPatchMustShutdown:NO];

        if (agent.patchClient == 1 || agent.patchServer == 1) {
            [self setAllowClient:YES];
        } else {
            [self setAllowClient:NO];
        }
        
        if (agent.patchServer == 1) {
            [self setAllowServer:YES];
        } else {
            [self setAllowServer:NO];
        }
		
    }
    return self;
}

#pragma mark -
#pragma mark Class Methods
//=========================================================== 
//  methods
//===========================================================

#pragma mark - Delegate

- (void)postStringToDelegate:(NSString *)str, ...
{
	va_list va;
	va_start(va, str);
	NSString *string = [[NSString alloc] initWithFormat:str arguments:va];
	va_end(va);
	
	qltrace(@"%@",string);
	[self.delegate asusProgress:string];
}

#pragma mark softwareupdate methods

- (NSArray *)scanForAppleUpdates
{
	MPASUSCatalogs *aCat = [MPASUSCatalogs new];
	[aCat checkAndSetCatalogURL];
	
	qlinfo(@"Scanning for Apple software updates.");
	[self postStringToDelegate:@"Configuring Apple software update scan."];
	
	NSArray *appleUpdates = nil;
	
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: ASUS_BIN_PATH];
	[task setArguments: [NSArray arrayWithObjects: @"-l", nil]];
	
	//if ((int)NSAppKitVersionNumber >= 1504 /* 10.12 */) {
	//	[task setArguments: [NSArray arrayWithObjects: @"-l", @"--include-config-data", nil]];
	//} else {
	//	[task setArguments: [NSArray arrayWithObjects: @"-l", nil]];
	//}
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	[task setStandardError: pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[task launch];
	qlinfo(@"Starting Apple software update scan.");
	[self postStringToDelegate:@"Scanning for Apple software updates."];
	[task waitUntilExit];
	
	int status = [task terminationStatus];
	if (status != 0) {
		qlinfo(@"Error: softwareupdate exit code = %d",status);
		[self postStringToDelegate:@"Error: softwareupdate exit code = %d",status];
		return appleUpdates;
	} else {
		qlinfo(@"Apple software update scan was completed.");
		[self postStringToDelegate:@"Apple software update scan was completed."];
	}

	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	qldebug(@"Apple software update full scan results\n%@",string);
	
	if (!([string rangeOfString:@"No new"].location == NSNotFound)) {
		qlinfo(@"No new updates.");
		[self postStringToDelegate:@"No new Apple updates."];
		return appleUpdates;
	}
	
	// We have updates so we need to parse the results
	NSArray *strArr = [NSArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
	
	NSMutableArray *tmpAppleUpdates = [[NSMutableArray alloc] init];
	NSString *tmpStr, *lineCleanStart;
	NSMutableDictionary *tmpDict;
	
	for (int i=0; i<[strArr count]; i++)
	{
		// Ignore empty lines
		if ([[strArr objectAtIndex:i] length] != 0)
		{
			NSString *_line = strArr[i];
			//Clear the tmpDict object before populating it
			if (!([_line rangeOfString:@"Software Update Tool"].location == NSNotFound)) continue;
			if (!([_line rangeOfString:@"Copyright"].location == NSNotFound)) continue;
			
			// Strip the White Space and any New line data
			tmpStr = [_line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([tmpStr hasPrefix:@"*"] || [tmpStr hasPrefix:@"!"])
			{
				@try
				{
					lineCleanStart = [self cleanLine:_line];
					tmpDict = [[NSMutableDictionary alloc] init];
					[tmpDict setObject:lineCleanStart forKey:@"patch"];
					[tmpDict setObject:@"Apple" forKey:@"type"];
					[tmpDict setObject:[[lineCleanStart componentsSeparatedByString:@"-"] lastObject] forKey:@"version"];
					if (@available(macOS 10.15, *)) {
						// macOS 10.13 or later code path
						[tmpDict setObject:[[strArr objectAtIndex:(i+1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"description"];
						[tmpDict setObject:[self getSizeFromDescription:[tmpDict objectForKey:@"description"]] forKey:@"size"];
						[tmpDict setObject:([[tmpDict objectForKey:@"description"] containsString:@"Recommended: YES"] ? @"Y": @"N") forKey:@"recommended"];
						[tmpDict setObject:([[tmpDict objectForKey:@"description"] containsString:@"Action: restart"] ? @"Yes": @"No") forKey:@"restart"];
					} else {
						// code for earlier than 10.15
						[tmpDict setObject:[[strArr objectAtIndex:(i+1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"description"];
						[tmpDict setObject:[self getSizeFromDescription:[tmpDict objectForKey:@"description"]] forKey:@"size"];
						[tmpDict setObject:([[tmpDict objectForKey:@"description"] containsString:@"[recommended]"] ? @"Y": @"N") forKey:@"recommended"];
						[tmpDict setObject:([[tmpDict objectForKey:@"description"] containsString:@"[restart]"] ? @"Yes": @"No") forKey:@"restart"];
					}
					
					
					[tmpAppleUpdates addObject:[tmpDict copy]];
					tmpDict = nil;
				}
				@catch (NSException *exception)
				{
					qlerror(@"Error create patch dict. %@",exception);
				}
			}
		} // if / empty lines
	} // for loop
	
	appleUpdates = [NSArray arrayWithArray:tmpAppleUpdates];
	qldebug(@"Apple Updates Found, %@",appleUpdates);
	return appleUpdates;
}

- (BOOL)installAppleSoftwareUpdate:(NSString *)approvedUpdate
{
	[self postStringToDelegate:@"Install %@",approvedUpdate];
	[self setPatchMustShutdown:NO];
	BOOL result = FALSE;

	NSMutableDictionary *environment = [NSMutableDictionary new];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[environment setObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
	
	NSError *taskErr = nil;
	MPNSTask *_task = [MPNSTask new];
	_task.delegate = self;
	NSString *taskStr = [_task runTask:ASUS_BIN_PATH binArgs:@[@"-i", approvedUpdate] environment:environment error:&taskErr];
	if (taskErr) {
		qlerror(@"Error installing %@.",approvedUpdate);
		qlerror(@"%@.",taskErr.localizedDescription);
	} else {
		qltrace(@"%@",taskStr);
		result = TRUE;
		if ([taskStr containsString:@"computer must shut down." ignoringCase:YES])
		{
			[self setPatchMustShutdown:YES];
		} else if ([taskStr containsString:@"Error installing updates." ignoringCase:YES]) {
			result = FALSE;
		}
		
	}

	return result;
}

- (BOOL)downloadAppleUpdate:(NSString *)updateName
{
    qlinfo(@"Downloading Apple software update %@.",updateName);
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: ASUS_BIN_PATH];
    [task setArguments: [NSArray arrayWithObjects: @"--download", updateName, nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    qlinfo(@"Starting Apple software update download.");
    [task waitUntilExit];
    
    int status = [task terminationStatus];
    if (status != 0) {
        qlinfo(@"Error: softwareupdate exit code = %d",status);
        return NO;
    } else {
        qlinfo(@"Apple software update download completed.");
    }
    
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    qldebug(@"Apple software update full download results\n%@",string);
    
    if (!([string rangeOfString:@"No new"].location == NSNotFound)) {
        qlinfo(@"No new updates.");
        return NO;
    }

    return YES;
}

#pragma mark - Delegate Methods
- (void)taskStatus:(MPNSTask *)mpNSTask status:(NSString *)statusStr
{
	if ([[statusStr trim] length] != 0)
	{
		if ([statusStr containsString:@"PackageKit: Missing bundle path"] == NO)
		{
			[self postStringToDelegate:statusStr];
		} else {
			logit(lcl_vDebug,@"%@",statusStr);
		}
	}
}

#pragma mark -
#pragma mark Helper Methods
//=========================================================== 
//  Helper Methods
//===========================================================

- (void)taskTimeoutThread
{
	@autoreleasepool
	{
		[_asusTimeoutTimer invalidate];
		
		logit(lcl_vInfo,@"Timeout is set to %d",_taskTimeoutValue);
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:_taskTimeoutValue
														  target:self
														selector:@selector(taskTimeout:)
														userInfo:nil
														 repeats:NO];
		[self setAsusTimeoutTimer:timer];
		while (_taskTimedOut == NO && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
	}
	
}

- (void)taskTimeout:(NSNotification *)aNotification
{
	logit(lcl_vInfo,@"Task timedout, killing task.");
	[_asusTimeoutTimer invalidate];
	[self setTaskTimedOut:YES];
	[task terminate];
}

// Software Update result method
// Will clean a line of text
- (NSString *)cleanLine:(NSString *)line
{
	// Removes the beginning of the line
	NSString *component = @"*";
	NSString *_lineTrimed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (@available(macOS 10.15, *))
	{
		if ([_lineTrimed hasPrefix:@"* Label:"])
		{
			component = @"* Label: "; // >= 10.15
		}
		else if ([_lineTrimed hasPrefix:@"!"])
		{
			component = @"! ";
		}
	}
	else
	{
		if ([_lineTrimed hasPrefix:@"*"])
		{
			component = @"* ";
		}
		else if ([_lineTrimed hasPrefix:@"!"])
		{
			component = @"! ";
		}
	}

	NSMutableArray *items = [[line componentsSeparatedByString:component] mutableCopy];
	[items removeObjectAtIndex:0];
	// With first item removed put it all back together
	return  [items componentsJoinedByString:component];
}

// Software Update result method
// Get the size from a line of text
- (NSString *)getSizeFromDescription:(NSString *)aDesc
{
	NSString *tmpStr = @"0";
	if (@available(macOS 10.15, *))
	{
		NSArray *tmpArr = [aDesc componentsSeparatedByString:@","];
		for (NSString *l in tmpArr) {
			if ([l containsString:@"Size:"]) {
				tmpStr = [[[l componentsSeparatedByString:@":"] lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				break;
			}
		}
	}
	else
	{
		tmpStr = [[aDesc componentsSeparatedByString:@","] lastObject];
		tmpStr = [[[tmpStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "] firstObject];
	}
	return tmpStr;
}

// Software Update result method
// Get recommendaed state from line of text
- (NSString *)getRecommendedFromDescription:(NSString *)aDesc
{
	NSRange textRange;
	textRange =[aDesc rangeOfString:@"recommended"];
	
	if(textRange.location != NSNotFound) {
		return @"Y";
	} else {
		return @"N";
	}
	
	return @"N";
}

@end
