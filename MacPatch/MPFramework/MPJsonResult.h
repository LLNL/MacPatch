//
//  MPJsonResult.h
//  MPAgentNewWin
//
//  Created by Heizer, Charles on 3/19/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPJsonResult : NSObject
{
    NSData          *jsonData;
}

@property (nonatomic, strong) NSData *jsonData;

- (id)initWithJSONData:(NSData *)aJsonDataObj;
- (id)returnResult:(NSError **)aError;
- (id)returnJsonResult:(NSError **)aError;
- (id)deserializeJSONString:(NSString *)JSONString error:(NSError **)aError;
- (NSString *)serializeJSONDataAsString:(NSDictionary *)aData error:(NSError **)aError;

@end
