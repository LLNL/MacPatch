//
//  MPJson.h
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

@class MPServerConnection;
@class MPASINet;

@interface MPJson : NSObject 
{
    MPServerConnection  *mpServerConnection;
    
@private
	BOOL            useSSL;
	BOOL            mpHostIsReachable;
	NSString        *l_Host;
	NSString        *l_Port;
	NSString        *l_jsonURL;
    NSString        *l_jsonURLPlain;
    NSDictionary    *l_defaults;
    NSString        *l_cuuid;
    
    MPASINet        *asiNet;
}

@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, assign) BOOL mpHostIsReachable;
@property (nonatomic, retain) NSString *l_Host;
@property (nonatomic, retain) NSString *l_Port;
@property (nonatomic, retain) NSString *l_jsonURL;
@property (nonatomic, retain) NSString *l_jsonURLPlain;
@property (nonatomic, retain) NSDictionary *l_defaults;
@property (nonatomic, retain) NSString *l_cuuid;

- (id)initWithServerConnection:(MPServerConnection *)aSrvObj cuuid:(NSString *)aCUUID;

// Methods
- (NSDictionary *)getCatalogURLSForOS:(NSString *)aOSVer error:(NSError **)err;
- (NSDictionary *)downloadPatchGroupContent:(NSError **)err;

// Software Distribution
- (BOOL)postJSONDataForMethod:(NSString *)aMethod data:(NSDictionary *)aData error:(NSError **)err;

@end
