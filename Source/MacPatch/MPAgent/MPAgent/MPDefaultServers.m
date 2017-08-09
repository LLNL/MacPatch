//
//  MPDefaultServers.m
//  MPAgent
//
//  Created by Charles Heizer on 7/21/17.
//  Copyright © 2017 LLNL. All rights reserved.
//

#import "MPDefaultServers.h"
#import "MacPatch.h"

@implementation MPDefaultServers

- (void)createDefaultServersList
{
    NSDictionary *defaults;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:AGENT_SERVERS_PLIST])
    {
        defaults = [NSDictionary dictionaryWithContentsOfFile:AGENT_PREFS_PLIST];
        
        NSMutableDictionary *_servers = [NSMutableDictionary new];
        [_servers setObject:@"1" forKey:@"id"];
        [_servers setObject:@"Default" forKey:@"name"];
        [_servers setObject:@"version" forKey:@"1"];
        
        NSMutableArray *list = [NSMutableArray new];
        
        NSDictionary *master = @{@"host": [defaults objectForKey:@"MPServerAddress"], @"port": [defaults objectForKey:@"MPServerPort"],
                                 @"serverType": [NSNumber numberWithInteger:1], @"useHTTPS": [defaults objectForKey:@"MPServerSSL"],
                                 @"useTLSAuth": [NSNumber numberWithInteger:0], @"allowSelfSigned": [defaults objectForKey:@"MPServerAllowSelfSigned"]};
        
        [list addObject:master];
        // If Proxy is configured
        if ([[defaults objectForKey:@"MPProxyEnabled"] boolValue])
        {
            NSDictionary *proxy = @{@"host": [defaults objectForKey:@"MPProxyServerAddress"], @"port": [defaults objectForKey:@"MPProxyServerPort"],
                                    @"serverType": [NSNumber numberWithInteger:1], @"useHTTPS": [defaults objectForKey:@"MPServerSSL"],
                                    @"useTLSAuth": [NSNumber numberWithInteger:0], @"allowSelfSigned": [defaults objectForKey:@"MPServerAllowSelfSigned"]};
            [list addObject:proxy];
        }
        [_servers setObject:list forKey:@"servers"];
        
        qldebug(@"Sefault servers plist: %@", _servers);
        [_servers writeToFile:AGENT_SERVERS_PLIST atomically:NO];
    }
}

@end
