//
//  MysqlIndex.h
//  mysql_connector
//
//  Created by Bill Allen on 8/26/11.
//  Copyright 2011 Karl Kraft. All rights reserved.
//

@class MysqlConnection;

@interface MysqlIndex : NSObject
{
  MysqlConnection *connection;
}

@property(readonly)MysqlConnection *connection;

+ (MysqlIndex *)indexWithConnection:(MysqlConnection *)aConnection;
- (NSSet *)indexNamesForTable:(NSString *)tableName;
- (NSArray *)columnsForTable:(NSString *)tableName index:(NSString *)indexName;

@end
