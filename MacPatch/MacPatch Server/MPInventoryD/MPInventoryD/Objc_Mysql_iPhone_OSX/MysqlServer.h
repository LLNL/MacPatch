//
//  MysqlServer.h
//  mysql_connector
//
//  Created by Karl Kraft on 3/19/11.
//  Copyright 2011 Karl Kraft. All rights reserved.
//



@interface MysqlServer : NSObject {
  NSString *host;
  NSString *user;
  NSString *password;
  NSString *schema;
  unsigned int port;
  unsigned long flags;
  unsigned int connectionTimeout;
}

@property(copy) NSString *host;
@property(copy) NSString *user;
@property(copy) NSString *password;
@property(copy) NSString *schema;
@property(assign) unsigned int port;
@property(assign) unsigned long flags;
@property(assign) unsigned int connectionTimeout;

@end
