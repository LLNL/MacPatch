//
//  MPNetServer.h
//  MPAgentNewWin
//
//  Created by Heizer, Charles on 3/18/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPNetServer : NSObject
{
    NSString *host;
    NSUInteger port;
    BOOL useHTTPS;
    BOOL allowSelfSigned;
    BOOL useTLSAuth;
    NSUInteger serverType;
}

@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSUInteger port;
@property (nonatomic, assign) BOOL useHTTPS;
@property (nonatomic, assign) BOOL allowSelfSigned;
@property (nonatomic, assign) BOOL useTLSAuth;
@property (nonatomic, assign) NSUInteger serverType;

+ (MPNetServer *)serverObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)serverAsDictionary;

@end
