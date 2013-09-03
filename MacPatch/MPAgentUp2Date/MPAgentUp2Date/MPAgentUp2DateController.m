//
//  MPAgentUp2DateController.m
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

#import "MPAgentUp2DateController.h"
#import "MacPatch.h"

@interface MPAgentUp2DateController ()
- (NSDictionary *)collectVersionInfo;
- (BOOL)compareVersionStrings:(NSString *)leftVersion operator:(NSString *)aOp compareTo:(NSString *)rightVersion;
- (NSString *)downloadUpdate:(NSString *)aURL error:(NSError **)err;
- (NSString *)createTempDirFromURL:(NSString *)aURL;
- (void)unzip:(NSString *)aZipFilePath error:(NSError **)err;
- (void)unzip:(NSString *)aZipFilePath targetPath:(NSString *)aTargetPath error:(NSError **)err;
- (NSString *)runTask:(NSString *)aBinPath binArgs:(NSArray *)aArgs error:(NSError **)err;
- (NSString *)runTask:(NSString *)aBinPath binArgs:(NSArray *)aArgs environment:(NSDictionary *)aEnv error:(NSError **)err;
- (void)installPkg:(NSString *)pkgPath error:(NSError **)err;
- (void)installPkg:(NSString *)pkgPath target:(NSString *)aTarget error:(NSError **)err;
- (NSString *)installPkgWithResult:(NSString *)pkgPath target:(NSString *)aTarget error:(NSError **)err;
@end

@implementation MPAgentUp2DateController

@synthesize _cuuid;
@synthesize _appPid;
@synthesize _updateData;
@synthesize _osVerDictionary;

- (id)init
{
    self = [super init];
    if (self) {
        
        mpServerConnection = [[MPServerConnection alloc] init];
		[self set_cuuid:[MPSystemInfo clientUUID]];
		[self set_updateData:nil];
        [self set_osVerDictionary:[MPSystemInfo osVersionOctets]];
        mpAsus = [[MPAsus alloc] initWithServerConnection:mpServerConnection];
        mpDataMgr = [[MPDataMgr alloc] init];
    }
    return self;    
}

- (void)dealloc
{
    [mpServerConnection release];
    [super dealloc];
}

-(int)scanForUpdate
{
	// Get local application versions
	logit(lcl_vInfo,@"Collecting agent version information.");	
	NSDictionary *_agentInfo = [self collectVersionInfo];

    MPWebServices *mpws = [[[MPWebServices alloc] init] autorelease];
    NSError *wsErr = nil;
    NSDictionary *updateInfo = [mpws getAgentUpdates:[_agentInfo objectForKey:@"agentVersion"] build:[_agentInfo objectForKey:@"agentBuild"] error:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"%@, error code %d (%@)",[wsErr localizedDescription], (int)[wsErr code], [wsErr domain]);
        //	return 0;
    }
	logit(lcl_vDebug,@"WS Result: %@",updateInfo);

	logit(lcl_vInfo,@"Evaluate local versions for updates.");
	// See if the update is needed
	int needsUpdate = 0;
	if ([[updateInfo objectForKey:@"updateAvailable"] boolValue] == YES) {
        needsUpdate++;
	}
	
	if (needsUpdate >= 1) {
		logit(lcl_vInfo,@"Client agent needs updating, a newer version exists.");
	} else {
		logit(lcl_vInfo,@"Client agent is up to date.");
	}
	
	[self set_updateData:updateInfo];
	return needsUpdate;
}

