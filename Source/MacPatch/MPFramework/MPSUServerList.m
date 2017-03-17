//
//  MPSUServerList.m
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

#import "MPSUServerList.h"

@interface MPSUServerList ()

- (NSArray *)randosmizeServersForOS:(NSArray *)aServers;

@end


@implementation MPSUServerList

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        fm = [NSFileManager defaultManager];
    }
    return self;
}

- (id)initAndGetListFromServer
{
    self = [super init];
    fm = [NSFileManager defaultManager];
    
    NSError *err = nil;
    [self getListFromServer:&err];
    if (err) {
        qlerror(@"%@",[err description]);
    }
    
    return self;
}

#pragma mark - Class Methods

- (NSDictionary *)readPlistFromHost
{
    if ([fm fileExistsAtPath:AGENT_SUS_SERVERS_PLIST])
    {
        NSDictionary *_curFile = [NSDictionary dictionaryWithContentsOfFile:AGENT_SUS_SERVERS_PLIST];
        return _curFile;
    }
    return nil;
}


#pragma mark - Get From Server

- (BOOL)usingCurrentList:(NSError **)err
{
    if ([fm fileExistsAtPath:AGENT_SUS_SERVERS_PLIST])
    {
        
        NSDictionary *_curFile = [NSDictionary dictionaryWithContentsOfFile:AGENT_SUS_SERVERS_PLIST];
        if (![_curFile objectForKey:@"version"] || ![_curFile objectForKey:@"id"]) {
            qlerror(@"Error, could not find objects version and listid.");
            return NO;
        }
        
        NSString *_curVerNo;
        if ([[_curFile objectForKey:@"version"] isKindOfClass:[NSNumber class]]) {
            _curVerNo = [[_curFile objectForKey:@"version"] stringValue];
        } else {
            _curVerNo = [_curFile objectForKey:@"version"];
        }
        
        NSString *_curLstID;
        if ([[_curFile objectForKey:@"id"] isKindOfClass:[NSNumber class]]) {
            _curLstID = [[_curFile objectForKey:@"id"] stringValue];
        } else {
            _curLstID = [_curFile objectForKey:@"id"];
        }
        
        NSError *wsErr = nil;
        MPWebServices *mpws = [[MPWebServices alloc] init];
        NSDictionary *jData = [mpws getSUSServerListVersion:_curVerNo listid:_curLstID error:&wsErr];
        if (wsErr) {
            qlerror(@"%@",wsErr.localizedDescription);
            return NO;
        }
        
        NSString *_rmtVerNo = [[jData objectForKey:@"version"] stringValue];
        NSString *_rmtLstID = [[jData objectForKey:@"listid"] stringValue];
        if ([_rmtLstID isEqualToString:_curLstID] == NO) {
            qlerror(@"List ID are different. Need to overwrite values.");
            return NO;
        }
        
        if ([_rmtVerNo intValue] > [_curVerNo intValue]) {
            qlinfo(@"Server list has been updated. Need to download a new copy.");
            return NO;
        } else {
            qlinfo(@"Server list is current.");
            return YES;
        }
        
    }
    
    return NO;
}

- (BOOL)getListFromServer:(NSError **)err
{
    // Check to see if it's the latest version
    if ([self usingCurrentList:NULL])
    {
        return YES;
    }
    
    NSError *wsErr = NO;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    NSDictionary *_curInfo = [self readPlistFromHost];
    if (!_curInfo) {
        
    }

    NSMutableDictionary *jData = [NSMutableDictionary dictionaryWithDictionary:[mpws getSUSServerList:&wsErr]];
    if (wsErr) {
        qlerror(@"%@",wsErr.localizedDescription);
        return NO;
    }
    
    NSMutableArray *_newServerList = [[NSMutableArray alloc] init];
    if (![jData objectForKey:@"servers"]) {
        qlerror(@"Servers object was not found.");
        return NO;
    }
    
    // Sort the server types, Master and Proxy get added to the end of the array
    for (NSDictionary *d in [jData objectForKey:@"servers"])
    {
        qldebug(@"Randomizig servers for 10.%@",[d objectForKey:@"os"]);
        NSMutableDictionary *curOSDict = [NSMutableDictionary dictionaryWithDictionary:[d copy]];
        NSArray *sortedServers = [self randosmizeServersForOS:[curOSDict objectForKey:@"servers"]];
        [curOSDict setObject:sortedServers forKey:@"servers"];
        
        // Add Newly Sorted Servers for OS to main array
        [_newServerList addObject:curOSDict];
    }
    
    // Add newly sorted servers array to main servers object
    [jData setObject:_newServerList forKey:@"servers"];
    
    
    // Write results to file, first make sure the path is available.
    NSError *fmErr;
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:AGENT_SUS_SERVERS_PLIST isDirectory:&isDir]) {
        fmErr = nil;
        [fm createDirectoryAtPath:[AGENT_SUS_SERVERS_PLIST stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&fmErr];
        if (fmErr) {
            qlerror(@"%@",fmErr.localizedDescription);
            return NO;
        }
    } else {
        if (isDir == NO) {
            fmErr = nil;
            [fm removeItemAtPath:AGENT_SUS_SERVERS_PLIST error:NULL];
            [fm createDirectoryAtPath:[AGENT_SUS_SERVERS_PLIST stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&fmErr];
            if (fmErr) {
                qlerror(@"%@",fmErr.localizedDescription);
                return NO;
            }
        }
    }
    
    [jData writeToFile:AGENT_SUS_SERVERS_PLIST atomically:NO];
    return YES;
}

- (NSArray *)randosmizeServersForOS:(NSArray *)aServers
{
    NSMutableArray *_staticItems     =  [NSMutableArray new];
    NSMutableArray *_randItems       =  [NSMutableArray new];
    NSMutableArray *_randComplete;
    
    for (NSDictionary *_srv in aServers) {
        if ((int)[_srv objectForKey:@"serverType"] == 1 || (int)[_srv objectForKey:@"serverType"] == 2)
        {
            [_staticItems addObject:_srv];
        } else {
            [_randItems addObject:_srv];
        }
    }
    
    // Sort Static Items, Master Server Before Proxy
    [_staticItems sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"serverType" ascending:YES], nil]];
    
    // Randomize the distribution servers
    if ([_randItems count] > 1) {
        _randComplete = [NSMutableArray arrayWithArray:[self randomizeArray:(NSArray *)_randItems]];
        [_randComplete addObjectsFromArray:_staticItems];
    } else {
        _randComplete = [NSMutableArray arrayWithArray:(NSArray *)_randItems];
        [_randComplete addObjectsFromArray:_staticItems];
    }
    
    return (NSArray *)_randComplete;
}

- (NSArray *)randomizeArray:(NSArray *)arrayToRandomize
{
    NSMutableArray *_newArray = [[NSMutableArray alloc] initWithArray:arrayToRandomize];
    NSUInteger count = [_newArray count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSInteger nElements = count - i;
        NSInteger n = (arc4random() % nElements) + i;
        [_newArray exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    
    return (NSArray *)_newArray;
}

@end
