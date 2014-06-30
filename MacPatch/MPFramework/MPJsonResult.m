//
//  MPJsonResult.m
//  MPAgentNewWin
//
//  Created by Heizer, Charles on 3/19/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "MPJsonResult.h"

#undef  ql_component
#define ql_component lcl_cMPJsonResult

@implementation MPJsonResult

@synthesize jsonData = _jsonData;

- (id)initWithJSONData:(NSData *)aJsonDataObj
{
    self = [super init];
    if (self) {
        self.jsonData = aJsonDataObj;
    }
    return self;
}

- (id)returnResult:(NSError **)aError
{
    NSError *err = nil;
    NSMutableDictionary *errInfo = [NSMutableDictionary dictionary];

    id jMsgResult = [NSJSONSerialization JSONObjectWithData:self.jsonData options:kNilOptions error:&err];
    // Check for valid object
    if (err)
    {
        if (aError) {
            *aError = err;
            return nil;
        } else {
            qlerror(@"%@",err.localizedDescription);
        }
    }
    if ([jMsgResult objectForKey:@"errorno"])
    {
        // Has errorno object, and return was not 0
        if ([[jMsgResult objectForKey:@"errorno"] integerValue] != 0) {
            NSString *errMsg = @" ";
            if ([jMsgResult objectForKey:@"errormsg"]) {
                errMsg = [jMsgResult objectForKey:@"errormsg"];
            }
            if (aError) {
                [errInfo setValue:errMsg forKey:NSLocalizedDescriptionKey];
                *aError = [NSError errorWithDomain:NSOSStatusErrorDomain code:1001 userInfo:errInfo];
            } else {
                qlerror(@"Error [1001]: ErrorNo = %@, %@",[jMsgResult objectForKey:@"errorno"],errMsg);
            }
            return nil;
        }

        // Check for result object
        if (![jMsgResult objectForKey:@"result"]) {
            [errInfo setValue:@"result object is missing." forKey:NSLocalizedDescriptionKey];
            *aError = [NSError errorWithDomain:NSOSStatusErrorDomain code:1002 userInfo:errInfo];
            return nil;
        }


        return [jMsgResult objectForKey:@"result"];
    }
    else
    {
        if (aError) {
            [errInfo setValue:@"errorno object is missing." forKey:NSLocalizedDescriptionKey];
            *aError = [NSError errorWithDomain:NSOSStatusErrorDomain code:1001 userInfo:errInfo];
            return nil;
        }
    }

    qlerror(@"Should never reach end of this method...");
    return nil;
}

- (id)returnJsonResult:(NSError **)aError
{
    NSError *err = nil;
    NSMutableDictionary *errInfo = [NSMutableDictionary dictionary];

    id jMsgResult = [NSJSONSerialization JSONObjectWithData:self.jsonData options:kNilOptions error:&err];
    // Check for valid object
    if (err)
    {
        if (aError) {
            *aError = err;
            return nil;
        } else {
            qlerror(@"%@",err.localizedDescription);
        }
    }
    if ([jMsgResult objectForKey:@"errorno"])
    {
        // Has errorno object, and return was not 0
        if ([[jMsgResult objectForKey:@"errorno"] integerValue] != 0) {
            NSString *errMsg = @" ";
            if ([jMsgResult objectForKey:@"errormsg"]) {
                errMsg = [jMsgResult objectForKey:@"errormsg"];
            }
            if (aError) {
                [errInfo setValue:errMsg forKey:NSLocalizedDescriptionKey];
                *aError = [NSError errorWithDomain:NSOSStatusErrorDomain code:1001 userInfo:errInfo];
            } else {
                qlerror(@"Error [1001]: ErrorNo = %@, %@",[jMsgResult objectForKey:@"errorno"],errMsg);
            }
            return nil;
        }

        // Check for result object
        if (![jMsgResult objectForKey:@"result"]) {
            [errInfo setValue:@"result object is missing." forKey:NSLocalizedDescriptionKey];
            *aError = [NSError errorWithDomain:NSOSStatusErrorDomain code:1002 userInfo:errInfo];
            return nil;
        }


        if ([[jMsgResult objectForKey:@"result"] isKindOfClass:[NSArray class]] || [[jMsgResult objectForKey:@"result"] isKindOfClass:[NSDictionary class]])
        {
            return [jMsgResult objectForKey:@"result"];
        }
        else if ([[jMsgResult objectForKey:@"result"] isKindOfClass:[NSNumber class]])
        {
            qldebug(@"%@",[jMsgResult objectForKey:@"result"]);
            return [jMsgResult objectForKey:@"result"];
        }
        else
        {
            err = nil;
            id altResult = [NSJSONSerialization JSONObjectWithData:[[jMsgResult objectForKey:@"result"] dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
            // Check for a Error
            if (err) {
                if (aError) {
                    *aError = err;
                } else {
                    qlerror(@"%@",err.localizedDescription);
                }
                return [jMsgResult objectForKey:@"result"];
            }

            // No error, now check if it's a json object or string result.
            BOOL isValidJSONObj = [NSJSONSerialization isValidJSONObject:altResult];
            if (!isValidJSONObj) {
                return [jMsgResult objectForKey:@"result"];
            }

            return altResult;
        }

        return nil;
    }
    else
    {
        if (aError) {
            [errInfo setValue:@"errorno object is missing." forKey:NSLocalizedDescriptionKey];
            *aError = [NSError errorWithDomain:NSOSStatusErrorDomain code:1001 userInfo:errInfo];
            return nil;
        }
    }

    qlerror(@"Should never reach end of this method...");
    return nil;
}

- (id)deserializeJSONString:(NSString *)JSONString error:(NSError **)aError
{
    NSData *jData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    id jObj = [NSJSONSerialization JSONObjectWithData:jData options:NSJSONReadingMutableContainers error:&err];
    if (err)
    {
        if (aError) {
            *aError = err;
            return nil;
        } else {
            qlerror(@"%@",err.localizedDescription);
        }
    }

    return jObj;
}

- (NSString *)serializeJSONDataAsString:(NSDictionary *)aData error:(NSError **)aError
{
    NSError *error = nil;
    NSData *jData = [NSJSONSerialization dataWithJSONObject:aData options:0 error:&error];
    if (error) {
        if (aError) {
            *aError = error;
            return nil;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
    }
    NSString *jString = [[NSString alloc] initWithBytes:[jData bytes] length:[jData length] encoding:NSUTF8StringEncoding];
    return jString;
}


@end
