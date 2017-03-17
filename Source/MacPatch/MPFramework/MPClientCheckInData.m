//
//  MPClientCheckInData.m
/*
 Copyright (c) 2017, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.
 
 This file is part of MacPatch, a program for installing and patching
 software.
 
 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.
 
 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.
 
 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import "MPClientCheckInData.h"
#import "MPSystemInfo.h"
#import "MPDate.h"

#undef  ql_component
#define ql_component lcl_cMPClientCheckInData

@interface MPClientCheckInData ()

@property (nonatomic, readwrite, strong) NSDictionary *hostNames;
@property (nonatomic, readwrite, strong) NSDictionary *osVersion;
@property (nonatomic, readwrite, strong) NSDictionary *agentData;
@property (nonatomic, readwrite, strong) NSDictionary *consoleUserData;

- (int)collectAgentData:(NSError **)error;

@end

@implementation MPClientCheckInData

@synthesize hostNames;
@synthesize osVersion;
@synthesize agentData;
@synthesize consoleUserData;

- (id)init
{
    self = [super init];
	if (self) {
		[self setHostNames:[MPSystemInfo hostAndComputerNames]];
        [self setOsVersion:[MPSystemInfo osVersionInfo]];
        [self setConsoleUserData:[MPSystemInfo consoleUserData]];
        [self collectAgentData:NULL];
    }
	
    return self;
}

#pragma mark - Private Methods

- (int)collectAgentData:(NSError **)error
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:AGENT_PREFS_PLIST]) {
        [self setAgentData:[NSDictionary dictionaryWithContentsOfFile:AGENT_PREFS_PLIST]];
        return 0;
    } else {
        if (error != NULL) *error = [NSError errorWithDomain:@"collectAgentData" 
                                                        code:1 
                                                    userInfo:[NSDictionary dictionaryWithObject:@"Agent plist not found." forKey:NSLocalizedDescriptionKey]];
        return 1;
    }
}


#pragma mark - Public Methods

- (NSDictionary *)collectClientCheckInData
{
	
	NSMutableDictionary *clientInfoDict = [[NSMutableDictionary alloc] init];
	[clientInfoDict setObject:[MPSystemInfo clientUUID] forKey:@"cuuid"];
	[clientInfoDict setObject:[hostNames objectForKey:@"localHostName"] forKey:@"hostname"];
	[clientInfoDict setObject:[hostNames objectForKey:@"localComputerName"] forKey:@"computername"];
	[clientInfoDict setObject:[MPSystemInfo getMacAddressForInterface:@"en0"] forKey:@"macaddr"];
	[clientInfoDict setObject:[MPSystemInfo getIPAddressForInterface:@"en0"] forKey:@"ipaddr"];
	[clientInfoDict setObject:[osVersion objectForKey:@"ProductName"] forKey:@"ostype"];
	[clientInfoDict setObject:[osVersion objectForKey:@"ProductVersion"] forKey:@"osver"];
	[clientInfoDict setObject:@"0" forKey:@"needsreboot"];
    [clientInfoDict setObject:[NSString stringWithFormat:@"%d",(int)[MPSystemInfo hostNeedsReboot]] forKey:@"needsreboot"];
	[clientInfoDict setObject:[MPDate dateTimeStamp] forKey:@"sdate"];
	[clientInfoDict setObject:[consoleUserData objectForKey:@"consoleUser"] forKey:@"consoleUser"];
	[clientInfoDict setObject:[consoleUserData objectForKey:@"consoleUserUID"] forKey:@"consoleUserUID"];
	[clientInfoDict setObject:[consoleUserData objectForKey:@"consoleUserGID"] forKey:@"consoleUserGID"];
    
	for (id keyObj in [agentData allKeys]) {
		[clientInfoDict setObject:[agentData objectForKey:keyObj] forKey:keyObj];	
	}
	
	NSDictionary *results = [NSDictionary dictionaryWithDictionary:clientInfoDict];
	
	qldebug(@"clientCheckInData: %@",results);
	return results;
}

@end
