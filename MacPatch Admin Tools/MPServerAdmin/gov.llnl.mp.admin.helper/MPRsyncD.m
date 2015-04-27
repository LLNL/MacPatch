//
//  MPRsyncD.m
//  mpRsyncTool
//
//  Created by Heizer, Charles on 4/3/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import "MPRsyncD.h"

#define RSYNC_PLIST @"/Library/MacPatch/Server/conf/etc/.mpRsyncd.plist"
#define RSYNC_CONF @"/Library/MacPatch/Server/conf/etc/rsyncd.conf"

@interface MPRsyncD ()
{
    NSMutableDictionary *confPlist;
    NSFileManager *fm;
}

- (NSDictionary *)defaultContent;
- (NSDictionary *)defaultConfig;
@end

@implementation MPRsyncD

@synthesize confFile;
@synthesize globalConfig;
@synthesize contentWeb;
@synthesize contentPatches;
@synthesize contentSW;

- (id)init
{
    self = [super init];
    fm = [NSFileManager defaultManager];
    confFile = RSYNC_CONF;
    if ([fm fileExistsAtPath:RSYNC_PLIST]) {
        confPlist = [NSMutableDictionary dictionaryWithContentsOfFile:RSYNC_PLIST];
    }
    return self;
}

- (id)initWithConfig:(NSString *)filePath
{
    self = [super init];
    fm = [NSFileManager defaultManager];
    confFile = RSYNC_CONF;
    if ([fm fileExistsAtPath:filePath]) {
        [self readPlistConfig:filePath];
    } else {
        NSLog(@"File %@ not found.",filePath);
    }
    return self;
}

- (BOOL)readPlistConfig:(NSString *)plistPath
{
    if ([fm fileExistsAtPath:plistPath]) {
        confPlist = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    } else {
        NSLog(@"File %@ not found.",plistPath);
        return NO;
    }
    
    globalConfig = [confPlist objectForKey:@"global"];
    contentWeb = [confPlist objectForKey:@"mpContentWeb"];
    contentPatches = [confPlist objectForKey:@"mpContentPatches"];
    contentSW = [confPlist objectForKey:@"mpContentSW"];
    
    return YES;
}

- (void)writeRSyncdConfig
{
    NSMutableArray *lines = [NSMutableArray new];
    [lines addObject:@"# AUTO GENERATED FILE, DO NOT EDIT"];
    [lines addObject:@"# "];
    [lines addObject:@"# rsyncd.conf -see rsyncd.conf(5)"];
    [lines addObject:@"# "];
    [lines addObject:@"# "];
    
    NSDictionary *d;
    NSString *lineStr;
    for (d in globalConfig.allKeys) {
        lineStr = [NSString stringWithFormat:@"%@ = %@",d,[globalConfig objectForKey:d]];
        [lines addObject:lineStr];
    }
    [lines addObject:@" "];
    [lines addObject:@"[mpContentWeb]"];
    for (d in contentWeb.allKeys) {
        lineStr = [NSString stringWithFormat:@"\t%@ = %@",d,[contentWeb objectForKey:d]];
        [lines addObject:lineStr];
    }
    [lines addObject:@" "];
    [lines addObject:@"[mpContentPatches]"];
    for (d in contentPatches.allKeys) {
        lineStr = [NSString stringWithFormat:@"\t%@ = %@",d,[contentPatches objectForKey:d]];
        [lines addObject:lineStr];
    }
    [lines addObject:@" "];
    [lines addObject:@"[mpContentSW]"];
    for (d in contentSW.allKeys) {
        lineStr = [NSString stringWithFormat:@"\t%@ = %@",d,[contentSW objectForKey:d]];
        [lines addObject:lineStr];
    }
    [lines addObject:@" "];
    
    NSString *fullString = [lines componentsJoinedByString:@"\n"];
    
    NSError *err = nil;
    [fullString writeToFile:confFile atomically:NO encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"%@",err.localizedDescription);
    }
}

