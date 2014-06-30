//
//  MPProxySyncController.m
//  MPProxySync
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

#import "MPProxySyncController.h"
#import "MacPatch.h"
#include "FileMD5Hash.h"

#include <curl/curl.h>
#include <stdio.h>
#include <unistd.h>


#define CONTENT_DIR @"/Library/MacPatch/Content/Web"
#define APP_USER    @"_appserver"
#define WWW_USER    @"_www"

@implementation MPProxySyncController

@synthesize defaults;
@synthesize remotePatchContent;
@synthesize numberOfPatchesSyncronnized;
@synthesize logResult;

- (id)initWithDefaults:(NSDictionary *)aDictionary
{
    self = [super init];
    if (self) {
        [self setDefaults:aDictionary];
        prefs = [[MPDefaults alloc] initWithDictionary:self.defaults];
        numberOfPatchesSyncronnized = 0;
		[self setLogResult:@"***** MPProxySync started *****\n"];
    }
    
    return self;
}

- (void)syncContent
{
    qlinfo(@"Syncronize patch content...");
    if ([self createBaseContentDirs] == NO)
        return;
    NSError *error = nil;
    NSArray *remoteContent;
    remoteContent = [self getRemotePatchContentForMethod:@"getDistributionContentAsJSON" error:&error];
    if (error) {
        qlerror(@"%@",error.localizedDescription);
        qlerror(@"Patch content will not be syncronized.");
        return;
    }

    int l_noOfPatches = 0;
    l_noOfPatches = (int)[remoteContent count] + 1;
    [self setLogResult:[NSString stringWithFormat:@"%@\n%d patches to syncronize.",logResult, l_noOfPatches]];
	qlinfo(@"%d patches to syncronize.",l_noOfPatches);
    
    BOOL dlContent = NO;
    dlContent = [self downloadPatchContent:remoteContent];

    [self setLogResult:[NSString stringWithFormat:@"%@\n%d were syncronized.",logResult, numberOfPatchesSyncronnized]];
    qlinfo(@"%d were syncronized.",numberOfPatchesSyncronnized);
    [self setLogResult:[NSString stringWithFormat:@"%@\nSyncronize complete.",logResult]];
    qlinfo(@"Syncronize complete.");
    error = nil;
	[self postSyncResults:&error];
    if (error) {
        qlerror(@"%@",error.localizedDescription);
    }
}

- (void)syncSWContent
{
    qlinfo(@"Syncronize software content...");
    if ([self createBaseContentDirs] == NO)
        return;

    NSError *error = nil;
    NSArray *remoteContent;
    remoteContent = [self getRemotePatchContentForMethod:@"getSWDistributionContentAsJSON" error:&error];
    if (error) {
        qlerror(@"%@",error.localizedDescription);
        qlerror(@"Software content will not be syncronized.");
        return;
    }

    int l_noOfPatches = 0;
    l_noOfPatches = (int)[remoteContent count] + 1;
    [self setLogResult:[NSString stringWithFormat:@"%@\n%d software packages to syncronize.",logResult, l_noOfPatches]];
	qlinfo(@"%d software packages to syncronize.",l_noOfPatches);

    BOOL dlContent = NO;
    dlContent = [self downloadPatchContent:remoteContent];

    [self setLogResult:[NSString stringWithFormat:@"%@\n%d were syncronized.",logResult, numberOfPatchesSyncronnized]];
    qlinfo(@"%d were syncronized.",numberOfPatchesSyncronnized);
    [self setLogResult:[NSString stringWithFormat:@"%@\nSyncronize complete.",logResult]];
    qlinfo(@"Syncronize complete.");
	[self postSyncResults:&error];
    if (error) {
        qlerror(@"%@",error.localizedDescription);
    }
}

- (BOOL)createBaseContentDirs
{
    return [self createBaseContentDirs:CONTENT_DIR];
}

