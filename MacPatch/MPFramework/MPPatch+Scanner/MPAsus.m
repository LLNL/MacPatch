//
//  MPAsus.m
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

#import "MPAsus.h"
#import "MPNetworkUtils.h"
#import "MPPatchScan.h"
#import "Constants.h"
#import "MPNetConfig.h"
#import "MPNetRequest.h"

#undef  ql_component
#define ql_component lcl_cMPAsus

@implementation MPAsus

@synthesize catalogURLArray;
@synthesize defaults;
@synthesize patchGroup;
@synthesize allowClient;
@synthesize allowServer;

#pragma mark -
#pragma mark init

//=========================================================== 
//  init 
//=========================================================== 

- (id)init
{
    self = [super init];
	if (self)
    {
        mpNetworkUtils = [[MPNetworkUtils alloc] init];
        MPDefaults *mpDefaults = [[MPDefaults alloc] init];
        defaults = [mpDefaults defaults];

        [self setCatalogURLArray:[defaults objectForKey:@"CatalogURL"]];

        if ([defaults objectForKey:@"PatchGroup"]) {
			[self setPatchGroup:[defaults objectForKey:@"PatchGroup"]];
		} else {
			[self setPatchGroup:@"RecommendedPatches"];
		}

		if ([defaults objectForKey:@"AllowClient"]) {
			NSString *cVal = [defaults objectForKey:@"AllowServer"];
			if ([cVal isEqualToString:@"1"] || [cVal isEqualToString:@"Y"] || [cVal isEqualToString:@"Yes"] || [cVal isEqualToString:@"T"] || [cVal isEqualToString:@"True"]) {
				[self setAllowClient:YES];
			} else {
				[self setAllowClient:NO];
			}
		} else {
			[self setAllowClient:YES];
		}

		if ([defaults objectForKey:@"AllowServer"]) {
			NSString *sVal = [defaults objectForKey:@"AllowServer"];
			if ([sVal isEqualToString:@"1"] || [sVal isEqualToString:@"Y"] || [sVal isEqualToString:@"Yes"] || [sVal isEqualToString:@"T"] || [sVal isEqualToString:@"True"]) {
				[self setAllowServer:YES];
			} else {
				[self setAllowServer:NO];
			}
		} else {
			[self setAllowServer:NO];
		}
    }
    return self;
}

- (id)initWithServerConnection:(id)srvObj
{
    return [self init];
}

#pragma mark -
#pragma mark dealloc
//===========================================================
//  dealloc
//===========================================================

#pragma mark -
#pragma mark Class Methods
//=========================================================== 
//  methods
//=========================================================== 

- (BOOL)checkAndSetCatalogURL:(NSArray *)aCatalogArray
{
	BOOL returnVal = 0;
	
	NSString *currentCatalogURL = [self readCatalogURLFromPlist];
	NSString *newCatalogURL = NULL;
	if ([aCatalogArray count] > 0 ) {
		for(int i=0;i<[aCatalogArray count];i++) {
			// Check to make sure host is reachable and we get a vaild return code
			if ([mpNetworkUtils isHostURLReachable:[aCatalogArray objectAtIndex:i]]) {
				if ([mpNetworkUtils isURLValid:[aCatalogArray objectAtIndex:i] returnCode:200]) {
					newCatalogURL = [aCatalogArray objectAtIndex:i];
					break;
				} else {
					continue;
				}
			} else {
				continue;	
			}
		}
		
		if ([currentCatalogURL isEqualToString:newCatalogURL] == FALSE) {
			
			if ([self writeCatalogURL:newCatalogURL]) {
				returnVal = YES;
			}
			
		} else {
			returnVal = YES;
		}
	} else {
		// CatalogURL is not defined, use the default Apple Config
		returnVal = YES;
	}

	return returnVal;
}

- (NSString *)readCatalogURLFromPlist
{
	NSDictionary *tmpDict = [NSDictionary dictionaryWithContentsOfFile:ASUS_PLIST_PATH];
	NSString *result = [tmpDict valueForKey:@"CatalogURL"];
	return result;
}

