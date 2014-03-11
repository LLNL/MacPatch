//
//  MPWebServices.h
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

#import <Foundation/Foundation.h>

@class MPASINet;

@interface MPWebServices : NSObject
{
    @private
    MPASINet *asiNet;
    NSString *_cuuid;
    NSString *_osver;
    NSDictionary *_defaults;
}

-(id)initWithDefaults:(NSDictionary *)aDefaults;

// Methods
- (NSDictionary *)getCatalogURLSForHostOS:(NSError **)err;
- (NSDictionary *)getPatchGroupContent:(NSError **)err;
- (BOOL)postPatchScanResultsForType:(NSInteger)aPatchScanType results:(NSDictionary *)resultsDictionary error:(NSError **)err;
- (BOOL)postPatchInstallResultsToWebService:(NSString *)aPatch patchType:(NSString *)aPatchType error:(NSError **)err;

- (NSArray *)getCustomPatchScanList:(NSError **)err;
- (BOOL)postClientAVData:(NSDictionary *)aDict error:(NSError **)err;
- (NSString *)getLatestAVDefsDate:(NSError **)err;
- (NSString *)getAvUpdateURL:(NSError **)err;

- (NSDictionary *)getAgentUpdates:(NSString *)curAppVersion build:(NSString *)curBuildVersion error:(NSError **)err;
- (NSDictionary *)getAgentUpdaterUpdates:(NSString *)curAppVersion error:(NSError **)err;


- (BOOL)postDataMgrXML:(NSString *)aDataMgrXML error:(NSError **)err;
- (BOOL)postSAVDefsDataXML:(NSString *)aAVXML encoded:(BOOL)aEncoded error:(NSError **)err;


- (BOOL)postJSONDataForMethod:(NSString *)aMethod data:(NSDictionary *)aData error:(NSError **)err;
- (NSDictionary *)sendRequestUsingMethodAndArgs:(NSString *)aMethod argsDictionary:(NSDictionary *)aDict error:(NSError **)err;

- (BOOL)clientHasInvDataInDB:(NSError **)err;
- (int)postClientHasInvData:(NSError **)err;
@end
