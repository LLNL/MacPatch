//
//  MPASUSCatalogs.m
/*
 Copyright (c) 2018, Lawrence Livermore National Security, LLC.
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
#import "Suserver.h"

#undef  ql_component
#define ql_component lcl_cMPASUSCatalogs

@interface MPASUSCatalogs ()
{
    MPSettings      *settings;
    MPNetworkUtils  *mpNetworkUtils;
}

@end

@implementation MPASUSCatalogs

-(id)init
{
    self = [super init];
	if (self)
    {
        mpNetworkUtils  = [[MPNetworkUtils alloc] init];
        settings        = [MPSettings sharedInstance];
    }
    return self;
}

#pragma mark -


- (BOOL)writeCatalogURL:(NSString *)aCatalogURL
{
	BOOL result = TRUE;
    
	NSMutableDictionary *asusDefaults = [NSMutableDictionary dictionaryWithContentsOfFile:ASUS_PLIST_PATH];
	if (aCatalogURL)
    {
		[asusDefaults setObject:aCatalogURL forKey:@"CatalogURL"];
	} else {
		qlerror(@"Unable to set catalog url (%@), using Apple built-in.", aCatalogURL);
		if ([asusDefaults objectForKey:@"CatalogURL"])
        {
			[asusDefaults removeObjectForKey:@"CatalogURL"];
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
            qldebug(@"%@",asusDefaults);
            [asusDefaults writeToFile:ASUS_PLIST_PATH atomically:NO];
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

- (BOOL)checkAndSetCatalogURL
{
    NSArray *suServers = settings.suservers;
    if (suServers.count <= 0) {
        qlinfo(@"Software update server list is empty. Can not set CatalogURL");
        return YES;
    }
    
    NSString *newCatalogURL = NULL;
    for (Suserver *server in suServers)
    {
        if ([mpNetworkUtils isHostURLReachable:server.catalogURL])
        {
            if ([mpNetworkUtils isURLValid:server.catalogURL returnCode:200])
            {
                qldebug(@"SU Catalog verified: %@",server.catalogURL);
                newCatalogURL = server.catalogURL;
                break;
            } else {
                qlerror(@"CatalogURL: %@ did not return 200.",server.catalogURL);
                continue;
            }
        }
    }
    
    // No valid suserver
    if (newCatalogURL == NULL)
        return NO;
    
    return [self writeCatalogURL:newCatalogURL];
}

@end
