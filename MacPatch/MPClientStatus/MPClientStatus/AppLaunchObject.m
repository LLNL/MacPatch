//
//  AppLaunchObject.m
//  MPClientStatus
//
//  Created by Heizer, Charles on 5/15/14.
//  Copyright (c) 2014 LLNL. All rights reserved.
//

#import "AppLaunchObject.h"

@interface AppLaunchObject (Private)

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;
- (NSString *)stringOrNAForKey:(id)aKey fromDictionary:(NSDictionary *)dict;
- (NSString *)stringOrZeroForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation AppLaunchObject

@synthesize appName;
@synthesize appPath;
@synthesize appVersion;

+ (AppLaunchObject *)appLaunchObjectWithDictionary:(NSDictionary *)dict
{
    AppLaunchObject *instance = [[AppLaunchObject alloc] initWithDictionary:dict];
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.appName = @"NA";
        self.appPath = @"NA";
        self.appVersion = @"0";
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];

    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
        self.appName = [self stringOrNAForKey:@"NSApplicationName" fromDictionary:dict];
        self.appPath = [self stringOrNAForKey:@"NSApplicationPath" fromDictionary:dict];
        self.appVersion = [self stringOrZeroForKey:@"CFBundleShortVersionString" fromDictionary:dict];
    }

    return self;
}

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}

- (NSString *)stringOrNAForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? @"NA" : object;
}

- (NSString *)stringOrZeroForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? @"0" : object;
}

- (NSDictionary *)appLaunchObjectAsDictionary
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:self.appName forKey:@"appName"];
    [d setObject:self.appPath forKey:@"appPath"];
    [d setObject:self.appVersion forKey:@"appVersion"];
    return [NSDictionary dictionaryWithDictionary:d];
}

@end