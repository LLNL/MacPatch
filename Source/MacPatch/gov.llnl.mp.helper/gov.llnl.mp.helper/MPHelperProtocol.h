//
//  MPHelperProtocol.h
//  gov.llnl.mp.helper
/*
Copyright (c) 2024, Lawrence Livermore National Security, LLC.
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

// Rev 43

#import <Foundation/Foundation.h>

enum {
	kMPInstallStatus = 0,
	kMPProcessStatus = 1,
	kMPProcessProgress = 2,
	kMPPatchProcessStatus = 3,
	kMPPatchProcessProgress = 4,
	kMPPatchAllProcessProgress = 5,
	kMPPatchAllProcessStatus = 6,
	kMPPatchAllInstallComplete = 7,
	kMPPatchAllInstallError = 8
};
typedef NSUInteger MPPostDataType;

enum {
	kMPCopyFile = 0,
	kMPMoveFile = 1
};
typedef NSUInteger MPFileMoveAction;

enum {
	kPatchingPausedOff = 0,
	kPatchingPausedOn = 1
};
typedef NSUInteger MPPatchingPausedState;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const MPXPCErrorDomain;

NS_ASSUME_NONNULL_END

enum {
	MPGeneralError = 1000,
	MPFileHashCheckError = 1001,
	MPFileUnZipError = 1002,
	MPPreInstallScriptError = 1003,
	MPPostInstallScriptError = 1004,
	MPRemoveFileError = 1005,
	MPCopyFileError = 1006,
	MPMountDMGError = 1007,
	MPUnMountDMGError = 1008
	
};


#define kHelperServiceName @"gov.llnl.mp.helper"

// HelperToolProtocol is the NSXPCConnection-based protocol implemented by the helper tool
// and called by the app.

@protocol MPHelperProtocol

@required



// This command simply returns the version number of the tool.  It's a good idea to include a
// command line this so you can handle app upgrades cleanly.

// The next two commands imagine an app that needs to store a license key in some global location
// that's not writable by all users; thus, setting the license key requires elevated privileges.
// To manage this there's a 'read' command--which by default can be used by everyone--to return
// the key and a 'write' command--which requires admin authentication--to set the key.

//- (void)readLicenseKeyAuthorization:(NSData *)authData withReply:(void(^)(NSError * error, NSString * licenseKey))reply;
// Reads the current license key.  authData must be an AuthorizationExternalForm embedded
// in an NSData.

//- (void)writeLicenseKey:(NSString *)licenseKey authorization:(NSData *)authData withReply:(void(^)(NSError * error))reply;
// Writes a new license key.  licenseKey is the new license key string.  authData must be
// an AuthorizationExternalForm embedded in an NSData.

@optional
- (void)getVersionWithReply:(nullable void(^)(NSString * _Nullable verData))reply;
- (void)getTestWithReply:(nullable void(^)(NSString * _Nullable aString))reply;
- (void)getProfilesWithReply:(nullable void(^)(NSString * _Nullable aString, NSData * _Nullable aData))reply;

// ----------------------------------------
// Patching -------------------------------
// ----------------------------------------


/**
 Scan host for patches
 
 @param patchType - filter scan based on type All, Apple, Custom
 @param reply foundPatches, patchGroupData
 */
- (void)scanForPatchesUsingFilter:(MPPatchContentType)patchType withReply:(nullable void(^)(NSError * _Nullable error, NSData * _Nullable patches, NSData * _Nullable patchGroupData))reply;

// Patching
- (void)installPatch:(NSDictionary *_Nonnull)patch withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode))reply;
- (void)installPatch:(NSDictionary *_Nonnull)patch userInstallRebootPatch:(int)installRebootPatch withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode))reply;
- (void)installPatches:(NSArray *_Nonnull)patches withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode))reply;
- (void)installPatches:(NSArray *_Nonnull)patches userInstallRebootPatch:(int)installRebootPatch withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode))reply;
- (void)scanAndPatchSoftwareItem:(nullable NSDictionary *)aSWDict withReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;
- (void)setPatchOnLogoutWithReply:(nullable void(^)(BOOL result))reply;
- (void)setStateOnPausePatching:(MPPatchingPausedState)state withReply:(nullable void(^)(BOOL result))reply;

// ----------------------------------------
// Software -------------------------------
// ----------------------------------------

- (void)installSoftware:(NSDictionary *_Nonnull)swItem withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode, NSData * _Nullable installData))reply;
- (void)installSoftware:(NSDictionary *_Nonnull)swItem timeOut:(NSInteger)timeout withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode, NSData * _Nullable installData))reply;

- (void)runScriptFromString:(NSString *_Nonnull)script withReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;
- (void)runScriptFromFile:(NSString *_Nonnull)script withReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;
- (void)runScriptFromDirectory:(NSString *_Nonnull)scriptDir withReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;

