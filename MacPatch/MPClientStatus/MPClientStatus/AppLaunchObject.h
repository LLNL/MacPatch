//
//  AppLaunchObject.h
//  MPClientStatus
//
//  Created by Heizer, Charles on 5/15/14.
//  Copyright (c) 2014 LLNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppLaunchObject : NSObject

@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appVersion;
@property (nonatomic, strong) NSString *appPath;

+ (AppLaunchObject *)appLaunchObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)appLaunchObjectAsDictionary;

@end
