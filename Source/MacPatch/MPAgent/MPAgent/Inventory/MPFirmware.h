//
//  MPFirmware.h
//  MPAgent
//
//  Created by Charles Heizer on 1/6/17.
//  Copyright © 2017 LLNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPFirmware : NSObject

@property (nonatomic, assign, readonly) int state;
@property (nonatomic, strong, readonly) NSString *status;
@property (nonatomic, strong, readonly) NSString *options;
@property (nonatomic, strong, readonly) NSString *mode;
@property (nonatomic, strong, readonly) NSError *error;

- (void)refresh;

@end
