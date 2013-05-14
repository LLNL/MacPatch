//
// MPDLWrapper.h
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

#import <Foundation/Foundation.h>
#import "MacPatch.h"

@protocol MPDLWrapperController

- (void)appendDownloadProgress:(double)aNumber;
- (void)appendDownloadProgressPercent:(NSString *)aPercent;
- (void)downloadStarted;
- (void)downloadFinished;
- (void)downloadError;

@end

@interface MPDLWrapper : NSObject 
{
    id				<MPDLWrapperController>controller;
	
	ASIHTTPRequest	*asiRequest;
	NSURL			*downloadURL;
	long long		maxValLong;
	long long		curValLong;
	BOOL			isRunning;
    int             errorCode;
}

// This is the designated initializer - pass in your controller and any task arguments.
// The first argument should be the path to the executable to launch with the NSTask.
- (id)initWithController:(id <MPDLWrapperController>)controller url:(NSURL *)aURL;

// This method launches the process, setting up asynchronous feedback notifications.
- (BOOL) startDownload;
- (BOOL) startDownloadAndSpecifyDownloadDirectory:(NSString *)aDirectory;

// This method stops the process, stoping asynchronous feedback notifications.
- (void) stopDownload;
- (int) returnCode;

@end

