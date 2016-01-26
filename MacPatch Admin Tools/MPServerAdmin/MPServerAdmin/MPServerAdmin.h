//
//  MPServerAdmin.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/25/16.
//  Copyright © 2016 Charles Heizer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPServerAdmin : NSObject
{
    AuthorizationRef    _authRef;
}

@property (atomic, copy,   readwrite) NSData *authorization;
@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;

+ (MPServerAdmin *)sharedInstance;

- (void)installHelperApp;
- (void)connectToHelperTool;
- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock;

@end
