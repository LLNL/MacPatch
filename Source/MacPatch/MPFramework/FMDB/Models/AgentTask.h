//
//  AgentTask.h
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "FMXModel.h"

@interface AgentTask : FMXModel

@property (strong, nonatomic) NSNumber *id;
@property (strong, nonatomic) NSNumber *tid;
@property (strong, nonatomic) NSNumber *tidrev;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *Description;
@property (strong, nonatomic) NSString *cmd;
@property (strong, nonatomic) NSString *data;
@property (strong, nonatomic) NSNumber *active;
@property (strong, nonatomic) NSString *interval;
@property (strong, nonatomic) NSString *startdate;
@property (strong, nonatomic) NSString *enddate;
@property (strong, nonatomic) NSNumber *type;
@property (strong, nonatomic) NSString *lastrun;
@property (strong, nonatomic) NSString *lastreturncode;
@property (strong, nonatomic) NSString *lasterror;
@property (strong, nonatomic) NSString *group_id;

@end
