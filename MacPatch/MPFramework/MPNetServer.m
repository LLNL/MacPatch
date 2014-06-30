//
//  MPNetServer.m
//  MPAgentNewWin
//
//  Created by Heizer, Charles on 3/18/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "MPNetServer.h"

#undef  ql_component
#define ql_component lcl_cMPNetServer

@interface MPNetServer ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MPNetServer

@synthesize host;
@synthesize port;
@synthesize useHTTPS;
@synthesize allowSelfSigned;
@synthesize useTLSAuth;
@synthesize serverType;

enum {
    kMPMasterServer = 0,
    kMPDistributionServer = 1,
    kMPProxyServer = 2
};
typedef NSUInteger MPServerType;


+ (MPNetServer *)serverObjectWithDictionary:(NSDictionary *)dict
{
    MPNetServer *instance = [[MPNetServer alloc] initWithDictionary:dict];
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.host = @"localhost";
        self.port = 2600;
        self.useHTTPS = YES;
        self.allowSelfSigned = NO;
        self.useTLSAuth = NO;
        self.serverType = 1; //Distribution Server
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];

    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
        self.host = [self objectOrNilForKey:@"host" fromDictionary:dict];
        self.port = [[self objectOrNilForKey:@"port" fromDictionary:dict] integerValue];
        self.useHTTPS = [[self objectOrNilForKey:@"useHTTPS" fromDictionary:dict] boolValue];
        self.allowSelfSigned = [[self objectOrNilForKey:@"allowSelfSigned" fromDictionary:dict] boolValue];
        self.useTLSAuth = [[self objectOrNilForKey:@"useTLSAuth" fromDictionary:dict] boolValue];
        self.serverType = [[self objectOrNilForKey:@"serverType" fromDictionary:dict] integerValue];
    }

    return self;
}

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}

- (NSDictionary *)serverAsDictionary
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:self.host forKey:@"host"];
    [d setObject:[NSNumber numberWithInt:(int)self.port] forKey:@"port"];
    [d setObject:[NSNumber numberWithBool:self.useHTTPS] forKey:@"useHTTPS"];
    [d setObject:[NSNumber numberWithBool:self.allowSelfSigned] forKey:@"allowSelfSigned"];
    [d setObject:[NSNumber numberWithBool:self.useTLSAuth] forKey:@"useTLSAuth"];
    [d setObject:[NSNumber numberWithInt:(int)self.serverType] forKey:@"serverType"];
    return [NSDictionary dictionaryWithDictionary:d];
}

@end