-(void)scanAndUpdate
{
	int needsUpdate = 0; 
	if (_updateData == nil) {
		needsUpdate = [self scanForUpdate];
	}
	
	if (needsUpdate <= 0) {
		logit(lcl_vInfo,@"No update needed.");
		return;
	}

	logit(lcl_vInfo,@"Update needed.");
	NSError *err = nil;
	NSString *installResult;
	
	
	// Build the download String
	NSString *_dlURL = [NSString stringWithFormat:@"http://%@%@",mpServerConnection.HTTP_HOST,[[_updateData objectForKey:@"SelfUpdate"] objectForKey:@"pkg_Url"]];
	logit(lcl_vInfo,@"Download update package from: %@",_dlURL);
	
	// Download the File
	NSString *dlZipFile = [self downloadUpdate:_dlURL error:&err];
	logit(lcl_vDebug,@"dlZipFile Result:%@",dlZipFile);
	if (err) {
		logit(lcl_vError,@"Error downloading zip file, error code %d (%@)",(int)[err code], [err domain]);
		return;
	}
	
	logit(lcl_vInfo,@"Unzip package.");
	err = nil; //Reset the error
	[self unzip:dlZipFile error:&err];
	if (err) {
		logit(lcl_vError,@"Error unzip file, error code %d (%@)",(int)[err code], [err domain]);
		return;
	}
	logit(lcl_vInfo,@"Locate package(s) to install.");
	// Get the pkg to install
	NSString *pkgPath;
	NSString *pkgBaseDir = [dlZipFile stringByDeletingLastPathComponent];
	NSPredicate *pkgPredicate = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
	NSArray *pkgList = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[dlZipFile stringByDeletingLastPathComponent] error:NULL] filteredArrayUsingPredicate:pkgPredicate];
	
	// Install pkg(s)
	for (int i = 0; i < [pkgList count]; i++)
	{	
		pkgPath = [NSString stringWithFormat:@"%@/%@",pkgBaseDir,[pkgList objectAtIndex:i]];
		logit(lcl_vInfo,@"Start install of %@",pkgPath);
		err = nil;
		installResult = [self installPkgWithResult:pkgPath target:@"/" error:&err];
		if (err) {	
			logit(lcl_vError,@"Error installing package, error code %d (%@)",(int)[err code], [err domain]);
			break;
		}
		logit(lcl_vInfo,@"%@",installResult);
	}
	
}

#pragma mark -
#pragma mark Private

-(NSDictionary *)collectVersionInfo
{
	NSDictionary *_agentVersionInfo = [NSDictionary dictionaryWithContentsOfFile:AGENT_VER_PLIST];
	NSDictionary *_agentFrameWorkInfo = [NSDictionary dictionaryWithContentsOfFile:AGENT_FRAMEWORK_PATH];
	NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
	
	if ([_agentVersionInfo objectForKey:@"version"]) {
		[tmpDict setObject:[_agentVersionInfo objectForKey:@"version"] forKey:@"agentVersion"];
	} else {
		[tmpDict setObject:@"0" forKey:@"agentVersion"];
	}
	if ([_agentVersionInfo objectForKey:@"build"] ) {
		[tmpDict setObject:[_agentVersionInfo objectForKey:@"build"] forKey:@"agentBuild"];
	} else {
		[tmpDict setObject:@"0" forKey:@"agentBuild"];
	}
	if ([_agentFrameWorkInfo objectForKey:@"CFBundleShortVersionString"]) {
		[tmpDict setObject:[_agentFrameWorkInfo objectForKey:@"CFBundleShortVersionString"] forKey:@"agentFramework"];
	} else {
		[tmpDict setObject:@"0" forKey:@"agentFramework"];
	}
	
	NSDictionary *_appVersions = [NSDictionary dictionaryWithDictionary:tmpDict];
	[tmpDict release];
	
	return _appVersions; 
}

