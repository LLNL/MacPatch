//
//  AgentConfigInfo.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "AgentConfigInfo.h"

@implementation AgentConfigInfo

static NSString * const kTypeName = @"AgentConfigInfo";
static NSString * const kTypeNameLower = @"agentconfiginfo";

+ (void)defaultTableMap:(FMXTableMap *)table
{
    [table setTableName:@"agent_config_info"];
    [table hasIntIncrementsColumn:@"id"];   // defines as a primary key.
    [table hasIntColumn:@"rev"];
    [table hasStringColumn:@"group_id"];
    [table hasStringColumn:@"mdate"];
}

- (BOOL)isValidType:(NSDictionary *)aData
{
    if ([aData objectForKey:@"type"])
    {
        if([[aData objectForKey:@"type"] isKindOfClass:[NSString class]] == YES)
        {
            if ([[[aData objectForKey:@"type"] lowercaseString] isEqualToString:kTypeNameLower])
            {
                return YES;
            }
        }
    }
    
    return NO;
}


- (BOOL)isValidData:(NSDictionary *)aData
{
    NSArray *_cols = @[@"rev",@"group_id",@"mdate"]; // Required Columns
    
    if ([aData objectForKey:@"data"])
    {
        if([[aData objectForKey:@"data"] isKindOfClass:[NSDictionary class]] == YES)
        {
            NSDictionary *_data = [aData objectForKey:@"data"];
            for (NSString *_col in _cols) {
                if (![_data objectForKey:_col]) {
                    // Required Column not found, fail
                    return NO;
                }
            }
            return YES;
        }
    }
    
    // No data key or it's not a dict
    return NO;
}

@end
