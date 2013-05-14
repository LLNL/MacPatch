//
//  MysqlDelete.m
//  mysql_connector
//
//  Created by Karl Kraft on 9/28/08.
//  Copyright 2008-2012 Karl Kraft. All rights reserved.
//

#import "MysqlDelete.h"
#import "MysqlConnection.h"
#import "MysqlException.h"
#import "NSString_MysqlEscape.h"


@implementation MysqlDelete

@synthesize tableName,qualifier,affectedRows;

+ (MysqlDelete *)deleteWithConnection:(MysqlConnection *)aConnection
{
  if (!aConnection) {
    [MysqlException raiseConnection:nil withFormat:@"Connection is nil"];
  }
  
  MysqlDelete *newObject=[[self alloc] init];
  newObject->connection = aConnection;
  newObject->tableName=nil;
  newObject->qualifier=nil;
  return newObject;
}


- (NSString *)command
{
  NSMutableString *cmd = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE %@",tableName,qualifier];
  return cmd;  
}

- (NSString *)commandUsingQuick
{
    NSMutableString *cmd = [NSMutableString stringWithFormat:@"DELETE QUICK FROM %@ WHERE %@",tableName,qualifier];
    return cmd;
}


- (void)execute
{
  @synchronized (connection) {
    if (!tableName) {
      [MysqlException raiseConnection:connection withFormat:@"Delete is missing table name"];
    }
    if (!qualifier) {
      [MysqlException raiseConnection:connection withFormat:@"Delete is unqualified. Use TRUNCATE to wipe out tables"];
    }
    
    NSString *cmd = [self command];
    if (mysql_query(connection.connection, [cmd UTF8String])) {
      [MysqlException raiseConnection:connection 
                           withFormat:@"Could not perform mysql update %@ #%d:%s",cmd,mysql_errno(connection.connection), mysql_error(connection.connection)];
    } else {
      unsigned long long rowCount = mysql_affected_rows(connection.connection);
      affectedRows = @(rowCount);
      MysqlLog(@"%@ rows affected by %@",affectedRows,cmd);
    }
  }
}

- (void)executeUsingQuick
{
    @synchronized (connection) {
        if (!tableName) {
            [MysqlException raiseConnection:connection withFormat:@"Delete is missing table name"];
        }
        if (!qualifier) {
            [MysqlException raiseConnection:connection withFormat:@"Delete is unqualified. Use TRUNCATE to wipe out tables"];
        }
        
        NSString *cmd = [self commandUsingQuick];
        if (mysql_query(connection.connection, [cmd UTF8String])) {
            [MysqlException raiseConnection:connection
                                 withFormat:@"Could not perform mysql update %@ #%d:%s",cmd,mysql_errno(connection.connection), mysql_error(connection.connection)];
        } else {
            unsigned long long rowCount = mysql_affected_rows(connection.connection);
            affectedRows = @(rowCount);
            MysqlLog(@"%@ rows affected by %@",affectedRows,cmd);
        }
    }
}


@end
