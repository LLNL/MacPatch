//
//  MPProxySyncController.h
//  MPProxySync
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

@interface MPProxySyncController : NSObject
{
    NSDictionary    *defaults;
    MPDefaults      *prefs;

@private
	NSString *logResult;
    NSArray *remotePatchContent;
    int numberOfPatchesSyncronnized;
}

@property (nonatomic, copy) NSDictionary *defaults;
@property (nonatomic, strong) NSString *logResult;
@property (nonatomic, copy) NSArray *remotePatchContent;
@property (nonatomic) int numberOfPatchesSyncronnized;

- (id)initWithDefaults:(NSDictionary *)aDictionary;
- (BOOL)createBaseContentDirs;
- (BOOL)createBaseContentDirs:(NSString *)aDIR;

- (void)syncContent;
- (void)syncSWContent;

- (NSArray *)getRemotePatchContentForMethod:(NSString *)method error:(NSError **)err;
- (BOOL)postSyncResults:(NSError **)err;

- (BOOL)downloadPatchContent:(NSArray *)aContent;
- (BOOL)checkFileHash:(NSString *)aFilePath validHash:(NSString *)aValidHash;
- (NSString *)downloadPatch:(NSString *)aURL error:(NSError **)err;
- (NSString *)createTempDirFromURL:(NSString *)aURL;

@end
