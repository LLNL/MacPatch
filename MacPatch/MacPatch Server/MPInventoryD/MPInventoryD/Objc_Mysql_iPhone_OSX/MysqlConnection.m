//
//  MysqlConnection.m
//  mysql_connector
//
//  Created by Karl Kraft on 5/21/08.
//  Copyright 2008-2012 Karl Kraft. All rights reserved.
//

#import "MysqlConnection.h"
#import "MysqlServer.h"

#import "MysqlCommitException.h"
#import "MysqlRollbackException.h"


@implementation MysqlConnection

@synthesize transactionsEnabled,server;



+ (MysqlConnection *)connectToServer:(MysqlServer *)server
{
  MysqlConnection *newObject = [[self alloc] init];
  newObject->_connection= calloc(1,sizeof(MYSQL));
  mysql_init(newObject->_connection);
  unsigned int timeout=server.connectionTimeout;
  mysql_options(newObject->_connection,MYSQL_OPT_CONNECT_TIMEOUT,&timeout);

  MysqlLog(@"Connecting to %@",server);
  
  if (!mysql_real_connect(newObject->_connection,
                          [server.host UTF8String],
                          [server.user UTF8String],
                          [server.password UTF8String],
                          [server.schema UTF8String],
                          server.port,  // default port
                          NULL,  // default socket
                          server.flags)) {
    MysqlLog(@"Failed to connect: Error: %s\n",mysql_error(&(newObject->_connection)));

    return nil;
  } else {
    MysqlLog(@"Connected to %@",server);
  }
  if (!mysql_set_character_set(newObject->_connection, "utf8")) {
    MysqlLog(@"Client character set: %s\n", mysql_character_set_name(&(newObject->_connection)));
  }
  newObject->server = server;
  return newObject;
}

+ (MysqlConnection *)connectToServers:(NSArray *)arrayOfServers
{
  for (MysqlServer *server in arrayOfServers) {
    MysqlConnection *aConnection=[self connectToServer:server];
    if (aConnection) return aConnection;
  }
  return nil;
}


- (void)enableStrictSql
{
  @synchronized (self) {
    MysqlLog(@"Setting strict sql");
    
    if (mysql_query(_connection, "set sql_mode=strict_all_tables")) {
      [MysqlException raiseConnection:self 
                           withFormat:@"Could not set sql_mode #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
    }
  }
}

- (void)enableTriggers
{
  @synchronized (self) {
    MysqlLog(@"Enabling triggers");
    
    if (mysql_query(_connection, "set @DISABLE_TRIGGERS = NULL")) {
      [MysqlException raiseConnection:self 
                           withFormat:@"Could not enable triggers #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
    }
  }
}

- (void)disableTriggers
{
  @synchronized (self) {
    MysqlLog(@"Disabling triggers");
    
    if (mysql_query(_connection, "set @DISABLE_TRIGGERS = 1")) {
      [MysqlException raiseConnection:self 
                           withFormat:@"Could not disable triggers #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
    }
  }
}

- (void)enableTransactions
{
  @synchronized (self) {
    MysqlLog(@"Transactions Enabled");
    transactionsEnabled=YES;
    mysql_autocommit(_connection, 0);
  }
}

- (void)disableTransactions
{
  @synchronized (self) {
    MysqlLog(@"Transactions Disabled");
    transactionsEnabled=NO;
    mysql_autocommit(_connection, 1);
  }
}

- (void)commitTransaction
{
  @synchronized (self) {
    if (mysql_commit(_connection)) {
      [MysqlCommitException raiseConnection:self withFormat:@"Transaction commit failed (%s)",mysql_error(_connection)];
    } else {
      MysqlLog(@"Transaction committed");
    }
  }
}

- (void)rollbackTransaction
{
  @synchronized (self) {
    if (mysql_rollback(_connection)) {
      [MysqlRollbackException raiseConnection:self withFormat:@"Transaction rollback failed (%s)",mysql_error(_connection)];
    } else {
      MysqlLog(@"Transaction committed");
    }
  }
}

- (void)sendIdle  __attribute__ ((noreturn))
{
  @autoreleasepool {
    [[NSThread currentThread] setName:@"Mysql Idle Thread"];
    while (true) {
      [NSThread sleepForTimeInterval:20.0];
      @synchronized (self) {
        MysqlLog(@"Sending idle");
        mysql_query(_connection, "select 'MysqlConnect:idleTmer'");
        MYSQL_RES     *theResults = mysql_use_result(_connection);
        mysql_free_result(theResults);  
      }
    }
  }
}

- (void)startIdle
{
  [self performSelectorInBackground:@selector(sendIdle) withObject:nil];
}



- (void)dealloc
{
  mysql_close(_connection);
  free(_connection);
}


- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ %@/%@/%@/%@",[super description],server.host,server.schema,server.user,server.password];
}

@end
