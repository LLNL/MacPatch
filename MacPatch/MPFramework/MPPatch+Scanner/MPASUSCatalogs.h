//
//  MPASUSCatalogs.h
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

#import <Cocoa/Cocoa.h>

@class MPNetworkUtils;

@interface MPASUSCatalogs : NSObject 
{
    MPNetworkUtils      *mpNetworkUtils;
    NSFileManager       *fm;
}

// Methods
- (BOOL)writeCatalogURL:(NSString *)aCatalogURL;
- (BOOL)disableCatalogURL;

/* Gets a JSON Object converted to Dictionary of all of the 
   SUS catalogs for all of the OS's */
- (NSDictionary *)getSUCatalogsFromServer;

/* Check and set the CatalogURL from the randomized array 
   of CatalogURLs from the plist on disk */
- (BOOL)checkAndSetCatalogURL;

/* Checks with the server to see if the agent has the latest
   version of the SUS Catalogs data */
- (BOOL)usingCurrentSUSList:(NSError **)err;

/* Takes the Dictionary result from getSUCatalogsFromServer
   and randomizes each list of catalogURLS and writes the 
   result to /L/MP/C/lib */
- (BOOL)writeSUServerListToDisk:(NSDictionary *)susDict error:(NSError **)err;

@end
