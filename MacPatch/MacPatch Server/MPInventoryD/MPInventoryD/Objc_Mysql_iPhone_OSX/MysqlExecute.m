//
//  MysqlExecute.m
//  MySQLTest
//
//  Created by Heizer, Charles on 11/9/12.
//  Copyright (c) 2012 LLNL. All rights reserved.
//

#import "MysqlExecute.h"
#import "MysqlConnection.h"
#import "MysqlException.h"
#import "NSString_MysqlEscape.h"

@implementation MysqlExecute

+ (MysqlExecute *)sqlExecuteWithConnection:(MysqlConnection *)aConnection
{
    if (!aConnection) {
        [MysqlException raiseConnection:nil withFormat:@"Connection is nil"];
    }
    
    MysqlExecute *newObject=[[self alloc] init];
    newObject->connection = aConnection;
    return newObject;
}

- (void)executeSQL:(NSString *)sqlString;
{
    @synchronized (connection) {
        if (mysql_query(connection.connection, [sqlString UTF8String])) {
            [MysqlException raiseConnection:connection
                                 withFormat:@"Could not perform mysql update %@ #%d:%s",sqlString,mysql_errno(connection.connection), mysql_error(connection.connection)];
        }
    }
}

@end