-(BOOL)writeCatalogURL:(NSString *)CatalogURL
{
	BOOL returnVal = NO;
	NSMutableDictionary *tmpDefaults = [NSMutableDictionary dictionaryWithContentsOfFile:ASUS_PLIST_PATH];
	[tmpDefaults setObject:CatalogURL forKey:@"CatalogURL"];
	@try {
		[tmpDefaults writeToFile:ASUS_PLIST_PATH atomically:YES];
		returnVal = YES; 
	}
	@catch ( NSException *e ) {
		qlerror(@"Error unable to write new config.");
		returnVal = NO; 
	}
	
	return (returnVal);
}

- (void)writeLogoutHook
{
    // MP 2.2.0 & Mac OS X 10.9 Support, now using /private/tmp/.MPAuthRun
    NSString *_atFile = @"/private/tmp/.MPAuthRun";
    NSString *_rbFile = @"/private/tmp/.MPRebootRun.plist";
    NSString *_rbText = @"reboot";
    // Mac OS X 10.9 Support, now using /private/tmp/.MPAuthRun
    NSDictionary *rebootPlist = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"reboot"];
    [rebootPlist writeToFile:_rbFile atomically:YES];
    [_rbText writeToFile:_atFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    NSDictionary *_fileAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:0777],@"NSFilePosixPermissions",nil];
    [[NSFileManager defaultManager] setAttributes:_fileAttr ofItemAtPath:_rbFile error:NULL];
    [[NSFileManager defaultManager] setAttributes:_fileAttr ofItemAtPath:_atFile error:NULL];
}

- (NSData *)installResultsToXML:(NSArray *)aInstalledPatches
{
	/*
	 <?xml version="1.0" encoding="UTF-8"?>
	 <root>
	 <cuuid></cuuid>
	 <idate></idate>
	 <patch></patch>
	 <patch></patch>
	 </root>
	 */
	
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"root"];
	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
	
	[root addChild:[NSXMLNode elementWithName:@"cuuid" stringValue:[MPSystemInfo clientUUID]]];
	
	[root addChild:[NSXMLNode elementWithName:@"idate" stringValue:[MPDate dateTimeStamp]]];
	
	NSEnumerator *enumerator = [aInstalledPatches objectEnumerator];
	id anObject;
	while ((anObject = [enumerator nextObject])) {
		[root addChild:[NSXMLNode elementWithName:@"patch" stringValue:anObject]];
	}
	
	NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];

	return xmlData;
}

- (NSArray *)installResultsToDictArray:(NSArray *)aInstalledPatches type:(NSString *)aType
{
	NSArray *results = NULL;
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpDict;
	
	NSEnumerator *enumerator = [aInstalledPatches objectEnumerator];
	id anObject;
	while ((anObject = [enumerator nextObject])) {
		tmpDict = [[NSMutableDictionary alloc] init];
		[tmpDict setObject:anObject forKey:@"patch"];
		[tmpDict setObject:aType forKey:@"type"];
		[tmpArray addObject:tmpDict];
	}
	
	results = [NSArray arrayWithArray:tmpArray];
	
	return results;
}

#pragma mark softwareupdate methods

- (NSArray *)scanForCustomUpdates
{
	NSArray *result = nil;
	MPPatchScan *patchScanObj = [[MPPatchScan alloc] init];
	//[patchScanObj setUseDistributedNotification:YES];
	result = [NSArray arrayWithArray:[patchScanObj scanForPatches]];
	return result;
}

- (NSArray *)scanForCustomUpdateUsingBundleID:(NSString *)aBundleID
{
    NSArray *result = nil;
	MPPatchScan *patchScanObj = [[MPPatchScan alloc] init];
	//[patchScanObj setUseDistributedNotification:NO];
	result = [NSArray arrayWithArray:[patchScanObj scanForPatchesWithbundleID:aBundleID]];
	return result;
}

