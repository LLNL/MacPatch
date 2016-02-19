//
//  MPServerAdmin.m
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/25/16.
//  Copyright © 2016 Charles Heizer. All rights reserved.
//

#import "MPServerAdmin.h"
#import "Common.h"
#import "HelperTool.h"
#import "AHLaunchCtl.h"

static MPServerAdmin *_instance;

@implementation MPServerAdmin

+ (MPServerAdmin *)sharedInstance
{
    @synchronized(self) {
        
        if (_instance == nil) {
            _instance = [[super allocWithZone:NULL] init];
            
            OSStatus                    err;
            AuthorizationExternalForm   extForm;
            
            // Create our connection to the authorization system.
            //
            // If we can't create an authorization reference then the app is not going to be able
            // to do anything requiring authorization.  Generally this only happens when you launch
            // the app in some wacky, and typically unsupported, way.  In the debug build we flag that
            // with an assert.  In the release build we continue with self->_authRef as NULL, which will
            // cause all authorized operations to fail.
            
            err = AuthorizationCreate(NULL, NULL, 0, &_instance->_authRef);
            if (err == errAuthorizationSuccess) {
                err = AuthorizationMakeExternalForm(_instance->_authRef, &extForm);
            }
            if (err == errAuthorizationSuccess) {
                _instance.authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
            }
            assert(err == errAuthorizationSuccess);
            
            // If we successfully connected to Authorization Services, add definitions for our default
            // rights (unless they're already in the database).
            
            if (_instance->_authRef) {
                [Common setupAuthorizationRights:_instance->_authRef];
            }
            
        }
    }
    return _instance;
}

#pragma mark Singleton Methods

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark Helper Tool

#pragma mark - Helper Tool
- (void)connectToHelperTool
// Ensures that we're connected to our helper tool.
{
    assert([NSThread isMainThread]);
    
    if (self.helperToolConnection == nil) {
        self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperToolMachServiceName options:NSXPCConnectionPrivileged];
        self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        // We can ignore the retain cycle warning because a) the retain taken by the
        // invalidation handler block is released by us setting it to nil when the block
        // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
        // will be released when that operation completes and the operation itself is deallocated
        // (notably self does not have a reference to the NSBlockOperation).
        /*
        self.helperToolConnection.invalidationHandler = ^{
            // If the connection gets invalidated then, on the main thread, nil out our
            // reference to it.  This ensures that we attempt to rebuild it the next time around.
            self.helperToolConnection.invalidationHandler = nil;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.helperToolConnection = nil;
                NSLog(@"connection invalidated");
            }];
        };
         */
#pragma clang diagnostic pop
        [self.helperToolConnection resume];
    }
}

- (void)installHelperApp
{
    NSError *error;
    NSString *kYourHelperToolReverseDomain = @"gov.llnl.mp.admin.helper";
    [AHLaunchCtl installHelper:kYourHelperToolReverseDomain prompt:@"Install Helper?" error:&error];
    if(error) {
        NSLog(@"error: %@",error);
    }
}

- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock
// Connects to the helper tool and then executes the supplied command block on the
// main thread, passing it an error indicating if the connection was successful.
{
    assert([NSThread isMainThread]);
    
    // Ensure that there's a helper tool connection in place.
    
    [self connectToHelperTool];
    
    // Run the command block.  Note that we never error in this case because, if there is
    // an error connecting to the helper tool, it will be delivered to the error handler
    // passed to -remoteObjectProxyWithErrorHandler:.  However, I maintain the possibility
    // of an error here to allow for future expansion.
    
    commandBlock(nil);
}

@end
