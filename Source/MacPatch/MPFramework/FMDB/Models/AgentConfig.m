//
//  AgentConfig.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "AgentConfig.h"

@implementation AgentConfig

+ (void)defaultTableMap:(FMXTableMap *)table
{
    [table setTableName:@"agent_config"];
    
    [table hasIntIncrementsColumn:@"id"];   // defines as a primary key.
    [table hasStringColumn:@"group_id"];
    [table hasStringColumn:@"Description"];
    [table hasStringColumn:@"clientGroup"];
    [table hasStringColumn:@"patchGroup"];
    [table hasStringColumn:@"patchGroupID"];
    [table hasStringColumn:@"patchState"];
    [table hasIntColumn:@"patchClient"];
    [table hasIntColumn:@"patchServer"];
    [table hasIntColumn:@"reboot"];
    [table hasStringColumn:@"swDistGroup"];
    [table hasStringColumn:@"swDistGroupID"];
    [table hasStringColumn:@"swDistGroupAdd"];
    [table hasStringColumn:@"swDistGroupAddID"];
    [table hasIntColumn:@"verifySignatures"];
}


@end
