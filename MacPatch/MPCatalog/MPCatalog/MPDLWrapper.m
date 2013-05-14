//
// MPDLWrapper.m
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

#import "MPDLWrapper.h"

@implementation MPDLWrapper

// Do basic initialization
- (id)initWithController:(id <MPDLWrapperController>)cont url:(NSURL *)aURL
{
    self = [super init];
    
	controller = cont;
    downloadURL = [aURL retain];
	isRunning = NO;
    errorCode = -1;
	
    return self;
}

- (void)dealloc
{
    [self stopDownload];
    [super dealloc];
}

// Here's where we actually kick off the download.
- (BOOL) startDownload
{
    return [self startDownloadAndSpecifyDownloadDirectory:@"/private/tmp"];
}
- (BOOL) startDownloadAndSpecifyDownloadDirectory:(NSString *)aDirectory 
{
    // We first let the controller know that we are starting
    [controller downloadStarted];
    
    logit(lcl_vInfo,@"Download URL: %@",downloadURL);
    
	asiRequest = [ASIHTTPRequest requestWithURL:downloadURL];
    [asiRequest setValidatesSecureCertificate:NO];
	[asiRequest setTimeOutSeconds:300.0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:aDirectory] == NO) {
        [fm createDirectoryAtPath:aDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    [asiRequest setDownloadDestinationPath:[aDirectory stringByAppendingPathComponent:[downloadURL lastPathComponent]]];
	[asiRequest setTemporaryFileDownloadPath:[[@"/private/tmp" stringByAppendingPathComponent:[downloadURL lastPathComponent]] stringByAppendingPathExtension:@"download"]];
	
	[asiRequest setDownloadProgressDelegate:self];
	[asiRequest setDelegate:self];
	
	curValLong = 0;
	maxValLong = 0;
	
    [asiRequest startAsynchronous];  
	[controller downloadStarted];
	
	isRunning = YES;
	while (isRunning == YES) {
		sleep(1);
	}
	
	return YES;
}

- (void) stopDownload
{
	[asiRequest cancel];
	[controller downloadFinished];
	controller = nil;
}

- (int) returnCode
{
    return errorCode;
}
#pragma mark -
#pragma mark ASIHTTPRequest Delegates
- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
	
    isRunning = NO;
    errorCode = (int)[error code];
	[controller downloadFinished];
	controller = nil;
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	logit(lcl_vError,@"%@",[error description]);
	
	isRunning = NO;
    errorCode = (int)[error code];
	[controller downloadError];
	controller = nil;
}
- (void)request:(ASIHTTPRequest *)request incrementDownloadSizeBy:(long long)newLength
{
	[self request:request didReceiveBytes:0];
	maxValLong = newLength;
}
- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes;
{
	curValLong = (curValLong + bytes);
	if (curValLong != 0) {
		[controller appendDownloadProgress:(((double)curValLong / (double)maxValLong) * 100)];
		[controller appendDownloadProgressPercent:[NSString stringWithFormat:@"%.0f%",((double)curValLong / (double)maxValLong) * 100]];
	}	
}


@end