- (NSArray *)scanForAppleUpdates
{
	qlinfo(@"Scanning for Apple software updates.");
	
	NSArray *appleUpdates = nil;
	// Check & Set CatalogURL
	// Not to be handled here
	//if (![self checkAndSetCatalogURL:[self catalogURLArray]]) {
	//	logit(lcl_vError,@"Error: unable to verify and set CatalogURL.");
	//	return appleUpdates;
	//}
	
	NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: ASUS_BIN_PATH];
    [task setArguments: [NSArray arrayWithObjects: @"-l", nil]];
	
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
    [task launch];
	qlinfo(@"Starting Apple software update scan.");
	[task waitUntilExit];
	
	int status = [task terminationStatus];
	if (status != 0) {
		qlinfo(@"Error: softwareupdate exit code = %d",status);
		return appleUpdates;
	} else {
		qlinfo(@"Apple software update scan was completed.");
	}
    
	
	NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	qldebug(@"Apple software update full scan results\n%@",string);
	
	if (!([string rangeOfString:@"No new"].location == NSNotFound)) {
		qlinfo(@"No new updates.");
		return appleUpdates;
	}
	
	// We have updates so we need to parse the results
	NSArray *strArr = [NSArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
	
	NSMutableArray *tmpAppleUpdates = [[NSMutableArray alloc] init];
	NSString *tmpStr;
	NSMutableDictionary *tmpDict;
	
	for (int i=0; i<[strArr count]; i++) {
		// Ignore empty lines
		if ([[strArr objectAtIndex:i] length] != 0) {
			
			//Clear the tmpDict object before populating it
			if (!([[strArr objectAtIndex:i] rangeOfString:@"Software Update Tool"].location == NSNotFound)) {
				continue;
			}
			if (!([[strArr objectAtIndex:i] rangeOfString:@"Copyright"].location == NSNotFound)) {
				continue;
			}	
			
			// Strip the White Space and any New line data
			tmpStr = [[strArr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			// If the object/string starts with *,!,- then allow it 
			if ([[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"*"] || [[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"!"] || [[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"-"]) {
				tmpDict = [[NSMutableDictionary alloc] init];
				qlinfo(@"Apple Update: %@",[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))]);
				[tmpDict setObject:[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))] forKey:@"patch"];
				[tmpDict setObject:@"Apple" forKey:@"type"];
				[tmpDict setObject:[[[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))] componentsSeparatedByString:@"-"] lastObject] forKey:@"version"];
				[tmpDict setObject:[[strArr objectAtIndex:(i+1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"description"];
				[tmpDict setObject:[self getSizeFromDescription:[tmpDict objectForKey:@"description"]] forKey:@"size"];
				[tmpDict setObject:[self getRecommendedFromDescription:[tmpDict objectForKey:@"description"]] forKey:@"recommended"];
				if ([[[strArr objectAtIndex:(i+1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] containsString:@"[restart]" ignoringCase:YES] == TRUE) {
					[tmpDict setObject:@"Y" forKey:@"restart"];
				} else {
					[tmpDict setObject:@"N" forKey:@"restart"];
				}
				
				[tmpAppleUpdates addObject:tmpDict];
			} // if is an update
		} // if / empty lines
	} // for loop
	appleUpdates = [NSArray arrayWithArray:tmpAppleUpdates];
	
	qldebug(@"Apple Updates Found, %@",appleUpdates);
	return appleUpdates;
}

- (NSString *)getSizeFromDescription:(NSString *)aDesc
{
	NSArray *tmpArr1 = [aDesc componentsSeparatedByString:@","];
	NSArray *tmpArr2 = [[[tmpArr1 objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "];
	return [[tmpArr2 objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)getRecommendedFromDescription:(NSString *)aDesc
{
	NSRange textRange;
	textRange =[aDesc rangeOfString:@"recommended"];
	
	if(textRange.location != NSNotFound) {
		return @"Y";
	} else {
		return @"N";
	}
	
	return @"N";
}

- (void)scanAppleSoftwareUpdates:(NSArray *)approvedUpdates
{
	NSMutableArray *appArgs = [[NSMutableArray alloc] initWithArray:approvedUpdates];
	
	NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: ASUS_BIN_PATH];
    [task setArguments: appArgs];
	
    install_pipe = [NSPipe pipe];
    [task setStandardOutput: install_pipe];
    [task setStandardError: install_pipe];
	
    fh_installTask = [install_pipe fileHandleForReading];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(readInstallTaskData:)
												 name: NSFileHandleReadCompletionNotification
											   object: fh_installTask];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(installTaskEnded:)
												 name: NSTaskDidTerminateNotification
											   object: task];

	
	[task launch];
	[fh_installTask readInBackgroundAndNotify];
}

- (void)installAppleSoftwareUpdates:(NSArray *)approvedUpdates
{
	NSMutableArray *appArgs = [[NSMutableArray alloc] initWithArray:approvedUpdates];
	[appArgs insertObject:@"-i" atIndex:0];
	
	NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: ASUS_BIN_PATH];
    [task setArguments: appArgs];
	[task setEnvironment:[NSDictionary dictionaryWithObject:@"1" forKey:@"COMMAND_LINE_INSTALL"]];
	
    install_pipe = [NSPipe pipe];
    [task setStandardOutput: install_pipe];
    [task setStandardError: install_pipe];
	
    fh_installTask = [install_pipe fileHandleForReading];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(installTaskEnded:)
												 name: NSTaskDidTerminateNotification
											   object: nil];
	
	// NSFileHandleReadToEndOfFileCompletionNotification
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(readInstallTaskData:)
												 name: NSFileHandleDataAvailableNotification
											   object: fh_installTask];
	
	[task launch];
	[fh_installTask readInBackgroundAndNotify];
}


- (BOOL)installAppleSoftwareUpdates:(NSArray *)approvedUpdates isSelfCheck:(BOOL)aSelfCheck
{
	BOOL result = YES;
	
	NSMutableArray *appArgs = [[NSMutableArray alloc] initWithArray:approvedUpdates];
	[appArgs insertObject:@"-i" atIndex:0];
	
	NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: ASUS_BIN_PATH];
    [task setArguments: appArgs];
	[task setEnvironment:[NSDictionary dictionaryWithObject:@"1" forKey:@"COMMAND_LINE_INSTALL"]];
	
    install_pipe = [NSPipe pipe];
    [task setStandardOutput: install_pipe];
    [task setStandardError: install_pipe];
	
    fh_installTask = [install_pipe fileHandleForReading];
	
	if (aSelfCheck == YES) {
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(installTaskEnded:)
													 name: NSTaskDidTerminateNotification
												   object: fh_installTask];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(readInstallTaskData:)
													 name: NSFileHandleDataAvailableNotification
												   object: fh_installTask];
		
		
		[fh_installTask readInBackgroundAndNotify];
		[task launch];
		
	} else {
		[task launch];
		[task waitUntilExit];
		
		int status = [task terminationStatus];
		if (status != 0) {
			qlerror(@"Error: softwareupdate exit code = %d",status);
			result = NO;
			goto done;
		}
	}
	
done:
	
	;
	
	return result;
}

