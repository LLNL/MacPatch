//
//  NSDateComponents+AHLaunchCtlSchedule.m
//  AHLaunchCtl
//
//  Created by Eldon on 4/26/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "AHLaunchJobSchedule.h"
NSInteger AHUndefinedScheduleComponent = NSUndefinedDateComponent;

@implementation AHLaunchJobSchedule

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                        NSNumber *obj,
                                                        BOOL *stop) {
            if ([key.lowercaseString
                    isEqualToString:NSStringFromSelector(@selector(minute))]) {
                self.minute = obj.integerValue;
            } else if ([key.lowercaseString
                           isEqualToString:NSStringFromSelector(
                                               @selector(hour))]) {
                self.hour = obj.integerValue;
            } else if ([key.lowercaseString
                           isEqualToString:NSStringFromSelector(
                                               @selector(weekday))]) {
                self.weekday = obj.integerValue;
            } else if ([key.lowercaseString
                           isEqualToString:NSStringFromSelector(
                                               @selector(weekday))]) {
                self.day = obj.integerValue;
            } else if ([key.lowercaseString
                           isEqualToString:NSStringFromSelector(
                                               @selector(month))]) {
                self.month = obj.integerValue;
            }
        }];
    }
    return self;
}

- (NSString *)description {
    return self.dictionary.description;
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *dict =
        [[NSMutableDictionary alloc] initWithCapacity:5];

    if (self.minute != AHUndefinedScheduleComponent) {
        dict[@"Minute"] = @(self.minute);
    }

    if (self.hour != AHUndefinedScheduleComponent) {
        dict[@"Hour"] = @(self.hour);
    }

    if (self.day != AHUndefinedScheduleComponent) {
        dict[@"Day"] = @(self.day);
    }

    if (self.weekday != AHUndefinedScheduleComponent) {
        dict[@"Weekday"] = @(self.weekday);
    }

    if (self.month != AHUndefinedScheduleComponent) {
        dict[@"Month"] = @(self.month);
    }

    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (instancetype)scheduleWithMinute:(NSInteger)minute
                              hour:(NSInteger)hour
                               day:(NSInteger)day
                           weekday:(NSInteger)weekday
                             month:(NSInteger)month {
    AHLaunchJobSchedule *components = [AHLaunchJobSchedule new];

    if (minute != AHUndefinedScheduleComponent) {
        components.minute = minute;
    }
    if (hour != AHUndefinedScheduleComponent) {
        components.hour = hour;
    }
    if (day != AHUndefinedScheduleComponent) {
        components.day = day;
    }
    if (weekday != AHUndefinedScheduleComponent) {
        components.weekday = weekday;
    }
    if (month != AHUndefinedScheduleComponent) {
        components.month = month;
    }
    return components;
}

+ (instancetype)dailyRunAtHour:(NSInteger)hour minute:(NSInteger)minute {
    return [self scheduleWithMinute:minute
                               hour:hour
                                day:AHUndefinedScheduleComponent
                            weekday:AHUndefinedScheduleComponent
                              month:AHUndefinedScheduleComponent];
}

+ (instancetype)weeklyRunOnWeekday:(NSInteger)weekday hour:(NSInteger)hour {
    return [self scheduleWithMinute:00
                               hour:hour
                                day:AHUndefinedScheduleComponent
                            weekday:weekday
                              month:AHUndefinedScheduleComponent];
}

+ (instancetype)monthlyRunOnDay:(NSInteger)day hour:(NSInteger)hour {
    return [self scheduleWithMinute:00
                               hour:hour
                                day:day
                            weekday:AHUndefinedScheduleComponent
                              month:AHUndefinedScheduleComponent];
}

@end
