//
//  AgentTasksInfo.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "AgentTasksInfo.h"

@implementation AgentTasksInfo

+ (void)defaultTableMap:(FMXTableMap *)table
{
    [table setTableName:@"tasks_info"];
    [table hasIntIncrementsColumn:@"id"];   // defines as a primary key.
    [table hasIntColumn:@"rev"];
    [table hasStringColumn:@"group_id"];
    [table hasStringColumn:@"mdate"];
}

@end

