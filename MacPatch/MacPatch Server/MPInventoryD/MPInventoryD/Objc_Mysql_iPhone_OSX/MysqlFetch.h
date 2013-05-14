//
//  MysqlFetch.h
//  mysql_connector
//
//  Created by Karl Kraft on 4/25/07.
//  Copyright 2007-2010 Karl Kraft. All rights reserved.
//

#import "mysql.h"

@class MysqlConnection;

@interface MysqlFetch : NSObject {
  NSArray *fieldNames;
  NSArray *fields;
  NSArray *results;
}

@property(readonly) NSArray *fieldNames;
@property(readonly) NSArray *fields;
@property(readonly) NSArray *results;


+ (MysqlFetch *)fetchWithCommand:(NSString *)s onConnection:(MysqlConnection *)connection extendedNames:(BOOL)useExtendedNames;

// calls above method with useExtendedNames==NO
+ (MysqlFetch *)fetchWithCommand:(NSString *)s onConnection:(MysqlConnection *)connection;

@end
