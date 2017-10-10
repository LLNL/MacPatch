//
//  MacPatch.h
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

#import <Cocoa/Cocoa.h>
#import "Constants.h"
// Logging
#import "lcl.h"
#import "MPLog.h"
// Uitlities & Networking
#import "MPNetworkUtils.h"
#import "MPDefaults.h"
#import "MPDiskUtil.h"
#import "MPSystemInfo.h"
#import "MPDate.h"
#import "MPClientCheckInData.h"
#import "MPNSTask.h"
#import "MPClientInfo.h"
#import "GCDTask.h"

// New Networking
#import "MPNetConfig.h"
#import "MPNetRequest.h"
#import "MPNetServer.h"
#import "MPJsonResult.h"
#import "MPResult.h"
#import "Reachability.h"
#import "MPServerList.h"
#import "MPSUServerList.h"

#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"
#import "AFSecurityPolicy.h"
#import "AFNetworkReachabilityManager.h"

#import "AFURLSessionManager.h"
#import "AFHTTPSessionManager.h"

#import "AFHTTPSessionManager+Synchronous.h"
/*
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"
#import "AFSecurityPolicy.h"
#import "AFNetworkReachabilityManager.h"

#import "AFURLConnectionOperation.h"
#import "AFHTTPRequestOperation.h"
#import "AFHTTPRequestOperationManager.h"

#if ( ( defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090) || \
( defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000 ) )
    #import "AFURLSessionManager.h"
    #import "AFHTTPSessionManager.h"
#endif
*/

// Networking Add for MP 3.1.0
#import "MPHTTPRequest.h"
#import "MPWSResult.h"
#import "STHTTPRequest.h"

// Patching & Scanning
#import "MPAsus.h"
#import "MPPatchScan.h"
#import "MPBundle.h"
#import "MPFileCheck.h"
#import "MPOSCheck.h"
#import "MPScript.h"
#import "MPASUSCatalogs.h"
#import "MPInstaller.h"
#import "MPApplePatch.h"
#import "MPCustomPatch.h"

// AntiVirus
// #import "MPAntiVirus.h"

// Software Distribution
#import "MPSWTasks.h"
#import "MPSWInstaller.h"

// WebServices
#import "MPDataMgr.h"
#import "MPWebServices.h"
#import "MPFailedRequests.h"

// Crypto
#import "MPCrypto.h"
#import "MPCodeSign.h"
#import "MPKeychain.h"
#import "MPKeyItem.h"
#import "MPSimpleKeychain.h"
#import "MPRemoteFingerprint.h"

// Helpers
#import "NSString+Helper.h"
#import "NSString+Hash.h"
#import "NSFileManager+Helper.h"
#import "NSFileManager+DirectoryLocations.h"
#import "NSDictionary+Helper.h"
#import "NSMutableDictionary+Helper.h"
#import "NSDate+Helper.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"

// Inventory Plugin
//#import "InventoryPlugin.h"