#pragma mark Custom Patch install

-(NSString *)downloadUpdate:(NSString *)aURL error:(NSError **)err
{
    MPNetConfig *mpConfig = [[MPNetConfig alloc] init];
    NSError *error = nil;
    NSURLResponse *response;
    MPNetRequest *req = [[MPNetRequest alloc] initWithMPServerArray:[mpConfig servers]];
    NSURLRequest *urlReq = [req buildDownloadRequest:aURL];
    NSString *dlFileLoc = [req downloadFileRequest:urlReq returningResponse:&response error:&error];
    if (error) {
        qlerror(@"%@",error.localizedDescription);
        if (err != NULL) *err = error;
        return @"";
    }
    return dlFileLoc;
}

- (int)installPkg:(NSString *)pkgPath error:(NSError **)err
{
	NSError *aErr = nil;
	[self installPkg:pkgPath target:@"/" error:&aErr];
	if (err != NULL) *err = aErr;
    return 0;
}

- (int)installPkg:(NSString *)pkgPath target:(NSString *)aTarget error:(NSError **)err
{
	NSError *aErr = nil;
	NSString *result;
	result = [self installPkgWithResult:pkgPath target:aTarget error:&aErr];
    qltrace(@"%@",result);
	if (err != NULL) *err = aErr;
    return 0;
}

