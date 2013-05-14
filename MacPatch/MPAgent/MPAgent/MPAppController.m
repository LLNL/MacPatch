//
//  MPAppController.m
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

#import "MPAppController.h"
#import	"MPDefaultsWatcher.h"
#import "MPAgent.h"
#import "MPTasks.h"
#import "MPTaskThread.h"

// Operations
#import "ClientCheckInOperation.h"
#import "AgentScanAndUpdateOperation.h"
#import "AntiVirusScanAndUpdateOperation.h"
#import "InventoryOperation.h"
#import	"PatchScanAndUpdateOperation.h"
#import "MPSWDistTaskOperation.h"

@implementation MPAppController

@synthesize useOperationQueue;

- (id)init 
{
	// Init plain is as daemon
	return [self initWithArg:0];
}

- (id)initWithArg:(int)aArg
{
	if (self = [super init]) {
		//Setup Signleton Manager for global iVars
		si = [MPAgent sharedInstance];
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:2];

		logit(lcl_vInfo,@"Client ID: %@",[si g_cuuid]);
		
		switch (aArg)
		{
			case 0:
				// Run as daemon
				[self runAsDaemon];
				break;
			case 1:
				// Run client checkin
				[self runClientCheckIn];
				break;
			case 2:
                // Run Inventory Collection
				[self runInventoryCollection];
				break;
			case 3:
                // Run PatchScan
                [self runPatchScan];
				break;	
			case 4:
				[self runPatchScanAndUpdate];
				break;	
			case 5:
				[self runAVInfoScan];
				break;
			case 6:
				[self runAVInfoScanAndDefsUpdate];
				break;
			case 7:
				[self scanAndUpdateAgentUpdater];
				break;
			case 99:
				// Run as daemon
				[self setUseOperationQueue:YES];
				[self runAsDaemon];
				break;	
			default:
				printf("Silly Rabbit, Trix are for Kids!\n");
				exit(1);
		}
    }
    return self;
}

- (void)dealloc
{
	[agentOp release];
	[clientOp release];
    [super dealloc];
}


- (void)runAsDaemon
{
	logit(lcl_vDebug,@"Run as daemon.");
	
	//Setup defaults watcher
	MPDefaultsWatcher *dw = [[MPDefaultsWatcher alloc] init];
	[NSThread detachNewThreadSelector:@selector(checkConfigThread) toTarget:dw withObject:nil];
	[NSThread detachNewThreadSelector:@selector(watchTasksPlistForChangesMethod) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(runTasksLoop) toTarget:self withObject:nil];
	
	// 10.5 Fix, run loop wont engadge otherwise
	NSLog(@"Getting current runloop mode ... %@",[[NSRunLoop currentRunLoop] currentMode]);
	[[NSRunLoop currentRunLoop] run];

	[dw release];
}

- (void)watchTasksPlistForChangesMethod
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	MPTasks *_t = [[MPTasks alloc] init];
	[_t readAndSetTasksFromPlist];
	
	MPDefaultsWatcher *defaultsWatcher; //Being Used for getting file Hash
	defaultsWatcher = [[MPDefaultsWatcher alloc] initForHash];
	
	NSString *_fHash;
	_fHash = [defaultsWatcher hashForFile:[_t _taskPlist] digest:@"MD5"];
	[defaultsWatcher release];
	
	unsigned int x = 0;
	BOOL keepRunning = YES;
	while (keepRunning)
	{
		// Every 30 Seconds Check to see if the tasks plist has been updated.
		if (x == 30) {
			x = 0;
			defaultsWatcher = [[MPDefaultsWatcher alloc] initForHash];
			if ([defaultsWatcher checkFileHash:[_t _taskPlist] fileHash:_fHash] == NO) {
				logit(lcl_vInfo,@"Tasks have been changed, reading in changes.");
				NSLock *lock = [NSLock new];
				[lock lock];
				_fHash = [defaultsWatcher hashForFile:[_t _taskPlist] digest:@"MD5"]; // Set new hash value
				[lock unlock];
				[_t readAndSetTasksFromPlist];
			}
			[defaultsWatcher release];
			defaultsWatcher = nil;
		}
		sleep(1);
		x++;
	}
	[_t release];
	[pool drain];
}

