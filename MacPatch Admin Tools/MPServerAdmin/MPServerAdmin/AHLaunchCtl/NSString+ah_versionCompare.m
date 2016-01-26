//
//  NSString+valueCompare.m
//  AutoPkgr
//
//  Created by Eldon Ahrold on 5/14/15.
//  Copyright 2015 Eldon Ahrold.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSString+ah_versionCompare.h"

@implementation NSString (lcVersionCompare)

- (NSComparisonResult)ah_compareToVersion:(NSString *)version
{
    // Break version into fields (separated by '.')
    NSMutableArray *selfArray = [[self componentsSeparatedByString:@"."] mutableCopy];
    NSMutableArray *versionArray = [[version componentsSeparatedByString:@"."] mutableCopy];

    // Balence the number of digits to compare
    if (selfArray.count < versionArray.count) {
        while ([selfArray count] != [versionArray count]) {
            [selfArray addObject:@"0"];
        }
    } else if (versionArray.count){
        while ([selfArray count] >= [versionArray count]) {
            [versionArray addObject:@"0"];
        };
    }

    __block NSComparisonResult results = NSOrderedSame;
    [selfArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        results = [selfArray[idx] compare:versionArray[idx] options:NSNumericSearch];
        if (results != NSOrderedSame) {
            *stop = YES;
        }
    }];

    return results;
}

- (BOOL)ah_version_isGreaterThan:(NSString *)b
{
    return ([self ah_compareToVersion:b] == NSOrderedDescending);
}

- (BOOL)ah_version_isGreaterThanOrEqualTo:(NSString *)b
{
    NSComparisonResult res = [self ah_compareToVersion:b];
    return ((res == NSOrderedDescending) || (res == NSOrderedSame));
}

- (BOOL)ah_version_isEqualTo:(NSString *)b
{
    return ([self ah_compareToVersion:b] == NSOrderedSame);
}

- (BOOL)ah_version_isLessThan:(NSString *)b
{
    return ([self ah_compareToVersion:b] == NSOrderedAscending);
}

- (BOOL)ah_version_isLessThanOrEqualTo:(NSString *)b
{
    NSComparisonResult res = [self ah_compareToVersion:b];
    return ((res == NSOrderedAscending) || (res == NSOrderedSame));
}

@end