-(BOOL)compareVersionStrings:(NSString *)leftVersion operator:(NSString *)aOp compareTo:(NSString *)rightVersion
{
	BOOL fileVerPass = FALSE;
	int i;
	
	// Break version into fields (separated by '.')
	NSMutableArray *leftFields  = [[NSMutableArray alloc] initWithArray:[leftVersion  componentsSeparatedByString:@"."]];
	NSMutableArray *rightFields = [[NSMutableArray alloc] initWithArray:[rightVersion componentsSeparatedByString:@"."]];
	
	// Implict ".0" in case version doesn't have the same number of '.'
	if ([leftFields count] < [rightFields count]) {
		while ([leftFields count] != [rightFields count]) {
			[leftFields addObject:@"0"];
		}
	} else if ([leftFields count] > [rightFields count]) {
		while ([leftFields count] != [rightFields count]) {
			[rightFields addObject:@"0"];
		}
	}
	
	// Do a numeric comparison on each field
	NSComparisonResult result = NSOrderedSame;
	for(i = 0; i < [leftFields count]; i++) {
		result = [[leftFields objectAtIndex:i] compare:[rightFields objectAtIndex:i] options:NSNumericSearch];
		if (result != NSOrderedSame) {
			break;
		}
	}
	
	/*
	 * compareVersions(@"10.4",             @"10.3")             returns NSOrderedDescending (1)
	 * compareVersions(@"10.5",             @"10.5.0")           returns NSOrderedSame (0)
	 * compareVersions(@"10.4 Build 8L127", @"10.4 Build 8P135") returns NSOrderedAscending (-1)
	 */
	
	NSString *op = [aOp	uppercaseString];
	
	if ([op isEqualToString:@"EQ"] || [op isEqualToString:@"="] || [op isEqualToString:@"=="] ) 
	{
		if ( result == NSOrderedSame ) {
			fileVerPass = YES; goto done;
		} else {
			fileVerPass = NO; goto done;
		}
	}
	else if ([op isEqualToString:@"NEQ"] || [op isEqualToString:@"!="] || [op isEqualToString:@"=!"]) 
	{
		if ( result == NSOrderedSame ) {
			fileVerPass = NO; goto done;
		} else {
			fileVerPass = YES; goto done;
		}
		
	}
	else if ([op isEqualToString:@"LT"] || [op isEqualToString:@"<"]) 
	{
		if ( result == NSOrderedAscending ) {
			fileVerPass = YES; goto done;
		} else {
			fileVerPass = NO; goto done;
		}
	}
	else if ([op isEqualToString:@"LTE"] || [op isEqualToString:@"<="]) 
	{
		if ( result == NSOrderedAscending || result == NSOrderedSame ) {
			fileVerPass = YES; goto done;
		} else {
			fileVerPass = NO; goto done;
		}
	}
	else if ([op isEqualToString:@"GT"] || [op isEqualToString:@">"]) 
	{
		if ( result == NSOrderedDescending ) {
			fileVerPass = YES; goto done;
		} else {
			fileVerPass = NO; goto done;
		}
	}
	else if ([op isEqualToString:@"GTE"] || [op isEqualToString:@">="]) 
	{
		if ( result == NSOrderedDescending || result == NSOrderedSame ) {
			fileVerPass = YES; goto done;
		} else {
			fileVerPass = NO; goto done;
		}
	}
	
	
done:
	[leftFields release];
	[rightFields release];
	return fileVerPass;
}

-(NSString *)downloadUpdate:(NSString *)aURL error:(NSError **)err
{
	NSString *tempFilePath = [self createTempDirFromURL:aURL];

    NSURL *url = [NSURL URLWithString:[aURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDownloadDestinationPath:tempFilePath];
    [request setValidatesSecureCertificate:NO];
    [request startSynchronous];
    NSError *error = [request error];
    if (error) {
        logit(lcl_vError,@"Error[%d], trying to download file.",(int)[error code]);
        if (err != NULL)  *err = error;
    }
	
    return tempFilePath;
}

-(NSString *)createTempDirFromURL:(NSString *)aURL
{
	NSString *tempFilePath;
	
	NSString *appName = [[NSProcessInfo processInfo] processName];
	NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.XXXXXX",appName]];
	
	const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	char *tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
	strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
	char *result = mkdtemp(tempDirectoryNameCString);
	if (!result) {
		// handle directory creation failure
		logit(lcl_vError,@"Error, trying to create tmp directory.");
	}
	
	NSString *tempDirectoryPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(result)];
	free(tempDirectoryNameCString);
	
	tempFilePath = [tempDirectoryPath stringByAppendingPathComponent:[aURL lastPathComponent]];
	return tempFilePath;
}

-(void)unzip:(NSString *)aZipFilePath error:(NSError **)err
{
	NSError *aErr = nil;
	NSString *parentDir = [aZipFilePath stringByDeletingLastPathComponent];
	[self unzip:aZipFilePath targetPath:parentDir error:&aErr];
	if (err != NULL) *err = aErr;
}

