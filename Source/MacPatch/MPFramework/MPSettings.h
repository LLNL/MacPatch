//
//  MPSettings.h
//  MPLibrary
//
//  Created by Charles Heizer on 6/12/17.
//
//

#import <Foundation/Foundation.h>

@class Agent;
@class Server;
@class Suserver;
@class Task;

@interface MPSettings : NSObject

@property (nonatomic, strong, readonly) NSString *ccuid;
@property (nonatomic, strong, readonly) NSString *serialno;

@property (nonatomic, strong, readonly) Agent *agent;
@property (nonatomic, strong, readonly) Server *server;
@property (nonatomic, strong, readonly) Suserver *suserver;
@property (nonatomic, strong, readonly) Task *task;


+ (MPSettings *)settings;

@end
