//
//  BatteryInfo.h
//  DictionaryTest
//
//  Created by Heizer, Charles on 1/14/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BatteryInfo : NSObject

@property (nonatomic, strong) NSString *serialNumber;
@property (nonatomic, strong) NSString *manufacturer;
@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, strong) NSString *firmwareVersion;
@property (nonatomic, strong) NSString *chargeRemaining_mAh;
@property (nonatomic, strong) NSString *fullChargeCapacity_mAh;
@property (nonatomic, strong) NSString *designChargeCapacity_mAh;
@property (nonatomic, strong) NSString *fullyCharged;
@property (nonatomic, strong) NSString *charging;
@property (nonatomic, strong) NSString *cycleCount;
@property (nonatomic, strong) NSString *designCycleCount;
@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSString *voltage_mV;
@property (nonatomic, assign) BOOL hasBatteryInstalled;

- (NSDictionary *)dictionaryRepresentation;

@end
