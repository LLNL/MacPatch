//
//  GetServerListOperation.m
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

#import "GetServerListOperation.h"
#import "MPAgent.h"
#import "MPDefaultsWatcher.h"

@interface GetServerListOperation (Private)

- (void)checkServerList;
- (void)getServerList;

@end


@implementation GetServerListOperation

@synthesize isExecuting;
@synthesize isFinished;

- (id)init
{
	if ((self = [super init])) {
		isExecuting = NO;
        isFinished  = NO;
		si	= [MPAgent sharedInstance];
		fm	= [NSFileManager defaultManager];
	}

	return self;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (void)cancel
{
    [self finish];
}

- (void)finish
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start
{
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
    } else {
        [self willChangeValueForKey:@"isExecuting"];
		[self performSelectorInBackground:@selector(main) withObject:nil];
        isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)main
{
	@try {
		[self checkServerList];
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"[NSException]: %@",e);
	}
	[self finish];
}

- (void)checkServerList
{
	@autoreleasepool
    {
        logit(lcl_vInfo,@"Running server list scan and verify.");

        if (![fm fileExistsAtPath:[AGENT_SERVERS_PLIST stringByDeletingLastPathComponent]])
        {
            NSError *fmErr = nil;
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0775] forKey:NSFilePosixPermissions];
            [fm createDirectoryAtPath:[AGENT_SERVERS_PLIST stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:attributes error:&fmErr];
            if (fmErr) {
                qlerror(@"%@",fmErr.localizedDescription);
                return;
            }
        }

        NSError *slErr = nil;
        MPServerList *mpsl = [[MPServerList alloc] init];
        BOOL isCurrent = [mpsl usingCurrentMPHostList:&slErr];
        if (slErr) {
            qlerror(@"%@",slErr.localizedDescription);
            return;
        }

        if (isCurrent == NO) {
            slErr = nil;
            BOOL didGetList = [mpsl getServerListFromServer:&slErr];
            if (slErr) {
                qlerror(@"%@",slErr.localizedDescription);
                return;
            }
            if (didGetList) {
                qldebug(@"Server list was retrieved successfully.");
            } else {
                qlerror(@"Server list was not retrieved successfully.");
            }
        }

        logit(lcl_vInfo,@"Server list scan and verify completed.");
	}
}

@end
