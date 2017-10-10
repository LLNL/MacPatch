//
//  SUServersInfo.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "SUServersInfo.h"

@implementation SUServersInfo

+ (void)defaultTableMap:(FMXTableMap *)table
{
    [table setTableName:@"su_servers_info"];
    [table hasIntIncrementsColumn:@"id"];   // defines as a primary key.
    [table hasIntColumn:@"version"];
    [table hasStringColumn:@"mdate"];
}

@end
