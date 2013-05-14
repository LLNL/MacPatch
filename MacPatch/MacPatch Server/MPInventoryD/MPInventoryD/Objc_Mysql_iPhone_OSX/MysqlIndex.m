//
//  MysqlIndex.m
//  mysql_connector
//
//  Created by Bill Allen on 8/26/11.
//  Copyright 2011 Karl Kraft. All rights reserved.
//

#import "MysqlIndex.h"
#import "MysqlConnection.h"
#import "MysqlException.h"
#import "MysqlFetch.h"

@implementation MysqlIndex

@synthesize connection;

+ (MysqlIndex *)indexWithConnection:(MysqlConnection *)aConnection
{
  MysqlIndex *t = [[self alloc] init];
  t->connection = aConnection;
  return t;
}

- (NSSet *)indexNamesForTable:(NSString *)tableName
{
  NSMutableSet *s = [[NSMutableSet alloc] init];
  NSString *cmd = [NSString stringWithFormat:@"show indexes in %@",tableName];
  @synchronized(connection) {
    MysqlFetch *fetch = [MysqlFetch fetchWithCommand:cmd onConnection:connection];
    for (NSDictionary *d in fetch.results) {
      [s addObject:[d objectForKey:@"Key_name"]];
    }
  }
  return [NSSet setWithSet:s];
}

- (NSArray *)columnsForTable:(NSString *)tableName index:(NSString *)indexName
{
  NSMutableArray *a = [[NSMutableArray alloc] init];
  NSString *cmd = [NSString stringWithFormat:@"show index in %@ where Key_name = '%@'",tableName,indexName];
  @synchronized(connection) {
    MysqlFetch *fetch = [MysqlFetch fetchWithCommand:cmd onConnection:connection];
    for (NSDictionary *d in fetch.results) {
      [a addObject:[d objectForKey:@"Column_name"]];
    }
  }
  return [NSArray arrayWithArray:a];
}

@end
