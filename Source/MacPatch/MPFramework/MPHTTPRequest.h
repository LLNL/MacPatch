//
//  MPHTTPRequest.h
//
//  MPHTTPRequest uses NSURLSession for it's requests
//
//  Created by Charles Heizer on 9/15/17.
//  Copyright © 2017 LLNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWSResult;

@interface MPHTTPRequest : NSObject <NSURLSessionDelegate>

- (id)initWithAgentPlist;

/**
 ASyncronus GET Request

 @param urlPath - URL Path, server info will automatically be populated
 @param completion - MPWSResult object will get returned
 */
- (void)runASyncGET:(NSString *)urlPath completion:(void (^)(MPWSResult *result, NSError *error))completion;

/**
 ASyncronus POST Request

 @param urlPath - URL Path, server info will automatically be populated
 @param body Dictionary, will be converted to JSON object, use nil if empty
 @param completion - MPWSResult object will get returned
 */
- (void)runASyncPOST:(NSString *)urlPath body:(NSDictionary *)body completion:(void (^)(MPWSResult *result, NSError *error))completion;


/**
 Download a file using blocks

 @param urlPath - URL Path, server info will automatically be populated
 @param dlDir - Download Directory
 @param progressBar - NSProgressIndicator, use nil if empty
 @param progressPercent - Progress percent
 @param completion - File Name and File Path
 */
- (void)runDownloadRequest:(NSString *)urlPath downloadDirectory:(NSString *)dlDir
                  progress:(NSProgressIndicator *)progressBar progressPercent:(id)progressPercent
                completion:(void (^)(NSString *fileName, NSString *filePath, NSError *error))completion;

- (MPWSResult *)runSyncGET:(NSString *)urlPath;
- (MPWSResult *)runSyncGET:(NSString *)urlPath body:(NSDictionary *)body;
- (MPWSResult *)runSyncPOST:(NSString *)urlPath body:(NSDictionary *)body;

@end
