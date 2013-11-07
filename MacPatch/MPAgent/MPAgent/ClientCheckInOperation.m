//
//  ClientCheckInOperation.m
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

#import "ClientCheckInOperation.h"
#import "MPAgent.h"
#import "MPDefaultsWatcher.h"


@interface ClientCheckInOperation (Private)

- (void)runCheckIn;

@end


@implementation ClientCheckInOperation

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

- (void)dealloc
{
	[super dealloc];
}

- (BOOL) isConcurrent 
{
    return YES;
}

- (void) finish 
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void) start 
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
		[self runCheckIn];
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"[NSException]: %@",e);
	}
	[self finish];
}

- (void)runCheckIn
{
	NSAutoreleasePool *rPool = [[NSAutoreleasePool alloc] init];
	NSMutableDictionary *agentDict;
	logit(lcl_vInfo,@"Running client check in.");
	@try {
        NSDictionary *consoleUserDict = [MPSystemInfo consoleUserData];
        NSDictionary *hostNameDict = [MPSystemInfo hostAndComputerNames];
        
		NSDictionary *clientVer = nil;
		if ([fm fileExistsAtPath:AGENT_VER_PLIST]) {
			if ([fm isReadableFileAtPath:AGENT_VER_PLIST] == NO ) {
                [fm setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0664UL] forKey:NSFilePosixPermissions]
                     ofItemAtPath:AGENT_VER_PLIST 
                            error:NULL];
			}
			clientVer = [NSDictionary dictionaryWithContentsOfFile:AGENT_VER_PLIST];	
		} else {
			clientVer = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"NA",@"NA",@"NA",@"NA",@"NA",@"NA",nil] 
													forKeys:[NSArray arrayWithObjects:@"version",@"major",@"minor",@"bug",@"build",@"framework",nil]];
		}
		
		agentDict = [[[NSMutableDictionary alloc] init] autorelease];
		[agentDict setObject:[si g_cuuid] forKey:@"cuuid"];
		[agentDict setObject:[si g_serialNo] forKey:@"serialno"];
		[agentDict setObject:[hostNameDict objectForKey:@"localHostName"] forKey:@"hostname"];
		[agentDict setObject:[hostNameDict objectForKey:@"localComputerName"] forKey:@"computername"];
		[agentDict setObject:[consoleUserDict objectForKey:@"consoleUser"] forKey:@"consoleUser"];
		[agentDict setObject:[MPSystemInfo getIPAddress] forKey:@"ipaddr"];
		[agentDict setObject:[MPSystemInfo getMacAddressForInterface:@"en0"] forKey:@"macaddr"];
		[agentDict setObject:[si g_osVer] forKey:@"osver"];
		[agentDict setObject:[si g_osType] forKey:@"ostype"];
		[agentDict setObject:[si g_agentVer] forKey:@"agent_version"];
		[agentDict setObject:[clientVer objectForKey:@"build"] forKey:@"agent_build"];
		[agentDict setObject:[clientVer objectForKey:@"version"] forKey:@"client_version"];
		[agentDict setObject:@"false" forKey:@"needsreboot"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/tmp/.MPAuthRun"]) {
			[agentDict setObject:@"true" forKey:@"needsreboot"];	
		}
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"[NSException]: %@",e);
		logit(lcl_vError,@"No client checkin data will be posted.");
		goto done;
		return;
	}	
	
	mpj = [[MPJson alloc] init];
	
	NSError *err = nil;
	BOOL postResult = NO;
	@try {
		err = nil;
		if (mpj) {
			postResult = [mpj postJSONDataForMethod:@"client_checkin_base" data:agentDict error:&err];
			if (err) {
				logit(lcl_vError,@"%@",[err localizedDescription]);
			}	
			if (postResult) {
				logit(lcl_vInfo,@"Running client base checkin, returned true.");
			} else {
				logit(lcl_vError,@"Running client base checkin, returned false.");
			}
		}
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"[NSException]: %@",e);
	}
	
	// Read Client Plist Info, and post it...
	@try {
		MPDefaultsWatcher *mpd = [[[MPDefaultsWatcher alloc] init] autorelease];
		NSMutableDictionary *mpDefaults = [[[NSMutableDictionary alloc] initWithDictionary:[mpd readConfigPlist]] autorelease];
		[mpDefaults setObject:[si g_cuuid] forKey:@"cuuid"];
		
		err = nil;
		postResult = [mpj postJSONDataForMethod:@"client_checkin_plist" data:mpDefaults error:&err];
		if (err) {
			logit(lcl_vError,@"%@",[err localizedDescription]);
		}	
		if (postResult) {
			logit(lcl_vInfo,@"Running client config checkin, returned true.");
		} else {
			logit(lcl_vError,@"Running client config checkin, returned false.");
		}
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"[NSException]: %@",e);
	}	
	
	[mpj release];
done:	
	logit(lcl_vInfo,@"Running client check in completed.");	
	[rPool release];
}

@end