-(void)unzip:(NSString *)aZipFilePath targetPath:(NSString *)aTargetPath error:(NSError **)err
{	
	NSError *aErr = nil;
	NSString *binFile = @"/usr/bin/ditto";
	NSArray *binArgs = [NSArray arrayWithObjects:@"-x", @"-k", aZipFilePath, aTargetPath, nil];
	NSString *result;
	result = [self runTask:binFile binArgs:binArgs error:&aErr];
	if (err != NULL) *err = aErr;	
}

-(NSString *)runTask:(NSString *)aBinPath binArgs:(NSArray *)aArgs error:(NSError **)err
{
	NSError *error = nil;
	NSString *result;
	result = [self runTask:aBinPath binArgs:aArgs environment:nil error:&error];
	if (error)
	{
		if (err != NULL) *err = error;
	}
	
    return [result trim];
}

#define aBUFSIZE 100

-(NSString *)runTask:(NSString *)aBinPath binArgs:(NSArray *)aArgs environment:(NSDictionary *)aEnv error:(NSError **)err
{
	if ([aBinPath isEqual:@"/usr/sbin/installer"]) {
		NSMutableString *_res = [[NSMutableString alloc] init];
		NSString *_cmd = [NSString stringWithFormat:@"export COMMAND_LINE_INSTALL=1; /usr/sbin/installer %@",[aArgs componentsJoinedByString:@" "]];
		
		int status;
		char buf[aBUFSIZE];
		
		FILE * f = popen([_cmd cStringUsingEncoding:NSUTF8StringEncoding], "r");
		size_t r;
		while((r = fread(buf, sizeof(char), aBUFSIZE - 1, f)) > 0) {
			buf[r+1] = '\0';
			[_res appendFormat:@"%@\n",[NSString stringWithUTF8String: buf]];
		}
		
		status = pclose(f);
		if (status == -1) {
			logit(lcl_vError,@"Error, closing file description for %@",_cmd);
		}
		
		NSString *result = [NSString stringWithString:_res];
		[_res release];
		return result;
		
	} else {

		NSPipe *cmdData = [NSPipe pipe];
		NSTask *cmd = [[NSTask alloc] init];
		[cmd setLaunchPath:aBinPath];
		[cmd setArguments: aArgs];
		if (aEnv) {
			[cmd setEnvironment:aEnv];	
		}
		[cmd setStandardOutput: cmdData];
		[cmd setStandardInput:[NSPipe pipe]];
		[cmd launch];
		[cmd waitUntilExit];
		
		if ([cmd terminationStatus] != 0) {
			logit(lcl_vError,@"Error, unable to run task.");
			if (err != NULL) *err = [NSError errorWithDomain:@"RunTask" code:[cmd terminationStatus] userInfo:nil];
		}
		[cmd release];
		
		NSData *data = [[cmdData fileHandleForReading] readDataToEndOfFile];
		NSString *l_string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		l_string = [NSString stringWithString:[l_string trim]];
		
		return l_string;
	}	
}

-(void)installPkg:(NSString *)pkgPath error:(NSError **)err
{
	NSError *aErr = nil;
	[self installPkg:pkgPath target:@"/" error:&aErr];
	if (err != NULL) *err = aErr;
}

-(void)installPkg:(NSString *)pkgPath target:(NSString *)aTarget error:(NSError **)err
{
	NSError *aErr = nil;
	NSString *result;
	result = [self installPkgWithResult:pkgPath target:aTarget error:&aErr];
	if (err != NULL) *err = aErr;
}

-(NSString *)installPkgWithResult:(NSString *)pkgPath target:(NSString *)aTarget error:(NSError **)err
{
	NSString *result;
#ifdef DEBUG	
	result = NULL;
#else	
	NSError *aErr = nil;
	NSArray *binArgs = [NSArray arrayWithObjects:@"-verboseR", @"-pkg", pkgPath, @"-target", aTarget, nil];
	NSDictionary *env = [NSDictionary dictionaryWithObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
	result = [self runTask:INSTALLER_BIN_PATH binArgs:binArgs environment:env error:&aErr];
	if (err != NULL) *err = aErr;
#endif
	
	return result;
}

@end