-(NSString *)installPkgWithResult:(NSString *)pkgPath target:(NSString *)aTarget error:(NSError **)err
{
	NSString *result;
#ifdef DEBUG	
	result = NULL;
#else	
	NSError *aErr = nil;
	NSString *binFile = @"/usr/sbin/installer";
	NSArray *binArgs = [NSArray arrayWithObjects:@"-verboseR", @"-pkg", pkgPath, @"-target", aTarget, nil];
	NSDictionary *env = [NSDictionary dictionaryWithObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
	result = [self runTask:binFile binArgs:binArgs environment:env error:&aErr];
	if (err != NULL) *err = aErr;
#endif
	
	return result;
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

-(NSString *)runTask:(NSString *)aBinPath binArgs:(NSArray *)aArgs environment:(NSDictionary *)aEnv error:(NSError **)err
{
	NSTask *cmd = [[NSTask alloc] init];
    [cmd setLaunchPath:aBinPath];
    [cmd setArguments: aArgs];
	if (aEnv) {
		[cmd setEnvironment:aEnv];	
	}
	
    NSPipe *pipe = [NSPipe pipe];
    [cmd setStandardOutput: pipe];
	[cmd setStandardError: pipe];
	
    NSFileHandle *file = [pipe fileHandleForReading];
	
    [cmd launch];
    [cmd waitUntilExit];
	
	if ([cmd terminationStatus] != 0)
	{
		qlerror(@"Error, unable to run task.");
		if (err != NULL) *err = [NSError errorWithDomain:@"RunTask" code:[cmd terminationStatus] userInfo:nil];
	}
	
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
    return [string trim];
}

#pragma mark -
#pragma mark Helper Methods
//=========================================================== 
//  Helper Methods
//=========================================================== 

-(NSString *)createTempDirFromURL:(NSString *)aURL
{
	NSString *tempFilePath;
	NSString *appName = [[NSProcessInfo processInfo] processName];
	NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.XXXXXX",appName]];
	
	const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	char *tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
	strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
	char *result = mkdtemp(tempDirectoryNameCString);
	if (!result)
	{
        free(tempDirectoryNameCString);
		// handle directory creation failure
		qlerror(@"Error, trying to create tmp directory.");
        return [@"/private/tmp" stringByAppendingPathComponent:appName];
	}
	
	NSString *tempDirectoryPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(result)];
	free(tempDirectoryNameCString);
	
	//NSURL *tmpURL = [NSURL URLWithString:aURL];
	tempFilePath = [tempDirectoryPath stringByAppendingPathComponent:[aURL lastPathComponent]];
	
	return tempFilePath;
}

-(int)unzip:(NSString *)aZipFilePath error:(NSError **)err
{
	NSError *aErr = nil;
	NSString *parentDir = [aZipFilePath stringByDeletingLastPathComponent];
	[self unzip:aZipFilePath targetPath:parentDir error:&aErr];
	if (err != NULL) *err = aErr;
    return 0;
}

-(int)unzip:(NSString *)aZipFilePath targetPath:(NSString *)aTargetPath error:(NSError **)err
{	
	NSError *aErr = nil;
	NSString *binFile = @"/usr/bin/ditto";
	NSArray *binArgs = [NSArray arrayWithObjects:@"-x", @"-k", aZipFilePath, aTargetPath, nil];
	NSString *result;
	result = [self runTask:binFile binArgs:binArgs error:&aErr];
    qltrace(@"%@",result);
	if (err != NULL) *err = aErr;	
    return 0;
}

#pragma mark Notifications

- (void)readInstallTaskData:(NSNotification *)aNotification
{
	// I dont really need this yet...
	NSData *data = [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem];
	NSString *string = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]];
	qldebug(@"%@",string);
	
	NSDictionary *myData = [NSDictionary dictionaryWithObject:string forKey:@"iData"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ASUSInstallStatus" object:self userInfo:myData];
	
	[[aNotification object] readInBackgroundAndNotify];
}

- (void)installTaskEnded:(NSNotification *)aNotification
{
	NSData *data = [fh_installTask readDataToEndOfFile];
    NSString *resultsString = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	qlinfo(@"Task completed[results]:\n%@",resultsString);
	
	NSDictionary *myData = [NSDictionary dictionaryWithObject:@"Done" forKey:@"iData"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ASUSInstallComplete" object:nil userInfo:myData];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[fh_installTask closeFile];
}	

@end
