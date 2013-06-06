//
//  MPFileCheck.m
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

#import "MPFileCheck.h"
#import "MPCrypto.h"
#import "RegexKitLite.h"

#undef  ql_component
#define ql_component lcl_cMPFileCheck

@implementation MPFileCheck

#pragma mark -
#pragma mark init
//=========================================================== 
//  init 
//=========================================================== 

-(id)initWithFilePath:(NSString *)aPath
{
	self = [super init];
	
    if ( self ) {
        [self setFilePath:aPath];
    }
	
    return self;
}

#pragma mark -
#pragma mark Getters & Setters
//=========================================================== 
//  Getters & Setters 
//=========================================================== 
- (NSString *)filePath
{
	return filePath;
}
- (void)setFilePath:(NSString *)aFilePath
{
	if (filePath != aFilePath) {
        [filePath release];
        filePath = [aFilePath copy];
    }
}

#pragma mark -
#pragma mark Class Methods
//=========================================================== 
//  Class Methods
//=========================================================== 

-(BOOL)queryFile:(NSString *)aPath action:(NSString *)aAction param:(NSString *)aParam
{
	BOOL result = NO;
	[self setFilePath:aPath];
	
	result = [self queryFile:aAction param:aParam];
	
	return result;
}

-(BOOL)queryFile:(NSString *)action param:(NSString *)aParam
{
	BOOL result = FALSE;
	NSString *theAction = [action uppercaseString];
	
	if ([theAction isEqualToString:@"EXISTS"])
	{
		result = [self fExists:[self filePath] param:aParam]; 
		goto done;
	}
	
	if ([theAction isEqualToString:@"DATE"])
	{
		NSArray *theParams;
		theParams = [aParam componentsSeparatedByString:@";"];
		if ([theParams count] != 2)
		{
			result = FALSE; goto done;	
		}
		
		NSString *vOppr = [theParams objectAtIndex:0];
		NSString *vDate = [theParams objectAtIndex:1];
		result = [self compareFileDate:[self filePath] date:vDate operator:vOppr];
		goto done;
	}
	else if ([theAction isEqualToString:@"HASH"])
	{
		result = [self checkFileHash:[self filePath] fileHash:aParam];
		goto done;
	}
	else if ([theAction isEqualToString:@"VERSION"])
	{
		NSArray *theParams;
		theParams = [aParam componentsSeparatedByString:@";"];
		if ([theParams count] != 2)
		{
			result = FALSE; goto done;	
		}
		
		NSString *vVers = [theParams objectAtIndex:0];
		NSString *vOppr = [theParams objectAtIndex:1];
		
		result = [self checkFileVersion:[self filePath] patchFileVer:vVers operator:vOppr];
		goto done;
	}
	else 
	{
		qlerror(@"Error: unable to process action type.");
		result = FALSE;
		goto done;
	}

		
done:
	return result;
}

#pragma mark -
#pragma mark Helper Methods
//=========================================================== 
//  Helper Methods
//=========================================================== 

-(BOOL)fExists:(NSString *)aFile
{
	return [self fExists:aFile param:@"TRUE"];
}

-(BOOL)fExists:(NSString *)aFile param:(NSString *)aParam
{
	BOOL result = FALSE;
	BOOL param = TRUE;
	NSString *pu = [aParam uppercaseString];
	
	if ([pu isEqualToString:@"Y"] || [pu isEqualToString:@"YES"] || [pu isEqualToString:@"T"] || [pu isEqualToString:@"TRUE"] )
	{	
		param = TRUE;
	}
	if ([pu isEqualToString:@"N"] || [pu isEqualToString:@"NO"] || [pu isEqualToString:@"F"] || [pu isEqualToString:@"FALSE"] )
	{	
		param = FALSE;
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:aFile] == param)
	{
		result = TRUE; 
		goto done;
	}
	
done:
	return result;	
}

-(BOOL)compareFileDate:(NSString *)aFile date:(NSString *)aDate operator:(NSString *)aOper
{
	// First Get the File Mod Date
	NSFileManager	*fm = [NSFileManager defaultManager];
	NSDictionary	*fa = [fm fileAttributesAtPath:aFile traverseLink:YES];
	
	NSDate *fileDate = [fa objectForKey:@"NSFileModificationDate"];
	NSDate *compareDate = [self dateWithSQLString:aDate];
	
	NSString *aOperUP	= [aOper uppercaseString];
	
	if ([aOperUP isEqualToString:@"EQ"] || [aOperUP isEqualToString:@"=="])
	{	
		return [fileDate isEqualToDate:compareDate];
	}
	else if ([aOperUP isEqualToString:@"LT"] || [aOperUP isEqualToString:@"<"])
	{	
		return [fileDate isLessThan:compareDate];
	}
	else if ([aOperUP isEqualToString:@"LTE"] || [aOperUP isEqualToString:@"<="])
	{	
		return [fileDate isLessThanOrEqualTo:compareDate];
	}
	else if ([aOperUP isEqualToString:@"GT"] || [aOperUP isEqualToString:@">"])
	{	
		return [fileDate isGreaterThan:compareDate];
	}
	else if ([aOperUP isEqualToString:@"GTE"] || [aOperUP isEqualToString:@">="])
	{	
		return [fileDate isGreaterThan:compareDate];
	}
	else 
	{
		qlerror(@"Error operator not understood.");
		return FALSE;
	}
}

