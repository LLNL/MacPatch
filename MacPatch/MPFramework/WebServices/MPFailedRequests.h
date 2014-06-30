//
//  MPFailedRequests.h
//  MPLibrary
//
//  Created by Heizer, Charles on 5/13/14.
//
//

#import <Foundation/Foundation.h>

@interface MPFailedRequests : NSObject
{
    NSFileManager *fm;
}

- (NSDictionary *)readFailedRequestsPlist;
- (BOOL)writeFailedRequestsPlist:(NSDictionary *)aRequests;
- (BOOL)addFailedRequest:(NSString *)methodName params:(NSDictionary *)aParams errorNo:(NSInteger)errorNo errorMsg:(NSString *)errorMsg;
- (BOOL)postFailedRequests;

@end
