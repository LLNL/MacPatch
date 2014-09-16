//
//  MPServerEntry.m
//  MPAgentExec
//
//  Created by Heizer, Charles on 9/15/14.
//  Copyright (c) 2014 LLNL. All rights reserved.
//

#import "MPServerEntry.h"

static NSString *kHOST = @"host";
static NSString *kPORT = @"port";
static NSString *kSERVER_TYPE = @"serverType";
static NSString *kUSEHTTPS = @"useHTTPS";
static NSString *kUSETLSAUTH = @"useTLSAuth";
static NSString *kALLOWSELFSIGNED = @"allowSelfSigned";
static NSString *kORDER = @"order";

@implementation MPServerEntry

@synthesize host = _host;
@synthesize port = _port;
@synthesize serverType = _serverType;
@synthesize useHTTPS = _useHTTPS;
@synthesize useTLSAuth = _useTLSAuth;
@synthesize allowSelfSigned = _allowSelfSigned;
@synthesize order = _order;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.host = @"NA";
        self.port = @"NA";
        self.serverType = @"NA";
        self.useHTTPS = @"NA";
        self.useTLSAuth = @"NA";
        self.allowSelfSigned = @"NA";
        self.order = @"999";
    }
    return self;
}

- (id)initWithServerDictionary:(NSDictionary *)aServerItem index:(NSString *)idx;
{
    self = [super init];
    if (self)
    {
        [self parseWithDictionary:aServerItem];
        [self setOrder:idx];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.host forKeyPath:kHOST];
    [mutableDict setValue:self.port forKeyPath:kPORT];
    [mutableDict setValue:self.serverType forKeyPath:kSERVER_TYPE];
    [mutableDict setValue:self.useHTTPS forKeyPath:kUSEHTTPS];
    [mutableDict setValue:self.useTLSAuth forKeyPath:kUSETLSAUTH];
    [mutableDict setValue:self.allowSelfSigned forKeyPath:kALLOWSELFSIGNED];
    [mutableDict setValue:self.order forKey:kORDER];
    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSDictionary *)parseWithDictionary:(NSDictionary *)aDictionary index:(NSString *)idx
{
    if (!aDictionary) {
        return [self dictionaryRepresentation];
    }

    for (NSString *key in aDictionary.allKeys) {
        if ([key isEqualToString:@"host"]) {
            self.host = [[aDictionary objectForKey:@"host"] stringValue];
            continue;
        }
        if ([key isEqualToString:@"port"]) {
            self.port = [[aDictionary objectForKey:@"port"] stringValue];
            continue;
        }
        if ([key isEqualToString:@"serverType"]) {
            self.display_Sleep_Uses_Dim = [[aDictionary objectForKey:@"serverType"] stringValue];
            continue;
        }
        if ([key isEqualToString:@"useHTTPS"]) {
            self.standby_Delay = [[aDictionary objectForKey:@"useHTTPS"] stringValue];
            continue;
        }
        if ([key isEqualToString:@"useTLSAuth"]) {
            self.standby_Delay = [[aDictionary objectForKey:@"useTLSAuth"] stringValue];
            continue;
        }
        if ([key isEqualToString:@"allowSelfSigned"]) {
            self.standby_Delay = [[aDictionary objectForKey:@"allowSelfSigned"] stringValue];
            continue;
        }
    }

    self.order = idx;
    return [self dictionaryRepresentation];
}

@end
