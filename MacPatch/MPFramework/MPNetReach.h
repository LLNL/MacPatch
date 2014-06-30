//
//  MPNetReach.h
//  MPLibrary
//
//  Created by Heizer, Charles on 5/30/14.
//
//

#import <Foundation/Foundation.h>

@interface MPNetReach : NSObject

@property (nonatomic, assign) int timeout;

- (id)initWithTimeout:(int)aTimeout;
- (BOOL)isMPServerAlive:(int)aPort host:(NSString *)aHost;

@end