- (BOOL)createBaseContentDirs:(NSString *)aDIR
{
    BOOL result = YES;
    NSDictionary *root_attribs, *web_attribs;
    root_attribs = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:0], NSFileGroupOwnerAccountID,
                            [NSNumber numberWithInt:80], NSFileOwnerAccountID,
                            @"root", NSFileGroupOwnerAccountName,
                            @"admin", NSFileOwnerAccountName, nil ];
    
    web_attribs = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:79], NSFileGroupOwnerAccountID,
                                  [NSNumber numberWithInt:70], NSFileOwnerAccountID,
                                  @"_appserver", NSFileGroupOwnerAccountName,
                                  @"_www", NSFileOwnerAccountName, nil ];
    


    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *subPaths = [fileManager subpathsAtPath:aDIR];
    for (NSString *aPath in subPaths) {
        BOOL isDirectory;
        [fileManager fileExistsAtPath:aPath isDirectory:&isDirectory];
        if (isDirectory) {
            // Change the permissions on the directory here
            NSError *error = nil;
            if ([aPath isEqualToString:@"Web"]) {
                [fileManager setAttributes:root_attribs ofItemAtPath:aPath error:&error];
            } else {
                [fileManager setAttributes:web_attribs ofItemAtPath:aPath error:&error];
                if (error) {
					qlerror(@"%@",[error localizedDescription]);
                    result = NO;
                }
            }    
        }
    }
    return result;    
}

- (NSData *)requestWithMethodAndParams:(NSString *)aMethod params:(NSDictionary *)aParams error:(NSError **)err
{
    MPNetConfig *mpNetConfig = [[MPNetConfig alloc] init];

    NSError *error = nil;
    NSURLResponse *response;
    MPNetRequest *req = [[MPNetRequest alloc] initWithMPServerArray:[mpNetConfig servers]];
    [req setApiURI:@"/MPDistribution.cfc"];
    NSURLRequest *urlReq = [req buildGetRequestForWebServiceMethod:aMethod formData:aParams error:&error];
    error = nil;
    NSData *res = [req sendSynchronousRequest:urlReq returningResponse:&response error:&error];

    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return res;
}

- (NSArray *)getRemotePatchContentForMethod:(NSString *)method error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSData *res = [self requestWithMethodAndParams:@"getDistributionContentAsJSON" params:nil error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    NSDictionary *jResult;
    error = nil;
    jResult = [jres deserializeJSONString:[result objectForKey:@"result"] error:&error];
    if (error) {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    if ([jResult objectForKey:@"Content"]) {
        return [NSArray arrayWithArray:[jResult objectForKey:@"Content"]];
    } else {
        qlerror(@"Error, Content object not found.");
        return nil;
    }
}

/*
- (NSArray *)getRemotePatchContentForURL:(NSString *)aURL
{
    NSArray *result = nil;

    serverConnection = [[MPServerConnection alloc] initWithDefaults:[prefs defaults]];
    asiNet = [[MPASINet alloc] initWithServerConnection:serverConnection];

    NSDictionary    *jsonResult = nil;
    NSString        *requestData;
    NSError         *error = nil;
    requestData = [asiNet synchronousRequestForURL:aURL error:&error];

    if (error) {
		qlerror(@"%@",[error localizedDescription]);
		return nil;
	}

    NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        jsonResult = [[deserializedData objectForKey:@"result"] objectFromJSONString];
        if ([[jsonResult objectForKey:@"errorno"] intValue] != 0) {
            qlerror(@"Error[%@]: %@",[jsonResult objectForKey:@"errorno"],[jsonResult objectForKey:@"errormsg"]);
            return nil;
		}
    }
    @catch (NSException *exception) {
        qlerror(@"%@",exception);
        return nil;
    }

    result = [NSArray arrayWithArray:[jsonResult objectForKey:@"Content"]];

    return result;
}
*/

- (BOOL)postSyncResults:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"0" forKey:@"logType"];
    [params setObject:[logResult urlEncode] forKey:@"logData"];
    NSData *res = [self requestWithMethodAndParams:@"postSyncResultsJSON" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    return YES;
}

