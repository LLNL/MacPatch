//
//  MPAntiVirus.m
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

#import "MPAntiVirus.h"
#import "MacPatch.h"

@implementation MPAntiVirus

@synthesize avType;
@synthesize avApp;
@synthesize avAppInfo;
@synthesize avDefsDate;
@synthesize l_Defaults;

-(id)init
{
    MPServerConnection *_srvObj = [[[MPServerConnection alloc] init] autorelease];
	return [self initWithServerConnection:_srvObj];
}

- (id)initWithServerConnection:(MPServerConnection *)aSrvObj
{
    self = [super init];
	if (self) {
		avApp = nil;
        mpServerConnection = aSrvObj;
		[self setL_Defaults:mpServerConnection.mpDefaults];
		soapService = [[SoapServices alloc] initWithServerConnection:mpServerConnection];
	}
	return self;
}

-(void)dealloc
{
	[avType autorelease];
    [avApp autorelease];
    [avAppInfo autorelease];
    [avDefsDate autorelease];
    [l_Defaults autorelease];
	[soapService release];
	[super dealloc];
}

-(void)scanDefs
{
	// Look for a Supported AV App, if not bail.
	NSDictionary *_avAppInfo = [self getAvAppInfo];
	if (_avAppInfo == nil) {
		logit(lcl_vInfo,@"No AV software was found, nothing to post.");
		return;
	}
	
	NSMutableDictionary *_avInfoToPost = [[NSMutableDictionary alloc] initWithDictionary:_avAppInfo];
	
	// Check for Valid Defs data, else post data, can not update
	NSString *_localDefsDate = [self getLocalDefsDate];
	if (_localDefsDate == nil) {
		logit(lcl_vError,@"No AV Defs software was found, nothing to validate.");
		[_avInfoToPost setValue:@"NA" forKey:@"DefsDate"];
		// Post AV to WebService
		[soapService postBasicSOAPMessageUsingConvertDictionaryToXML:@"AddClientSAVData"
															 argName:@"theXmlFile"
														   dictToXml:_avInfoToPost
														   b64Encode:YES];
		[_avInfoToPost release];
		return;
	}
	logit(lcl_vInfo, @"Host AV defs date is %@",_localDefsDate);
	
	// Get Latest Defs Date from Server
	NSString *_remoteAvDefsDate = [self getLatestAVDefsDate];
	if (_remoteAvDefsDate == nil) {
		[_avInfoToPost release];
		return;
	}
	logit(lcl_vInfo, @"Latest AV defs date is %@",_remoteAvDefsDate);
	
	// If Updates are enabled
	if (([_remoteAvDefsDate intValue] > [_localDefsDate intValue]) && [_localDefsDate intValue] != -1) {
		logit(lcl_vInfo,@"AV Defs are out of date.")
	} else {
		logit(lcl_vDebug, @"AV Defs are current.");
	}
	
	// Post AV to WebService
	[_avInfoToPost setValue:_localDefsDate forKey:@"DefsDate"];
	[soapService postBasicSOAPMessageUsingConvertDictionaryToXML:@"AddClientSAVData"
														 argName:@"theXmlFile"
													   dictToXml:_avInfoToPost
													   b64Encode:YES];
	[_avInfoToPost release];
	return;
}

