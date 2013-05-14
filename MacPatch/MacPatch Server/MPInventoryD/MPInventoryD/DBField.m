//
//  DBField.m
/*
 Copyright (c) 2013, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.
 
 This file is part of MacPatch, a program for installing and patching
 software.
 
 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.
 
 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.
 
 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import "DBField.h"

@implementation DBField


- (id)init
{
    self = [super init];
    [self setName:@""];
    [self setDataType:@"CF_SQL_VARCHAR"];
    [self setLength:@"255"];
    [self setDataTypeExt:@""];
    [self setDefaultValue:@""];
    [self setAutoIncrement:@""];
    [self setPrimaryKey:@""];
    [self setAllowNull:@""];
    return self;
}

-(NSDictionary *) description
{
    NSDictionary *d = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:self.name,self.dataType,self.length,self.dataTypeExt,self.defaultValue,self.autoIncrement,self.primaryKey,self.allowNull,nil]
                                                  forKeys:[NSArray arrayWithObjects:@"name",@"dataType",@"length",@"dataTypeExt",@"defaultValue",@"autoIncrment",@"primaryKey",@"allowNull",nil]];
    
    return d;
}

- (NSDictionary *)fieldDescription
{
    NSDictionary *d = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:self.name,self.dataType,self.length,self.dataTypeExt,self.defaultValue,self.autoIncrement,self.primaryKey,self.allowNull,nil]
                                                  forKeys:[NSArray arrayWithObjects:@"name",@"dataType",@"length",@"dataTypeExt",@"defaultValue",@"autoIncrment",@"primaryKey",@"allowNull",nil]];
    
    return d;
}

@end
