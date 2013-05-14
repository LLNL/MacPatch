//
//  NSString_MysqlEscape.m
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2012 Karl Kraft. All rights reserved.
//

#import "MysqlConnection.h"

#import "NSString_MysqlEscape.h"


@implementation NSString(MysqlEscape)

- (NSString *)mysqlEscapeInConnection:(MysqlConnection *)connection
{
  const char *ch = [self UTF8String];
  char *buf=malloc(strlen(ch)*2+1);
  mysql_real_escape_string(connection.connection, buf, ch, strlen(ch));
  NSString *retval=@(buf);
  free(buf);
  return retval;  
}

@end
