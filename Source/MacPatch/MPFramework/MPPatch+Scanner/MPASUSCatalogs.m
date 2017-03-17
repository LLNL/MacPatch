//
//  MPASUSCatalogs.m
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

#import "MPASUSCatalogs.h"
#import "MPWebServices.h"
#import "MPNetworkUtils.h"
#import "MPSystemInfo.h"

#undef  ql_component
#define ql_component lcl_cMPASUSCatalogs

@interface MPASUSCatalogs ()

- (NSArray *)randomizeArray:(NSArray *)arrayToRandomize;

@end

@implementation MPASUSCatalogs

-(id)init
{
    self = [super init];
	if (self)
    {
        mpNetworkUtils = [[MPNetworkUtils alloc] init];
        fm = [NSFileManager defaultManager];
    }
    return self;
}

#pragma mark -


- (BOOL)writeCatalogURL:(NSString *)aCatalogURL
{
	BOOL result = TRUE;
	NSMutableDictionary *tmpDefaults = [NSMutableDictionary dictionaryWithContentsOfFile:ASUS_PLIST_PATH];
	if (aCatalogURL) {
		[tmpDefaults setObject:aCatalogURL forKey:@"CatalogURL"];
	} else {
		qlerror(@"Unable to set catalog url (%@), using Apple built-in.", aCatalogURL);
		if ([tmpDefaults objectForKey:@"CatalogURL"]) {
			[tmpDefaults removeObjectForKey:@"CatalogURL"];
        }
        return FALSE;
	}
	
	@try
    {
        NSDictionary *osVerInfo = [MPSystemInfo osVersionOctets];
        if ([[osVerInfo objectForKey:@"minor"] intValue] >= 10)
        {
            // For Mac OS X 10.10 or higher
            qlinfo(@"Setting catalog using softwareupdate, to %@",aCatalogURL);
            [NSTask launchedTaskWithLaunchPath:@"/usr/sbin/softwareupdate" arguments:[NSArray arrayWithObjects:@"--set-catalog",aCatalogURL,nil]];
        }
        else
        {
            qlinfo(@"Setting catalog using writeToFile.");
            qldebug(@"%@",tmpDefaults);
            [tmpDefaults writeToFile:ASUS_PLIST_PATH atomically:NO];
        }
	}
	@catch ( NSException *e )
    {
		qlerror(@"Error unable to write new config.");
		result = FALSE;
	}
	
	return result;
}

- (BOOL)disableCatalogURL
{
	// Disabled this, using interceptor now...
	//return [self writeCatalogURL:@"http://127.0.0.1:8088/index.sucatalog"];
	return YES;
}

#pragma mark - New methods

- (NSDictionary *)getSUCatalogsFromServer
{
    NSDictionary	*susListDict = NULL;
    NSError *err = nil;
    
    MPWebServices *mpw = [[MPWebServices alloc] init];
    susListDict = [mpw getSUSServerList:&err];
    if (err) {
        qlerror(@"%@",[err localizedDescription]);
        return nil;
    }
    return susListDict;
}

- (BOOL)checkAndSetCatalogURL
{
    BOOL result = FALSE;
    NSMutableArray *catalogs = [[NSMutableArray alloc] init];
    NSDictionary *susDict;
    // Check for SUS Plist if missing then download and randomize
    if (![fm fileExistsAtPath:AGENT_SUS_SERVERS_PLIST]) {
        [self writeSUServerListToDisk:[self getSUCatalogsFromServer] error:NULL];
    }
    
    susDict = [NSDictionary dictionaryWithContentsOfFile:AGENT_SUS_SERVERS_PLIST];
    
    // Get Array of apporpriate OS Catalogs
    NSDictionary *osVers = [MPSystemInfo osVersionOctets];
    NSString *osMinor = [[osVers objectForKey:@"minor"] stringValue];
    if ([susDict objectForKey:@"servers"]) {
        if ([[susDict objectForKey:@"servers"] isKindOfClass:[NSArray class]]) {
            for (NSDictionary *server in [susDict objectForKey:@"servers"])
            {
                id _os_minor = [server objectForKey:@"os"];
                if (![self isOfNSStringType:_os_minor]) {
                    _os_minor = [[server objectForKey:@"os"] stringValue];
                }

                if ([[server objectForKey:@"os"] isEqualToString:osMinor]) {
                    if ([server objectForKey:@"servers"]) {
                        if ([[server objectForKey:@"servers"] isKindOfClass:[NSArray class]]) {
                            for (NSDictionary *item in [server objectForKey:@"servers"]) {
                                [catalogs addObject:[item objectForKey:@"CatalogURL"]];
                            }
                        }
                    }
                    break;
                }
            }
        }
    }
    
    qldebug(@"SU Catalogs for OS: %@",catalogs);
    
    NSString *newCatalogURL = NULL;
    if ([catalogs count] > 0 ) {
        for(int i=0;i<[catalogs count];i++) {
            // Check to make sure host is reachable and we get a vaild return code
            if ([mpNetworkUtils isHostURLReachable:[catalogs objectAtIndex:i]]) {
                if ([mpNetworkUtils isURLValid:[catalogs objectAtIndex:i] returnCode:200]) {
                    qldebug(@"SU Catalog verified: %@",[catalogs objectAtIndex:i]);
                    newCatalogURL = [catalogs objectAtIndex:i];
                    break;
                } else {
                    qlerror(@"CatalogURL: %@ did not return 200.",[catalogs objectAtIndex:i]);
                    continue;
                }
            } else {
                qlerror(@"CatalogURL: %@ is not reachable.",[catalogs objectAtIndex:i]);
                continue;
            }
        }
        
        if ([self writeCatalogURL:newCatalogURL]) {
            result = YES;
        }
    } else {
        // CatalogURL is not defined, use the default Apple Config
        result = YES;
    }
    
    return result;
}

