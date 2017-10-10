//
//  MPServer.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "Server.h"

@implementation Server

+ (void)defaultTableMap:(FMXTableMap *)table
{
    [table setTableName:@"mp_servers"];
    [table hasIntIncrementsColumn:@"id"];   // defines as a primary key.
    [table hasStringColumn:@"hostname"];
    [table hasIntColumn:@"port"];
    [table hasIntColumn:@"usessl"];
    [table hasIntColumn:@"useclientcert"];
    [table hasIntColumn:@"isproxy"];
}

@end
