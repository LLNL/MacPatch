//
//  MPAgentRegister.m
//  MPAgent
//
//  Created by Heizer, Charles on 8/8/14.
//  Copyright (c) 2014 LLNL. All rights reserved.
//

#import "MPAgentRegister.h"
#import "MacPatch.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "MPKeychain.h"

#define AUTO_REG_KEY @"999999999"

@interface MPAgentRegister ()


@end

@implementation MPAgentRegister

@synthesize clientKey = _clientKey;
@synthesize registrationKey = _registrationKey;
@synthesize hostName = _hostName;


- (id)init
{
    self = [super init];
    if (self)
    {
        self.hostName = (__bridge NSString *)SCDynamicStoreCopyLocalHostName(NULL);
        self.registrationKey = AUTO_REG_KEY;
        self.clientKey = [[NSProcessInfo processInfo] globallyUniqueString];
        mpws = [[MPWebServices alloc] init];
    }
    return self;
}

- (BOOL)clientIsRegistered
{
    BOOL result = FALSE;
    //NSError *err = nil;
    //NSString *res = [mpws getRegisterAgent:aRegKey hostName:hostName clientKey:clientKey error:&err];
    //NSLog(@"%@",res);
    return result;
}

- (int)registerClient
{
    return [self registerClient:self.registrationKey hostName:self.hostName];
}

- (int)registerClient:(NSString *)aRegKey
{
    return [self registerClient:aRegKey hostName:self.hostName];
}

- (int)registerClient:(NSString *)aRegKey hostName:(NSString *)hostName
{
    //NSError *err = nil;
    //NSString *res = [mpws getRegisterAgent:aRegKey hostName:hostName clientKey:clientKey error:&err];
    //NSLog(@"%@",res);
    return 0;
}

@end
