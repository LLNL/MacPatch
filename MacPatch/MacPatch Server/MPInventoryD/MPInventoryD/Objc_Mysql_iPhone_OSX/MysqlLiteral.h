//
//  MysqlLiteral.h
//  mysql_connector
//
//  Created by Karl Kraft on 8/29/09.
//  Copyright 2009-2010 Karl Kraft. All rights reserved.
//



@interface MysqlLiteral : NSObject {
  NSString *string;
}

@property(readonly) NSString *string;

+(MysqlLiteral *)literalWithString:(NSString *)s;

@end