-(void)scanAndUpdateDefs
{
	// Look for a Supported AV App, if not bail.
	NSDictionary *_avAppInfo = [self getAvAppInfo];
	if (_avAppInfo == nil) {
		logit(lcl_vInfo,@"No AV software was found, nothing to post.");
        
        [soapService postBasicSOAPMessageUsingConvertDictionaryToXML:@"AddClientSAVData"
															 argName:@"theXmlFile"
														   dictToXml:_avAppInfo
														   b64Encode:YES];
        
		return;
	}
	
	NSMutableDictionary *_avInfoToPost = [[NSMutableDictionary alloc] initWithDictionary:_avAppInfo];
	
	// Check for Valid Defs data, else post data, can not update
	NSString *_localDefsDate = [self getLocalDefsDate];
	if (_localDefsDate == nil) {
		logit(lcl_vError,@"No AV Defs software was found, nothing to validate.");
		[_avInfoToPost setValue:@"NA" forKey:@"DefsDate"];
		// Post AV to WebService
		[soapService postBasicSOAPMessageUsingConvertDictionaryToXML:@"AddClientSAVData"
															 argName:@"theXmlFile"
														   dictToXml:_avInfoToPost
														   b64Encode:YES];
		[_avInfoToPost release];
		return;
	}
	logit(lcl_vInfo, @"Host AV defs date: %@",_localDefsDate);
	
	// Get Latest Defs Date from Server
	NSString *_remoteAvDefsDate = [self getLatestAVDefsDate];
	if (_remoteAvDefsDate == nil) {
		[_avInfoToPost release];
		return;
	}
	logit(lcl_vInfo, @"Latest AV defs date: %@",_remoteAvDefsDate);

	// If Updates are enabled
	if (([_remoteAvDefsDate intValue] > [_localDefsDate intValue]) && [_localDefsDate intValue] != -1) {
		logit(lcl_vInfo,@"Run the AV Defs update, defs are out of date.")
		// Install the Software
		NSString *_avDefsURL = [self getAvUpdateURL];
		logit(lcl_vDebug,@"AV Defs URL: %@",_avDefsURL);
		if (_avDefsURL) {
			int installResult = -1;
			installResult = [self downloadUnzipAndInstall:_avDefsURL];
			if (installResult != 0) {
				logit(lcl_vError,@"AV Defs were not updated. Please see the install.log file for reason.");
			} else {
				logit(lcl_vError,@"AV Defs were updated.");
			}
		}
	} else {
		logit(lcl_vDebug, @"AV Defs are current.");
	}
	
	// Get Defs Info
	_localDefsDate = [self getLocalDefsDate];
	[_avInfoToPost setValue:_localDefsDate forKey:@"DefsDate"];
	
	// Post AV to WebService
	[soapService postBasicSOAPMessageUsingConvertDictionaryToXML:@"AddClientSAVData"
														 argName:@"theXmlFile"
													   dictToXml:_avInfoToPost
													   b64Encode:YES];
	[_avInfoToPost release];
	return;
}

-(NSDictionary *)getAvAppInfo
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *avAppArray = [NSArray arrayWithObjects:
						   @"/Applications/Symantec Solutions/Symantec AntiVirus.app",
						   @"/Applications/Symantec Solutions/Norton AntiVirus.app",
						   @"/Applications/Norton Solutions/Symantec AntiVirus.app",
						   @"/Applications/Norton Solutions/Norton AntiVirus.app", 
						   @"/Applications/Symantec Solutions/Symantec Endpoint Protection.app",
						   @"/Applications/Sophos Anti-Virus.app",
						   nil];	
	// Find the 
	for (NSString *item in avAppArray) {
		if ([fm fileExistsAtPath:item]) {
			avApp = [NSString stringWithString:item];
			break;
		}
	}
	
	if (avApp == nil) {
		logit(lcl_vError,@"Unable to find a AV product.");
	}
	NSDictionary *_avAppInfo = [NSDictionary dictionaryWithContentsOfFile:[avApp stringByAppendingPathComponent:@"Contents/Info.plist"]];
	NSMutableDictionary *_tmpAvDict = [[NSMutableDictionary alloc] init];
	[_tmpAvDict setValue:[MPSystemInfo clientUUID] forKey:@"cuuid"];
    if (avApp) {
        [_tmpAvDict setValue:[_avAppInfo valueForKey:@"CFBundleExecutable"] forKey:@"CFBundleExecutable"];
        [_tmpAvDict setValue:avApp forKey:@"NSBundleResolvedPath"];
        [_tmpAvDict setValue:[_avAppInfo valueForKey:@"CFBundleVersion"] forKey:@"CFBundleVersion"];
        [_tmpAvDict setValue:[_avAppInfo valueForKey:@"CFBundleShortVersionString"] forKey:@"CFBundleShortVersionString"];
    }
	[self setAvAppInfo:_tmpAvDict];
	
	return [_tmpAvDict autorelease];
}

-(NSString *)getLocalDefsDate
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *_avDefsPath = nil;
	NSArray *avDefsArray = [NSArray arrayWithObjects:
						   @"/Library/Application Support/Symantec/AntiVirus/Engine/V.GRD",
						   @"/Library/Application Support/Norton Solutions Support/Norton AntiVirus/Engine/v.grd",
						   @"/Library/Application Support/Norton Solutions Support/Norton AntiVirus/Engine/V.GRD",
						   nil];
	// Find the 
	for (NSString *item in avDefsArray) {
		if ([fm fileExistsAtPath:item]) {
			logit(lcl_vDebug,@"Reading defs file, %@",item);
			_avDefsPath = [NSString stringWithString:item];
			break;
		}
	}
	
	if (_avDefsPath == nil) {
		logit(lcl_vError,@"Unable to find a AV Defs.");
		return nil;
	}
	// Read Defs file
	NSError *err = nil;
	NSString *_avDefsFileData = [NSString stringWithContentsOfFile:_avDefsPath encoding:NSUTF8StringEncoding error:&err];
	if (err) {
		logit(lcl_vError,@"Unable to read AV Defs file\n%@.",[err localizedDescription]);
		return nil;
	}
	logit(lcl_vDebug,@"avDefsFile Data: %@",_avDefsFileData);
	
	// Parse Defs File
	NSString *_defsDate = nil;
	NSArray *_lines = [_avDefsFileData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for (NSString *_line in _lines) {
		//LastModifiedGmtFormated
		if ([_line containsString:@"LastModifiedGmtFormated" ignoringCase:YES]) {
			logit(lcl_vDebug,@"containsString: %@",_line);
			_defsDate = [[[[_line componentsSeparatedByString:@"="] objectAtIndex:1] componentsSeparatedByString:@" "] objectAtIndex:0];
			logit(lcl_vDebug,@"_defsDate: %@",_defsDate);
			break;
		}
	}
	[self setAvDefsDate:[NSString stringWithString:_defsDate]];
	return _defsDate;
}