-(NSDate *)dateWithSQLString:(NSString *)dateAndTime
{
	NSDate *date = [NSDate dateWithNaturalLanguageString:dateAndTime];
	if (!date) return nil;
	
	NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDateComponents *dateComps = [calendar components:(
														NSYearCalendarUnit |
														NSMonthCalendarUnit |
														NSDayCalendarUnit |
														NSHourCalendarUnit |
														NSMinuteCalendarUnit |
														NSSecondCalendarUnit) 
											  fromDate:date];
	[calendar setTimeZone:[NSTimeZone defaultTimeZone]];
	date = [calendar dateFromComponents:dateComps];
	return date;
}

#pragma mark -
-(BOOL)checkFileVersion:(NSString *)localFilePath patchFileVer:(NSString *)aPatchFileVer operator:(NSString *)aOp
{
	BOOL fileVerPass = FALSE;
	NSDictionary *localFileDict;
	NSString *l_localFilePath;
	
	// Need to stop using NSBundle content is cached and reports false postitives
	// .framework use a slightly different path, it's "...Resources/Info.plist"
	// .app, .menu, .plugin, .bundle, .kext, .prefPane, .qlerror(nPlugin uses "...Contents/Info.plist"
	if ([[localFilePath lastPathComponent] containsString:@"framework"]) {
		l_localFilePath = [NSString pathWithComponents:[NSArray arrayWithObjects:localFilePath,@"Resources",@"Info.plist",nil]];
	} else {
		l_localFilePath = [NSString pathWithComponents:[NSArray arrayWithObjects:localFilePath,@"Contents",@"Info.plist",nil]];
	}
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:l_localFilePath]) {
		localFileDict = [NSDictionary dictionaryWithContentsOfFile:l_localFilePath];
	} else {
		qlinfo(@"Unable to get version from file %@. Please check supported file types.",localFilePath);
		goto done;
	}
	
	NSString *localFileVer = NULL;
	if (![localFileDict objectForKey:@"CFBundleShortVersionString"]) {
		qlerror(@"CFBundleShortVersionString was not found.");
		fileVerPass = NO;
		goto done;
	}
	
	localFileVer = [NSString stringWithString:[localFileDict objectForKey:@"CFBundleShortVersionString"]];
	qldebug(@"Found file version: =%@",localFileVer);
	
	NSString *regexString	= @"^(\\d+)(.\\d+)?(.\\d+)?(.\\d+)?(.\\d+)?(.\\d+)?$";
	NSString *matchedString = [localFileVer stringByMatching:regexString];
	if ([matchedString isEqualToString:localFileVer] == NO) {
		qlerror(@"CFBundleShortVersionString (%@) is not valid version string format.",localFileVer);
		fileVerPass = NO;
		goto done;
	}
	
	fileVerPass = [self compareVersion:localFileVer operator:aOp compareTo:aPatchFileVer];
	goto done;
	
done:	
	return fileVerPass;
}

-(BOOL)compareVersion:(NSString *)leftVersion operator:(NSString *)aOp compareTo:(NSString *)rightVersion
{
	
	qldebug(@"Comparing version strings: %@ %@ %@",leftVersion,aOp,rightVersion);
	
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
	
	NSString *op = [NSString stringWithString:[aOp	uppercaseString]];
	
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
	qldebug(@"Comparing version strings result: %@",(fileVerPass ? @"YES" : @"NO"));
	[leftFields release];
	[rightFields release];
	return fileVerPass;
}

-(NSDictionary *)getSWVers
{
	NSDictionary *results = NULL;
	NSString *clientVerPath = @"/System/Library/CoreServices/SystemVersion.plist";
	NSString *serverVerPath = @"/System/Library/CoreServices/ServerVersion.plist";
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:serverVerPath] == TRUE) {
		results = [NSDictionary dictionaryWithContentsOfFile:serverVerPath];
	} else {
		if ([[NSFileManager defaultManager] fileExistsAtPath:clientVerPath] == TRUE) {
			results = [NSDictionary dictionaryWithContentsOfFile:clientVerPath];
		}
	}
	
	return results;
}

-(BOOL)checkFileHash:(NSString *)localFilePath fileHash:(NSString *)hash
{
	return [self checkFileHash:localFilePath fileHash:hash hashType:@"MD5"];
}

-(BOOL)checkFileHash:(NSString *)localFilePath fileHash:(NSString *)hash hashType:(NSString *)type
{
	BOOL hashResult = FALSE;
	
	MPCrypto *crypto;

	if (![[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
		qlerror(@"Unable to get hash for file %@. File is missing.",localFilePath);	
		return FALSE;
	}

	crypto = [[MPCrypto alloc] init];
	
	if ([type isEqualToString:@"MD5"]) {
		if ([[[crypto md5HashForFile:localFilePath] uppercaseString] isEqualToString:[hash uppercaseString]])
		{
			hashResult = TRUE;
		}
	} 
	else if ([type isEqualToString:@"SHA1"])
	{
		if ([[[crypto sha1HashForFile:localFilePath] uppercaseString] isEqualToString:[hash uppercaseString]])
		{
			hashResult = TRUE;
		}
	}
	
    [crypto release];
	
	return hashResult;
}

@end