- (void)runTasksLoop
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	logit(lcl_vInfo,@"Starting tasks...");
	if (useOperationQueue == YES) {
		logit(lcl_vInfo,@"Using Operation Queue.");
	}
	
	// Set the tasks list ...
	MPTasks *mpt;
    NSDate *d;

	BOOL keepRunning = YES;
	while (keepRunning)
	{
		NSAutoreleasePool *innerpool = [[NSAutoreleasePool alloc] init];
		NSDictionary *taskDict;
		NSArray *tmpArr = [NSArray arrayWithArray:[si g_Tasks]];

		NSTimeInterval _n = 0;
		// Need to begin loop for tasks
		for (taskDict in tmpArr)
		{
			// If task is Active
			if ([[taskDict objectForKey:@"active"] isEqualToString:@"1"])
			{
				_n = [[NSDate now] timeIntervalSince1970]; 
				logit(lcl_vTrace,@"taskDict: %0.0f",_n);
				logit(lcl_vTrace,@"taskDict: %0.0f >: %0.0f", _n, [[NSDate shortDateFromString:[taskDict objectForKey:@"startdate"]] timeIntervalSince1970]);
				logit(lcl_vTrace,@"taskDict %0.0f <: %0.0f", _n, [[NSDate shortDateFromString:[taskDict objectForKey:@"enddate"]] timeIntervalSince1970]);
				if ( _n > [[NSDate shortDateFromString:[taskDict objectForKey:@"startdate"]] timeIntervalSince1970] && _n < [[NSDate shortDateFromString:[taskDict objectForKey:@"enddate"]] timeIntervalSince1970])				
				{	
					d = [[NSDate alloc] init]; // Get current date/time
					// Compare as long value, thus removing the floating point.
					if ([[taskDict objectForKey:@"nextrun"] longValue] == (long)[d timeIntervalSince1970]) 
					{
						if (useOperationQueue == YES) {
                            logit(lcl_vInfo,@"Run task (%@) via queue (%lu).",[taskDict objectForKey:@"cmd"],[queue.operations count]);
                            if ([queue.operations count] >= 20) {
                                logit(lcl_vError,@"Queue appears to be stuck with %lu waiting in queue. Purging queue now.",[queue.operations count]);
                                [queue cancelAllOperations];
                            }
                            
							if ([[taskDict objectForKey:@"cmd"] isEqualToString:@"kMPCheckIn"]) {
								clientOp = [[ClientCheckInOperation alloc] init];
								[queue addOperation:clientOp];
								[clientOp release], clientOp = nil;
							} else if ([[taskDict objectForKey:@"cmd"] isEqualToString:@"kMPAgentCheck"]) {
								agentOp = [[AgentScanAndUpdateOperation alloc] init];
								[queue addOperation:agentOp];
								[agentOp release], agentOp = nil;
							} else if ([[taskDict objectForKey:@"cmd"] isEqualToString:@"kMPAVCheck"]) {
								avOp = [[AntiVirusScanAndUpdateOperation alloc] init];
								[avOp setScanType:1];
								[queue addOperation:avOp];
								[avOp release], avOp = nil;
							} else if ([[taskDict objectForKey:@"cmd"] isEqualToString:@"kMPInvScan"]) {
								invOp = [[InventoryOperation alloc] init];
								[queue addOperation:invOp];
								[invOp release], invOp = nil;
							} else if ([[taskDict objectForKey:@"cmd"] isEqualToString:@"kMPVulScan"]) {
								patchOp = [[PatchScanAndUpdateOperation alloc] init];
								[queue addOperation:patchOp];
								[patchOp release], patchOp = nil;
							} else if ([[taskDict objectForKey:@"cmd"] isEqualToString:@"kMPVulUpdate"]) {
								patchOp = [[PatchScanAndUpdateOperation alloc] init];
								[patchOp setScanType:1];
								[queue addOperation:patchOp];
								[patchOp release], patchOp = nil;	
							} else if ([[taskDict objectForKey:@"cmd"] isEqualToString:@"kMPSWDistMan"]) {
								swDistOp = [[MPSWDistTaskOperation alloc] init];
								[queue addOperation:swDistOp];
								[swDistOp release], swDistOp = nil;	
							}
                            
						} else {
							[NSThread detachNewThreadSelector:@selector(runTask:) 
													 toTarget:[MPTaskThread class] 
												   withObject:[NSDictionary dictionaryWithDictionary:taskDict]];
						}
						
						mpt = [[MPTasks alloc] init];
						[mpt updateTaskRunAt:[taskDict objectForKey:@"id"]];
						[mpt release];
						mpt = nil;
						
					} else if ([[taskDict objectForKey:@"nextrun"] doubleValue] < [d timeIntervalSince1970]) {
						// Reschedule, we missed out date
						// Schedule for 30 seconds out
						logit(lcl_vInfo,@"We missed our task, rescheduled to run in 30 seconds.");
						mpt = [[MPTasks alloc] init];
						[mpt updateMissedTaskRunAt:[taskDict objectForKey:@"id"]];
						[mpt release];
						mpt = nil;
					}
					[d release];
					d = nil;
				}	
			}
		}
		[innerpool drain];
		sleep(1);
	}
	[pool drain];
}

-(void)runClientCheckIn
{
	[MPTaskThread runCheckIn];
	exit(0);
}

-(void)runInventoryCollection
{
	[MPTaskThread runInventoryCollection];
	exit(0);
}

-(void)runPatchScan
{
	[MPTaskThread runPatchScan];
	exit(0);
}

- (void)runPatchScanAndUpdate
{
	[MPTaskThread runPatchScanAndUpdate];
	exit(0);
}

- (void)runAVInfoScan
{
	[MPTaskThread runAVInfoScan];
	exit(0);
}

- (void)runAVInfoScanAndDefsUpdate
{
	[MPTaskThread runAVInfoScanAndDefsUpdate];
	exit(0);
}

-(void)scanAndUpdateAgentUpdater
{
	[MPTaskThread runAgentScanAndUpdate];
	exit(0);
}
				 
				 

@end
