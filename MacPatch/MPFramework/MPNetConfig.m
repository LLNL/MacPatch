//
//  MPNetConfig.m
//  MPLibrary
//
//  Created by Heizer, Charles on 4/3/14.
//
//

#import "MPNetConfig.h"
#import "MPNetServer.h"
#import "MPDefaults.h"

#undef  ql_component
#define ql_component lcl_cMPNetConfig

@implementation MPNetConfig
{
    NSFileManager *fm;
    NSMutableArray *tmpServers;
}

@synthesize servers;

- (id)init
{
    self = [super init];
    if (self)
    {
        fm = [NSFileManager defaultManager];
        tmpServers = [[NSMutableArray alloc] init];
        BOOL useMaster = YES;
        if ([fm fileExistsAtPath:AGENT_SERVERS_PLIST])
        {
            NSDictionary *agentServerConf = [NSDictionary dictionaryWithContentsOfFile:AGENT_SERVERS_PLIST];
            if ([agentServerConf objectForKey:@"servers"])
            {
                if ([[agentServerConf objectForKey:@"servers"] count] > 0)
                {
                    for (NSDictionary *s in [agentServerConf objectForKey:@"servers"])
                    {
                        MPNetServer *ns = [MPNetServer serverObjectWithDictionary:s];
                        [tmpServers addObject:ns];
                    }
                    self.servers = [NSArray arrayWithArray:tmpServers];
                    useMaster = NO;
                }
            }
        }

        if (useMaster == YES)
        {
            MPNetServer *sns = [[MPNetServer alloc] init];
            MPDefaults *d = [[MPDefaults alloc] init];
            NSDictionary *defaults = [d defaults];
            [sns setHost:[defaults objectForKey:@"MPServerAddress"]];
            [sns setPort:[[defaults objectForKey:@"MPServerPort"] integerValue]];
            [sns setUseHTTPS:([[defaults objectForKey:@"MPServerSSL"] integerValue] ? YES : NO)];
            [sns setUseTLSAuth:([[defaults objectForKey:@"MPClientAuth"] integerValue] ? YES : NO)];
            [sns setServerType:0];
            self.servers = [NSArray arrayWithObject:sns];
        }


    }
    return self;
}

- (id)initWithServer:(MPNetServer *)netServer
{
    self = [super init];
    if (self)
    {
        self.servers = [NSArray arrayWithObject:netServer];
    }
    return self;
}

@end