- (BOOL)usingCurrentSUSList:(NSError **)err
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
        
        NSString *_rmtVerNo = [jData objectForKey:@"version"];
        NSString *_rmtLstID = [jData objectForKey:@"listid"];
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

- (BOOL)writeSUServerListToDisk:(NSDictionary *)susDict error:(NSError **)err
{
    // Check to see if it's the latest version
    if ([self usingCurrentSUSList:nil])
    {
        return YES;
    }
    
    NSMutableDictionary *susDictNew = [[NSMutableDictionary alloc] initWithDictionary:susDict];
    NSMutableDictionary *serverDict;
    NSMutableArray *susDictServerArr = [[NSMutableArray alloc] init];
    NSMutableArray *_staticItems;
    NSMutableArray *_randItems;
    NSMutableArray *_randComplete;
    
    if ([susDict objectForKey:@"server"]) {
        if ([[susDict objectForKey:@"server"] isKindOfClass:[NSArray class]]) {
            for (NSDictionary *server in [susDict objectForKey:@"server"])
            {
                serverDict = [NSMutableDictionary dictionaryWithDictionary:server];
                if ([server objectForKey:@"servers"]) {
                    if ([[server objectForKey:@"servers"] isKindOfClass:[NSArray class]])
                    {
                        // Create New Mutable Array for _staticItems and _randItems
                        _staticItems = [[NSMutableArray alloc] init];
                        _randItems = [[NSMutableArray alloc] init];
                        // Loop and sort based on serverType
                        for (NSDictionary *item in [server objectForKey:@"servers"]) {
                            if ([[item objectForKey:@"serverType"] isEqualToString:@"1"])
                            {
                                [_staticItems addObject:item];
                            } else {
                                [_randItems addObject:item];
                            }
                        }
                        
                        // Sort Static Items
                        [_staticItems sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"serverType" ascending:YES], nil]];
                        _randComplete = [[NSMutableArray alloc] init];
                        
                        // Randomize the servers
                        if ([_randItems count] > 1) {
                            [_randComplete addObjectsFromArray:[self randomizeArray:(NSArray *)_randItems]];
                        }
                        // Static Items
                        if ([_staticItems count] > 1) {
                            [_randComplete addObjectsFromArray:_staticItems];
                        }
                        
                        [serverDict setObject:_randComplete forKey:@"servers"];
                    }
                }
                // Add the randomized array of catalogURLs
                [susDictServerArr addObject:serverDict];

            } // For Loop in server
            
            // Add in the Randomized lists
            [susDictNew setObject:susDictServerArr forKey:@"server"];
        } else {
            qlerror(@"SU Servers object was not os correct type.");
            return NO;
        }
    } else {
        qlerror(@"SU Servers object was not found.");
        return NO;
    }
    
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
    
    // Write Changes to disk
    [susDictNew writeToFile:AGENT_SUS_SERVERS_PLIST atomically:NO];
    return YES;
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

- (BOOL)isOfNSStringType:(id)obj
{
    if ([[obj className] isMemberOfClass: [NSString class]]) {
        return YES;
    }
    if ([[obj class] isKindOfClass: [NSString class]]) {
        return YES;
    }
    if ([[obj classForCoder] isSubclassOfClass: [NSString class]]) {
        return YES;
    }
    
    return NO;
}


@end