- (BOOL)downloadPatchContent:(NSArray *)aContent
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *l_path, *l_dirPath, *l_dlFile;
    BOOL isDir = NO;
    
    NSError *error = nil;
    for (int i = 0; i < [aContent count]; i++) 
    {
        l_path = [NSString stringWithFormat:@"%@%@",CONTENT_DIR,[[aContent objectAtIndex:i] objectForKey:@"pkg_url"]];
        l_dirPath = [l_path stringByDeletingLastPathComponent];
        if ([fm fileExistsAtPath:l_dirPath isDirectory:&isDir] == FALSE) {
            [fm createDirectoryAtPath:l_dirPath withIntermediateDirectories:YES attributes:nil error:&error];
            if(error) {
                qlerror(@"%@",[error localizedDescription]);
                qlerror(@"Skipping %@",[l_path lastPathComponent]);
                continue;
            }    
        }    
        
        if ([fm fileExistsAtPath:l_path]) {
            // Check Hash
            error = nil;
            if ([self checkFileHash:l_path validHash:[[aContent objectAtIndex:i] objectForKey:@"pkg_hash"]] == NO) {    
                if ([fm removeItemAtPath:l_path error:&error] == NO) {
                    qlerror(@"Trying to remove %@",l_path);
                    qlerror(@"%@",[error localizedDescription]);
                    qlerror(@"Skipping %@",[l_path lastPathComponent]);
                    continue;
                }
            } else {
                // Patch alread exists and the hash matches.
                continue; 
            }
        }
        // Download the new content
        error = nil;
        l_dlFile = [self downloadPatch:[[aContent objectAtIndex:i] objectForKey:@"pkg_url"] error:&error]; 
        if (error) {
            qlerror(@"%@",[error localizedDescription]);
            continue;
        }
        // Move Content Into Place
        error = nil;
        if ([self checkFileHash:l_dlFile validHash:[[aContent objectAtIndex:i] objectForKey:@"pkg_hash"]]) {     
            if ([fm moveItemAtPath:l_dlFile toPath:l_path error:&error]) {
                qlinfo(@"Moved file to %@", l_path);
                [self setNumberOfPatchesSyncronnized:(numberOfPatchesSyncronnized+1)];
            } else {
                if (error) {
                    qlerror(@"File not moved to %@", l_path);
                    qlerror(@"%@",[error localizedDescription]);
                    continue;
                }
            }    
        }    
    } 
    
    return YES;
}

- (BOOL)checkFileHash:(NSString *)aFilePath validHash:(NSString *)aValidHash
{
    BOOL result = NO;
    CFStringRef md5hash = FileMD5HashCreateWithPath((__bridge CFStringRef)aFilePath, FileHashDefaultChunkSizeForReadingData);
    
    if ([[(__bridge NSString *)md5hash uppercaseString] isEqualToString:[aValidHash uppercaseString]]) {
        result = YES;
    } else {
        qlerror(@"File hash failed for %@",[aFilePath lastPathComponent]);
    }

    CFRelease(md5hash);
    return result;    
}

- (NSString *)downloadPatch:(NSString *)aURL error:(NSError **)err
{
    NSString *theURL = [NSString stringWithFormat:@"http://%@/mp-content%@",[self.defaults objectForKey:@"MPServerAddress"],[aURL urlEncode]];
    
    qlinfo(@"Download: %@",theURL);
	NSString *tempFilePath = [self createTempDirFromURL:theURL];
    
	qlinfo(@"Download to: %@",tempFilePath);
	FILE *dlFile = fopen([tempFilePath UTF8String], "w");
    
    qldebug(@"Encoded URL: %@",[theURL urlEncode]);
	
	CURL *curl;
	CURLcode res;
	curl = curl_easy_init();
	if (curl) {
		// Set Options
		curl_easy_setopt( curl, CURLOPT_URL, [theURL  cStringUsingEncoding:NSUTF8StringEncoding] ) ;
		curl_easy_setopt( curl, CURLOPT_SSL_VERIFYPEER, FALSE);
		curl_easy_setopt( curl, CURLOPT_WRITEDATA, dlFile);
		// Run CURL
		res = curl_easy_perform( curl );
		if (res != 0)
		{
            if (err != NULL) {
                *err = [NSError errorWithDomain:@"libCurl" code:res userInfo:nil];
            } else {
                qlerror(@"Error[%d], trying to download file.",res);
            }
		}
	} else {
        if (err != NULL) {
            *err = [NSError errorWithDomain:@"libCurl" code:1 userInfo:nil];
        } else {
            qlerror(@"Error, trying to init curl lib.");
        }
	}

	// Clean up curl handle and file handle
	curl_easy_cleanup( curl );
	fclose(dlFile);

    return tempFilePath;
}

- (NSString *)createTempDirFromURL:(NSString *)aURL
{
	NSString *tempFilePath;
	
	NSString *appName = [[NSProcessInfo processInfo] processName];
	NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.XXXXXX",appName]];
	
	const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	char *tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
	strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
	char *result = mkdtemp(tempDirectoryNameCString);
	if (!result)
	{
		// handle directory creation failure
		qlerror(@"Error, trying to create tmp directory.");
	}
	
	NSString *tempDirectoryPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(result)];
	free(tempDirectoryNameCString);
	
	tempFilePath = [tempDirectoryPath stringByAppendingPathComponent:[aURL lastPathComponent]];
	return tempFilePath;
}

@end
