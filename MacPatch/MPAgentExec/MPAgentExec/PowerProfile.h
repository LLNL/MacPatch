//
//  PowerProfile.h
//  DictionaryTest
//
//  Created by Heizer, Charles on 1/15/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PowerProfile : NSObject

@property (nonatomic, strong) NSString *profileName;
@property (nonatomic, strong) NSString *wake_On_LAN;
@property (nonatomic, strong) NSString *standby_Enabled;
@property (nonatomic, strong) NSString *display_Sleep_Uses_Dim;
@property (nonatomic, strong) NSString *standby_Delay;
@property (nonatomic, strong) NSString *hibernate_File;
@property (nonatomic, strong) NSString *darkWakeBackgroundTasks;
@property (nonatomic, strong) NSString *gpuSwitch;
@property (nonatomic, strong) NSString *prioritizeNetworkReachabilityOverSleep;
@property (nonatomic, strong) NSString *disk_Sleep_Timer;
@property (nonatomic, strong) NSString *system_Sleep_Timer;
@property (nonatomic, strong) NSString *hibernate_Mode;
@property (nonatomic, strong) NSString *autoPowerOff_Delay;
@property (nonatomic, strong) NSString *display_Sleep_Timer;
@property (nonatomic, strong) NSString *autoPowerOff_Enabled;
@property (nonatomic, strong) NSString *ttySPreventSleep;
@property (nonatomic, strong) NSString *wake_On_AC_Change;
@property (nonatomic, strong) NSString *reduceBrightness;
@property (nonatomic, strong) NSString *wake_On_Clamshell_Open;

- (id)initWithProfileName:(NSString *)aProfileName;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)parseWithDictionary:(NSDictionary *)aDictionary;

@end
