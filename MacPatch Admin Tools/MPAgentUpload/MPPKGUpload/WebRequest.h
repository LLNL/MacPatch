//
//  WebRequest.h
//  MPPKGUpload
//
//  Created by Heizer, Charles on 5/13/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebRequest : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, assign, readonly) BOOL isRunnng;
@property (nonatomic, strong, readonly) NSData *responseData;
@property (nonatomic, assign, readonly) BOOL connectionDidFinishLoading;

- (id)init;
- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)aResponse error:(NSError **)error;
@end
