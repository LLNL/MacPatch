//
//  MySQLTableColumn.m
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

#import "MySQLTableColumn.h"

@interface MySQLTableColumn ()

@property (nonatomic, readwrite, retain) NSString *Field;
@property (nonatomic, readwrite, retain) NSString *Type;
@property (nonatomic, readwrite, retain) NSString *Length;
@property (nonatomic, readwrite, retain) NSString *TypeExtension;
@property (nonatomic, readwrite, assign) BOOL null;
@property (nonatomic, readwrite, retain) NSString *Key;
@property (nonatomic, readwrite, retain) NSString *Default;
@property (nonatomic, readwrite, retain) NSString *Extra;

- (void)populateValuesFromResults:(NSDictionary *)aResults;
- (void)parseFieldType:(NSData *)dType;

@end

@implementation MySQLTableColumn

@synthesize Field;
@synthesize Type;
@synthesize Length;
@synthesize TypeExtension;
@synthesize null;
@synthesize Key;
@synthesize Default;
@synthesize Extra;


- (id)initWithFetchResults:(NSDictionary *)results
{
    self = [super init];
    
    [self setField:@"Err"];
    [self setType:@"varchar"];
    [self setLength:@"255"];
    [self setTypeExtension:@""];
    [self setNull:YES];
    [self setKey:@""];
    [self setDefault:@""];
    [self setExtra:@""];
    [self populateValuesFromResults:results];
    
    return self;
}

- (void)populateValuesFromResults:(NSDictionary *)aResults
{
    if ([aResults objectForKey:@"Field"]) {
        [self setField:[aResults objectForKey:@"Field"]];
    } else {
        // Need to log this
        return;
    }
    if ([aResults objectForKey:@"Type"]) {
        [self parseFieldType:[aResults objectForKey:@"Type"]];
    } else {
        // Need to log this
        return;
    }
    if ([aResults objectForKey:@"Key"]) {
        [self setKey:[aResults objectForKey:@"Key"]];
    }
    if ([aResults objectForKey:@"Default"]) {
        [self setDefault:[aResults objectForKey:@"Default"]];
    }
    if ([aResults objectForKey:@"Extra"]) {
        [self setExtra:[aResults objectForKey:@"Extra"]];
    }
    if ([aResults objectForKey:@"Null"]) {
        [self setNull:[[aResults objectForKey:@"Null"] boolValue]];
    }
}

- (void)parseFieldType:(NSData *)dType
{
    NSString *_type;
    NSString *_lenth;
    NSString *_typeExten = @"";
    NSString *_typeAsString = [[NSString alloc] initWithData:dType encoding:NSUTF8StringEncoding];
    @try {
        // int(11) unsigned
        // 1) parse on ")"
        NSArray *mRaw = [_typeAsString componentsSeparatedByString:@")"];
        if ([mRaw count] == 1)
        {
            _type = [mRaw objectAtIndex:0];
            _lenth = @"";
        }
        else if ([mRaw count] == 2)
        {
            _type = [[[mRaw objectAtIndex:0] componentsSeparatedByString:@"("] objectAtIndex:0];
            _lenth = [[[mRaw objectAtIndex:0] componentsSeparatedByString:@"("] objectAtIndex:1];
            
            if ([[[mRaw objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0)
            {
                _typeExten = [[mRaw objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    
    [self setType:_type];
    [self setLength:_lenth];
    [self setTypeExtension:_typeExten];
}

- (NSDictionary *) description
{
    /* This Description is made to match the DBField class */
    
    NSDictionary *d = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:self.Field,self.Type,self.Length,self.TypeExtension,self.Default,self.Extra,self.Key,(self.null ? @"NULL" : @"NOT NULL"), nil]
                                                  forKeys:[NSArray arrayWithObjects:@"name",@"dataType",@"length",@"dataTypeExt",@"defaultValue",@"autoIncrment",@"primaryKey",@"allowNull",nil]];
    
    return d;
}

- (NSDictionary *)colDescription
{
    NSDictionary *d = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:self.Field,self.Type,self.Length,self.TypeExtension,self.Default,self.Extra,self.Key,(self.null ? @"NULL" : @"NOT NULL"), nil]
                                                  forKeys:[NSArray arrayWithObjects:@"name",@"dataType",@"length",@"dataTypeExt",@"defaultValue",@"autoIncrment",@"primaryKey",@"allowNull",nil]];
    
    return d;
}

@end
