//
//  MPFirmware.m
//  MPAgent
//
//  Created by Charles Heizer on 1/6/17.
//  Copyright © 2017 LLNL. All rights reserved.
//

#import "MPFirmware.h"

@interface MPFirmware ()

@property (nonatomic, assign, readwrite) int state;
@property (nonatomic, strong, readwrite) NSString *mode;
@property (nonatomic, strong, readwrite) NSString *options;
@property (nonatomic, strong, readwrite) NSString *status;
@property (nonatomic, strong, readwrite) NSError *error;

- (int)queryFirmwarePasswordState;
- (void)queryFirmwarePasswordMode;

@end

@implementation MPFirmware

@synthesize mode    = _mode;
@synthesize options = _options;
@synthesize status  = _status;
@synthesize error   = _error;

- (id)init
{
    self = [super init];
    if (self)
    {
        _error = nil;
        
        [self setState:-1];
        [self setStatus:@"na"];
        [self setMode:@"na"];
        [self setOptions:@"na"];
        
        [self refresh];
    }
    return self;
}

- (void)refresh
{
    if (floor(NSAppKitVersionNumber) < 1343) {
        /* earlier than 10.8 system */
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Firmware Password Inventory Requires 10.10 and higher." forKey:NSLocalizedDescriptionKey];
        _error = [NSError errorWithDomain:@"myDomain" code:200 userInfo:errorDetail];
        [self setStatus:@"Firmware Password Inventory Requires 10.10 and higher."];
        return;
    }
    
    [self setState:[self queryFirmwarePasswordState]];
    [self queryFirmwarePasswordMode];
}

- (int)queryFirmwarePasswordState
{
    NSTask *task = [NSTask new];
    NSPipe *pipe = [NSPipe new];
    
    [task setStandardOutput:pipe];
    [task setLaunchPath:@"/usr/sbin/firmwarepasswd"];
    [task setArguments:[NSArray arrayWithObject:@"-check"]];
    [task launch];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];
    
    if ([task terminationStatus] != 0) {
        return -1;
    }
    
    if (data == nil) {
        return -1;
    }
    
    NSString *results = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    if ([results.lowercaseString isEqualToString:[@"Password Enabled: No" lowercaseString]]) {
        return 0;
    }
    if ([results.lowercaseString isEqualToString:[@"Password Enabled: Yes" lowercaseString]]) {
        return 1;
    }
    
    return -1;
}

- (void)queryFirmwarePasswordMode
{
    NSTask *task = [NSTask new];
    NSPipe *pipe = [NSPipe new];
    
    [task setStandardOutput:pipe];
    [task setLaunchPath:@"/usr/sbin/firmwarepasswd"];
    [task setArguments:[NSArray arrayWithObject:@"-mode"]];
    [task launch];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];
    
    if ([task terminationStatus] != 0) {
        return;
    }
    
    if (data == nil) {
        return;
    }
    
    NSString *results = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    NSString *trimStr0 = [[results componentsSeparatedByString: @"\n"] objectAtIndex:0];
    NSString *trimStr1 = [[results componentsSeparatedByString: @"\n"] objectAtIndex:1];
    NSString *result = [trimStr0 stringByReplacingOccurrencesOfString:@"Mode: " withString:@""];
    [self setMode:result];
    [self setOptions:trimStr1];
    return;
}

@end
