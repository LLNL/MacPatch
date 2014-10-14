//
//  MPAgentRegister.h
//  MPAgent
//
//  Created by Heizer, Charles on 8/8/14.
//  Copyright (c) 2014 LLNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWebServices;

@interface MPAgentRegister : NSObject
{
    MPWebServices *mpws;
}

@property (nonatomic, strong) NSString *clientKey;
@property (nonatomic, strong) NSString *registrationKey;
@property (nonatomic, strong) NSString *hostName;


- (BOOL)clientIsRegistered;

- (int)registerClient;
- (int)registerClient:(NSString *)aRegKey;
- (int)registerClient:(NSString *)aRegKey hostName:(NSString *)hostName;

@end