- (void)installPackageFromZIP:(NSString *_Nonnull)pkgID environment:(NSString *_Nullable)env withReply:(nullable void(^)(NSError * _Nullable error, NSInteger installResult))reply;
- (void)copyAppFromDirToApplications:(NSString *_Nonnull)aDir action:(int)action withReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;

- (void)installPkgFromDMG:(NSString *_Nonnull)dmgPath packageID:(NSString *_Nonnull)packageID environment:(NSString *_Nullable)aEnv withReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;

- (void)uninstallSoftware:(NSString *_Nonnull)swTaskID withReply:(nullable void(^)(NSInteger resultCode))reply;

// ----------------------------------------
// Misc     -------------------------------
// ----------------------------------------
- (void)unzip:(NSString *_Nonnull)aFile withReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;
- (void)removeFile:(NSString *_Nonnull)aFile withReply:(nullable void(^)(NSInteger result))reply;

// ----------------------------------------
// Client Checkin     ---------------------
// ----------------------------------------
- (void)runCheckInWithReply:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nonnull result))reply;

// ----------------------------------------
// MacPatch Client Database      ----------
// ----------------------------------------
- (void)createAndUpdateDatabase:(nullable void(^)(BOOL result))reply;

- (void)recordSoftwareInstallAdd:(NSDictionary *_Nonnull)swTask withReply:(nullable void(^)(NSInteger result))reply;

- (void)recordSoftwareInstallRemove:(NSString *_Nonnull)swTaskName taskID:(NSString *_Nonnull)swTaskID withReply:(nullable void(^)(BOOL result))reply;

- (void)recordPatchInstall:(NSDictionary *_Nonnull)patch withReply:(nullable void(^)(NSInteger result))reply;

- (void)recordHistoryWithType:(DBHistoryType)hstType name:(NSString *_Nonnull)aName
						 uuid:(NSString *_Nonnull)aUUID
					   action:(DBHistoryAction)aAction
					   result:(NSInteger)code
					 errorMsg:(NSString * _Nullable)aErrMsg
					withReply:(nullable void(^)(BOOL result))reply;

- (void)retrieveInstalledSoftwareTasksWithReply:(nullable void(^)(NSData * _Nullable result))reply;

- (void)addRequiredPatch:(NSData *_Nonnull)patch withReply:(nullable void(^)(BOOL result))reply;
- (void)removeRequiredPatch:(NSString *_Nonnull)type patchID:(NSString *_Nonnull)patchID patch:(NSString *_Nonnull)patch withReply:(nullable void(^)(BOOL result))reply;

// ----------------------------------------
// OS Config Profiles	         ----------
// ----------------------------------------

- (void)scanForInstalledConfigProfiles:(nullable void(^)(NSArray * _Nullable profiles))reply;
- (void)getInstalledConfigProfilesWithReply:(nullable void(^)(NSString * _Nullable aString, NSData * _Nullable aProfilesData))reply;

// ----------------------------------------
// FileVault			         ----------
// ----------------------------------------
- (void)setAuthrestartDataForUser:(NSString * _Nullable )userName userPass:(NSString * _Nullable)userPass useRecoveryKey:(BOOL)useKey  withReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;

- (void)enableAuthRestartWithReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;
- (void)runAuthRestartWithReply:(nullable void(^)(NSError * _Nullable error, NSInteger result))reply;

- (void)getAuthRestartDataWithReply:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable result))reply;
- (void)clearAuthrestartData:(nullable void(^)(NSError * _Nullable error, BOOL result))reply;
- (void)fvAuthrestartAccountIsValid:(nullable void(^)(NSError * _Nullable error, BOOL result))reply;
- (void)getFileVaultUsers:(nullable void(^)(NSArray * _Nullable users))reply;

// ----------------------------------------
// Provisioning                  ----------
// ----------------------------------------
- (void)createDirectory:(NSString * _Nullable )path withReply:(nullable void(^)(NSError * _Nullable error))reply;
//- (void)postProvisioningData:(NSString * _Nullable )key dataForKey:(id _Nullable )data withReply:(nullable void(^)(NSError * _Nullable error))reply;
- (void)postProvisioningData:(NSString * _Nullable )key dataForKey:(NSData * _Nullable)data dataType:(NSString * _Nullable)dataType withReply:(nullable void(^)(NSError * _Nullable error))reply;
- (void)touchFile:(NSString * _Nullable )filePath withReply:(nullable void(^)(NSError * _Nullable error))reply;
- (void)rebootHost:(nullable void(^)(NSError * _Nullable error))reply;

@end

@protocol MPHelperProgress

- (void)patchProgress:(nullable NSString *)progressStr;
- (void)postStatus:(nullable NSString *)status type:(MPPostDataType)type;
- (void)postPatchInstallStatus:(nullable NSString *)patchID type:(MPPostDataType)type;

@end




