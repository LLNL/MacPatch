//
//  MPRsyncD.h
//  mpRsyncTool
//
//  Created by Heizer, Charles on 4/3/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPRsyncD : NSObject
{
    NSString *confFile;
    NSDictionary *globalConfig;
    NSDictionary *contentWeb;
    NSDictionary *contentPatches;
    NSDictionary *contentSW;
}

@property (nonatomic, strong) NSString *confFile;
@property (nonatomic, strong) NSDictionary *globalConfig;
@property (nonatomic, strong) NSDictionary *contentWeb;
@property (nonatomic, strong) NSDictionary *contentPatches;
@property (nonatomic, strong) NSDictionary *contentSW;

- (id)init;
- (id)initWithConfig:(NSString *)filePath;

- (BOOL)readPlistConfig:(NSString *)plistPath;
- (void)writeRSyncdConfig;
/*
 Write Default Rsync Plist
 The server admin software will read this file to set the contents of the 
 rsyncd.conf file.
*/
- (void)writeDefaultPlistConfig;

// One Method to read settings from Plist
- (NSDictionary *)readContentSettingsForUI;

// One Method to write changes from UI
- (BOOL)writeChangesForHostsAndConnections:(NSString *)hostAllow hostsDeny:(NSString *)hostDeny connections:(NSString *)maxConnextions;

@end
