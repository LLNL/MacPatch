//
//  MysqlFetchField.h
//  mysql_connector
//
//  Created by Karl Kraft on 10/22/09.
//  Copyright 2009-2011 Karl Kraft. All rights reserved.
//

#import "mysql.h"

@interface MysqlFetchField : NSObject {
  NSString *name;
  enum enum_field_types fieldType;
  NSUInteger width;
  NSUInteger decimals;
  BOOL primaryKey;
}

@property(retain) NSString *name;
@property(assign) enum enum_field_types fieldType;
@property(assign) NSUInteger width;
@property(assign) NSUInteger decimals;
@property(assign) BOOL primaryKey;

@end
