//
//  MysqlExecute.h
//  MySQLTest
//
//  Created by Heizer, Charles on 11/9/12.
//  Copyright (c) 2012 LLNL. All rights reserved.
//

@class MysqlConnection;

@interface MysqlExecute : NSObject
{
    MysqlConnection *connection;
}

+ (MysqlExecute *)sqlExecuteWithConnection:(MysqlConnection *)aConnection;
- (void)executeSQL:(NSString *)sqlString;

@end
