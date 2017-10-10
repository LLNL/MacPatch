//
//  AgentTask.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "AgentTask.h"

@implementation AgentTask

+ (void)defaultTableMap:(FMXTableMap *)table
{
    [table setTableName:@"tasks"];
    [table hasIntIncrementsColumn:@"id"];   // defines as a primary key.
    [table hasIntColumn:@"tid"];
    [table hasIntColumn:@"tidrev"];
    [table hasStringColumn:@"name"];
    [table hasStringColumn:@"Description"];
    [table hasStringColumn:@"cmd"];
    [table hasStringColumn:@"data"];
    [table hasIntColumn:@"active"];
    [table hasStringColumn:@"interval"];
    [table hasStringColumn:@"startdate"];
    [table hasStringColumn:@"enddate"];
    [table hasIntColumn:@"type"];
    [table hasStringColumn:@"lastrun"];
    [table hasStringColumn:@"lastreturncode"];
    [table hasStringColumn:@"lasterror"];
    [table hasStringColumn:@"group_id"];
}

@end
