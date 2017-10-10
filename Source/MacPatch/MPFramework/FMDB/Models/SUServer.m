//
//  SUServer.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "SUServer.h"

@implementation SUServer

+ (void)defaultTableMap:(FMXTableMap *)table
{
    [table setTableName:@"su_servers"];
    [table hasIntIncrementsColumn:@"id"];   // defines as a primary key.
    [table hasStringColumn:@"CatalogURL"];
    [table hasIntColumn:@"serverType"];
    [table hasIntColumn:@"osmajor"];
    [table hasIntColumn:@"osminor"];
}

@end
