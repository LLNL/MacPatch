//
//  AgentTasksInfo.h
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "FMXModel.h"

@interface AgentTasksInfo : FMXModel

@property (strong, nonatomic) NSNumber *id;
@property (strong, nonatomic) NSNumber *rev;
@property (strong, nonatomic) NSString *group_id;
@property (strong, nonatomic) NSString *mdate;

@end
