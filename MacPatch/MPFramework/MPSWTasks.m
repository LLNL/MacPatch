//
//  MPSWTasks.m
/*
 Copyright (c) 2013, Lawrence Livermore National Security, LLC.
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

#import "MPSWTasks.h"
#import "MPWebServices.h"

@interface MPSWTasks () 

@end

@implementation MPSWTasks

@synthesize mpHostConfigInfo;

@synthesize defaults;
@synthesize groupHash;
@synthesize groupName;

- (id)init
{
    return [self initWithGroupAndHash:nil hash:@"NA"];
}

- (id)initWithGroupAndHash:(NSString *)aGroup hash:(NSString *)aHash;
{
    self = [super init];
    if (self)
    {
        MPDefaults *d = [[MPDefaults alloc] init];
        [self setDefaults:[d defaults]];

        if (aGroup) {
            [self setGroupName:aGroup];
        } else {
            if ([defaults objectForKey:@"SWDistGroup"]) {
                [self setGroupName:[defaults objectForKey:@"SWDistGroup"]];
            } else {
                [self setGroupName:@"NA"];
            }
        }    
        [self setGroupHash:aHash];
    }
    return self;
}


- (void)main 
{
    NSError *error = nil;
    NSString *_remoteGroupHash = nil;
    _remoteGroupHash = [self getHashForGroup:&error];
    if (error) {
        qlerror(@"Error [getHashForGroup]: %@",[error description]);
        return;
    }
    
    if ([groupHash isEqualTo:NULL] || ([groupHash isEqualToString:_remoteGroupHash] == NO)) {
        error = nil;
        id jResult = [self getSWTasksForGroupFromServer:&error]; 
        if (error) {
            qlerror(@"Error [getSWTasksForGroupFromServer]: %@",[error description]);
            return;
        }
        if (jResult != nil) {
            [jResult writeToFile:[NSString stringWithFormat:@"%@/Data/.swTasks.plist",MP_ROOT_CLIENT] 
                      atomically:YES 
                        encoding:NSUTF8StringEncoding error:NULL];
        }
    }
    
}

- (NSString *)getHashForGroup:(NSError **)err
{
    NSError *error = nil;
    NSString *result = @"NA";
    MPWebServices *mpws = [[MPWebServices alloc] init];
    result = [mpws getHashForSWTaskGroup:self.groupName error:&error];
    if (error) {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return @"NA";
    }
    
    qldebug(@"Result: %@",result);
    return result;    
}

- (id)getSWTasksForGroupFromServer:(NSError **)err
{
    NSError *error = nil;
    id result = nil;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    result = [mpws getSWTasksForGroup:self.groupName error:&error];
    if (error) {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return @"NA";
    }
    
    qldebug(@"Result: %@",result);
    return result;
}

- (int)postInstallResults:(int)resultNo resultText:(NSString *)resultString task:(NSDictionary *)taskDict
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"json" forKey:@"type"];
    [params setObject:[MPSystemInfo clientUUID] forKey:@"ClientID"];
    [params setObject:[taskDict objectForKey:@"id"] forKey:@"SWTaskID"];
    [params setObject:[taskDict valueForKeyPath:@"Software.sid"] forKey:@"SWDistID"];
    [params setObject:[NSNumber numberWithInt:resultNo] forKey:@"ResultNo"];
    [params setObject:resultString forKey:@"ResultString"];
    [params setObject:@"i" forKey:@"Action"];


    NSError *error = nil;
    int result = -1;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    result = [mpws postSWInstallResults:(NSDictionary *)params error:&error];
    if (error)
    {
        qlerror(@"%@",error.localizedDescription);
        return 1;
    }

    qldebug(@"Result [postSWInstallResults]: %d",result);
    return result;
}

- (int)postUnInstallResults:(int)resultNo resultText:(NSString *)resultString task:(NSDictionary *)taskDict
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"json" forKey:@"type"];
    [params setObject:[MPSystemInfo clientUUID] forKey:@"ClientID"];
    [params setObject:[taskDict objectForKey:@"id"] forKey:@"SWTaskID"];
    [params setObject:[taskDict valueForKeyPath:@"Software.sid"] forKey:@"SWDistID"];
    [params setObject:[NSNumber numberWithInt:resultNo] forKey:@"ResultNo"];
    [params setObject:resultString forKey:@"ResultString"];
    [params setObject:@"u" forKey:@"Action"];


    NSError *error = nil;
    int result = -1;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    result = [mpws postSWInstallResults:(NSDictionary *)params error:&error];
    if (error)
    {
        qlerror(@"%@",error.localizedDescription);
        return 1;
    }

    qldebug(@"Result [postUnInstallResults]: %d",result);
    return result;
}

@end