-(NSString *)getLatestAVDefsDate
{
	NSString *result;
	NSString *_theArch = @"x86"; 
	if ([[MPSystemInfo hostArchitectureType] isEqualToString:@"ppc"]) {
		_theArch = @"ppc";
	}
	NSDictionary *soapArgs = [NSDictionary dictionaryWithObject:_theArch forKey:@"theArch"];
	result = [soapService postBasicSOAPMessage:@"GetSavAvDefsDate" argDictionary:soapArgs];
	if ([result isEqualToString:@"NA"]) {
		logit(lcl_vError,@"Did not recieve a vaild defs date.");
		return nil;
	}
	return result;
}

// Download & Update
-(NSString *)getAvUpdateURL
{
	NSString *result;
	NSString *_theArch = @"x86"; 
	if ([[MPSystemInfo hostArchitectureType] isEqualToString:@"ppc"]) {
		_theArch = @"ppc";
	}
	NSDictionary *soapArgs = [NSDictionary dictionaryWithObject:_theArch forKey:@"theArch"];
	result = [soapService postBasicSOAPMessage:@"GetSavAvDefsFile" argDictionary:soapArgs];
	if ([result isEqualToString:@"NA"]) {
		logit(lcl_vError,@"Did not recieve a vaild defs file.");
		return nil;
	}
	
	logit(lcl_vDebug,@"[getAvUpdateURL] result: %@",result);
	return result;
}

-(int)downloadUnzipAndInstall:(NSString *)pkgURL
{
	// First we need to download the update
	int result = 0;
	MPDefaults *mpDefaults = [[MPDefaults alloc] init];
	MPAsus *mpAsus = [[MPAsus alloc] init];
	NSError *err = nil;
	NSString *dlPatchLoc;
	if ([pkgURL hasPrefix:@"http"] || [pkgURL hasPrefix:@"https"]) {
		dlPatchLoc = [mpAsus downloadUpdate:pkgURL error:&err];
	} else {
		dlPatchLoc = [mpAsus downloadUpdate:[NSString stringWithFormat:@"http://%@%@",mpServerConnection.HTTP_HOST,pkgURL] error:&err];
	}

	if (err) {
		logit(lcl_vError,@"Error downloading a patch, skipping %@. Err Message: %@",pkgURL, [err localizedDescription]);
		result = 1;
	}

	// Now we need to unzip
	if (result == 0) {
		logit(lcl_vInfo,@"Uncompressing patch, to begin install.");
		logit(lcl_vInfo,@"Begin decompression of file, %@",dlPatchLoc);
		err = nil;
		[mpAsus unzip:dlPatchLoc error:&err];
		if (err) {
			logit(lcl_vError,@"Error decompressing a patch, skipping %@. Err Message:%@",dlPatchLoc,[err localizedDescription]);
			result = 1;
		}
		logit(lcl_vInfo,@"File has been decompressed.");
	}
	// *****************************
	// Install the update
	if (result == 0) {
		NSString *pkgPath;
		NSString *pkgBaseDir = [dlPatchLoc stringByDeletingLastPathComponent];						
		NSPredicate *pkgPredicate = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
		NSArray *pkgList = [[[NSFileManager defaultManager] directoryContentsAtPath:[dlPatchLoc stringByDeletingLastPathComponent]] filteredArrayUsingPredicate:pkgPredicate];
		int installResult = -1;
		MPInstaller *mpi = [[MPInstaller alloc] init];
		// Install pkg(s)
		for (id _pkg in pkgList) {
			pkgPath = [pkgBaseDir stringByAppendingPathComponent:_pkg];
			logit(lcl_vInfo,@"Start install of %@",pkgPath);
			installResult = [mpi installPkg:pkgPath target:@"/" env:nil];
			if (installResult != 0) {
				logit(lcl_vError,@"Error installing package, error code %d.",installResult);
				result = 1;
			}
		}
		[mpi release];
	}
	
	[mpDefaults release];
	[mpAsus release];
	return result;
}

@end