- (void)writeDefaultPlistConfig
{
    NSDictionary *d = [self defaultConfig];
    if (![d writeToFile:RSYNC_PLIST atomically:NO]) {
        NSLog(@"Unable to write default rsyncd plist.");
    }
}

#pragma mark - UI API's
// One Method to read settings from Plist
- (NSDictionary *)readContentSettingsForUI
{
    // If No Default Rsync Plist, then write one
    if (![fm fileExistsAtPath:RSYNC_PLIST]) {
        [self writeDefaultPlistConfig];
    }
    
    if (![self readPlistConfig:RSYNC_PLIST]) {
        return nil;
    }
    
    NSMutableDictionary *d = [NSMutableDictionary new];
    [d setObject:[contentWeb objectForKey:@"hosts allow"] forKey:@"hosts allow"];
    [d setObject:[contentWeb objectForKey:@"hosts deny"] forKey:@"hosts deny"];
    [d setObject:[globalConfig objectForKey:@"max connections"] forKey:@"max connections"];
    
    return (NSDictionary *)d;
}

// One Method to write changes from UI
- (BOOL)writeChangesForHostsAndConnections:(NSString *)hostAllow hostsDeny:(NSString *)hostDeny connections:(NSString *)maxConnextions
{
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:confPlist];
    [d setValue:maxConnextions forKeyPath:@"global.max connections"];
    [d setValue:hostAllow forKeyPath:@"mpContentWeb.hosts allow"];
    [d setValue:hostAllow forKeyPath:@"mpContentPatches.hosts allow"];
    [d setValue:hostAllow forKeyPath:@"mpContentSW.hosts allow"];
    [d setValue:hostDeny forKeyPath:@"mpContentWeb.hosts deny"];
    [d setValue:hostDeny forKeyPath:@"mpContentPatches.hosts deny"];
    [d setValue:hostDeny forKeyPath:@"mpContentSW.hosts deny"];
    
    BOOL result = [d writeToFile:RSYNC_PLIST atomically:NO];
    [self readPlistConfig:RSYNC_PLIST];
    [self writeRSyncdConfig];
    
    return result;
}

#pragma mark - Default Config Data

- (NSDictionary *)defaultContent
{
    NSDictionary *content = @{ @"path" : @"/private/tmp", @"read only" : @"yes",
                               @"comment" : @"Content", @"uid" : @"79", @"gid": @"70", @"list": @"yes",
                               @"local file": @"/var/run/rsync_mp_data.lock", @"hosts allow": @"127.0.0.1, localhost",
                               @"hosts deny": @"*"};
    return content;
}

- (NSDictionary *)defaultConfig
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    NSDictionary *global = @{ @"pid file" : @"/var/run/rsyncd.pid", @"use chroot" : @"yes",
                              @"syslog facility" : @"ftp", @"max connections" : @"2" };
    [d setObject:global forKey:@"global"];
    
    NSMutableDictionary *_contentWeb = [NSMutableDictionary dictionaryWithDictionary:[self defaultContent]];
    [_contentWeb setObject:@"/Library/MacPatch/Content/Web" forKey:@"path"];
    [_contentWeb setObject:@"MacPatch Content" forKey:@"comment"];
    [d setObject:_contentWeb forKey:@"mpContentWeb"];
    
    NSMutableDictionary *_contentPatches = [NSMutableDictionary dictionaryWithDictionary:[self defaultContent]];
    [_contentPatches setObject:@"/Library/MacPatch/Content/Web/patches" forKey:@"path"];
    [_contentPatches setObject:@"MacPatch Content Patches" forKey:@"comment"];
    [d setObject:_contentPatches forKey:@"mpContentPatches"];
    
    NSMutableDictionary *_contentSW = [NSMutableDictionary dictionaryWithDictionary:[self defaultContent]];
    [_contentSW setObject:@"/Library/MacPatch/Content/Web/sw" forKey:@"path"];
    [_contentSW setObject:@"MacPatch Content SW" forKey:@"comment"];
    [d setObject:_contentSW forKey:@"mpContentSW"];

    return (NSDictionary *)d;
}

@end
