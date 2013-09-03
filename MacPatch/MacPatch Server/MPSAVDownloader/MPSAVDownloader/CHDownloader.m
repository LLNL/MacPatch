//
//  CHDownloader.m
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

#import "CHDownloader.h"

@interface NSURLRequest (SomePrivateAPIs)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(id)fp8;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)fp8 forHost:(id)fp12;
@end

@implementation CHDownloader

@synthesize fileURL, filePath;
@synthesize isDownloading;


- (id)initWithURL:(NSURL *)theURL toPath:(NSString *)downloadPath
{
	self = [super init];
	if (theURL) {
		
		
		theRequest = [NSURLRequest requestWithURL:theURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        theDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
		
		if (theDownload) {	
			// set the destination file now
			NSString *xPath = [downloadPath stringByAppendingPathComponent:[fileURL lastPathComponent]];
			
			[theDownload setDestination:xPath allowOverwrite:YES];
			isDownloading = YES;
		} else {
			// inform the user that the download could not be made
			logit(lcl_vError,@"Error: Unable to start the download.");
			isDownloading = NO;
		}		
	}

	return self;
}

- (void)startDownloadingURL
{
    // create the request	
    theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:fileURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	theDownload=[[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
	
    if (theDownload) {	
		isDownloading = YES;
    } else {
        // inform the user that the download could not be made
		logit(lcl_vError,@"Error: Unable to start the download.");
		isDownloading = NO;
    }
}

#pragma mark NSURLDownloadDelegate methods
			
- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{	
	NSFileManager *dFM = [NSFileManager defaultManager];
	logit(lcl_vInfo,@"Saving downloaded files to %@",filePath);
	if (![dFM fileExistsAtPath:filePath]) {
		logit(lcl_vInfo,@"Missing %@",filePath);
        [dFM createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:NULL];
		logit(lcl_vInfo,@"Created %@",filePath);
	}
	logit(lcl_vInfo,@"Downloading %@",filename);
	[download setDestination:[filePath stringByAppendingPathComponent:filename] allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    // release the connection
    [download release];
	
    // inform the user
    logit(lcl_vError,@"Download failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	isDownloading = NO;
}

-(void)downloadDidBegin:(NSURLDownload *)download
{
	logit(lcl_vInfo,@"Download Did Begin");
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    // release the connection
    [download release];
	
    // do something with the data
    logit(lcl_vInfo,@"Download Did Finish");
	isDownloading = NO;
}

- (void) dealloc {
	[super dealloc]; 
}

@end
