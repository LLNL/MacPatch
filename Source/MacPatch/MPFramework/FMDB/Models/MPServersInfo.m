//
//  MPServersInfo.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "MPServersInfo.h"

@implementation MPServersInfo

+ (void)defaultTableMap:(FMXTableMap *)table
{
    [table setTableName:@"mp_servers_info"];
    [table hasIntIncrementsColumn:@"id"];   // defines as a primary key.
    [table hasIntColumn:@"version"];
    [table hasStringColumn:@"mdate"];
}


@end
