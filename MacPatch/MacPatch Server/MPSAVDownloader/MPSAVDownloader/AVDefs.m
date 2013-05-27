//
//  AVDefs.m
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

#import "AVDefs.h"
#import "SSCrypto.h"
#import "RegexKitLite/RegexKitLite.h"
#include <curl/curl.h>
#include <stdio.h>
#include <unistd.h>

@interface NSURLRequest (SomePrivateAPIs)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(id)fp8;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)fp8 forHost:(id)fp12;
@end

@implementation AVDefs

@synthesize remoteAVURL, remoteAVInfoURL;
@synthesize avDefsDict, avDefsDictArray, rawHttpResults, avXMLData, dlFilePath, dlFilePathDir;
@synthesize avTempData;

- (id)initWithURL:(NSURL *)theURL
{
	self = [super init];
	if (theURL) {
		return self;		
	}
	return self;
}

- (NSArray *)itemsInCollection:(NSArray *)collection containingWord:(NSString *)word 
{
	NSPredicate *containsWordPredicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", word];
	return [collection filteredArrayUsingPredicate:containsWordPredicate];
}

- (void)remoteAVData
{
	int x = -1;
	x = [self getRemoteAVDataViaFtp];
	if (x == 0) {
		[self parseRemoteAVData];
	} else {
		logit(lcl_vError,@"There was a error getting the remote av info.");
	}
}

- (int)getRemoteAVDataViaFtp
{
	logit(lcl_vInfo,@"Downloading AV def info from %@",remoteAVURL);

	NSString *fileName = @".mpftpData";
	[self setAvTempData:[NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),fileName]];
	logit(lcl_vDebug,@"Temp AV ftp request file, %@", avTempData);

	FILE *dlFile = fopen([avTempData UTF8String], "w");
	
	CURL *curl;
	CURLcode res;
	curl = curl_easy_init();
	if (curl) {
		// Set Options
		curl_easy_setopt(curl, CURLOPT_URL, [remoteAVURL cStringUsingEncoding:NSUTF8StringEncoding] ) ;
		curl_easy_setopt(curl, CURLOPT_USERPWD, "ftp:ftp");
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, dlFile);
        curl_easy_setopt(curl, CURLOPT_DIRLISTONLY, 1);
		
		// Run CURL
		res = curl_easy_perform( curl );
		if (res != 0)
		{
			NSLog(@"Error[%d], trying to download file.",res);
		}
	} else {
		NSLog(@"Error, trying to init curl lib.");
	}
	
	// Clean up curl handle and file handle
	curl_easy_cleanup( curl );
	fclose(dlFile);
	return res;
}

- (void)parseRemoteAVData
{
	NSString *fileContents = [NSString stringWithContentsOfFile:avTempData];
	NSArray *_fileArray = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	logit(lcl_vDebug,@"File Contents:\n%@",_fileArray);
	
	NSMutableArray *ppcArray;
	NSMutableArray *x86Array;
	
	NSSortDescriptor * sortDesc = [[[NSSortDescriptor alloc] initWithKey:@"self" ascending:NO] autorelease];
	NSPredicate *containsWordsPredicate;
	containsWordsPredicate = [NSPredicate predicateWithFormat:@"(SELF CONTAINS[cd] %@) AND (SELF CONTAINS[cd] %@)", @".zip", @"NavM9_"];
	ppcArray = [NSMutableArray arrayWithArray:[_fileArray filteredArrayUsingPredicate:containsWordsPredicate]];	
	[ppcArray sortUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
	if ([ppcArray count] > 3) {
		[ppcArray removeObjectsInRange:NSMakeRange(3,([ppcArray count] - 3))];
	}	
	logit(lcl_vDebug,@"[RAW]: PPC AV Updates: %@",ppcArray);
	for (int i = 0; i < [ppcArray count]; i++) {
		[ppcArray replaceObjectAtIndex:i withObject:[ppcArray objectAtIndex:i]];
	}
	logit(lcl_vInfo,@"PPC AV Updates: %@",ppcArray);
	
	containsWordsPredicate = [NSPredicate predicateWithFormat:@"(SELF CONTAINS[cd] %@) AND (SELF CONTAINS[cd] %@)", @".zip", @"NavM_"];
	x86Array = [NSMutableArray arrayWithArray:[_fileArray filteredArrayUsingPredicate:containsWordsPredicate]];
	[x86Array sortUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
	if ([x86Array count] > 3) {
		[x86Array removeObjectsInRange:NSMakeRange(3,([x86Array count] - 3))];
	}
	logit(lcl_vDebug,@"[RAW]: X86 AV Updates: %@",x86Array);
	NSLog(@"%@",x86Array);
	for (int i = 0; i < [x86Array count]; i++) {
		[x86Array replaceObjectAtIndex:i withObject:[x86Array objectAtIndex:i]];
	}
	logit(lcl_vInfo,@"X86 AV Updates: %@",x86Array);
	
	NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
	[tmpDict setObject:x86Array forKey:@"x86"];
	[tmpDict setObject:ppcArray forKey:@"ppc"];
	
	[self setAvDefsDict:[NSMutableDictionary dictionaryWithDictionary:tmpDict]];
	[tmpDict release];
	
}

- (NSXMLDocument *)createAVXMLDoc:(NSArray *)theArray
{
	/*
	 <?xml version="1.0" encoding="UTF-8"?>
	 <root>
		 <sav>
			 <arch type="ppc">
				<def date="20090605" current="YES">NavM9_Installer_20090605_US.zip</def>
				<def date="20090604" current="NO">NavM9_Installer_20090604_US.zip</def>
			 </arch>
			 <arch type="x86">
				<def date="20090605" current="YES">NavM_Intel_Installer_20090605_US.zip</def>
				<def date="20090604" current="NO">NavM_Intel_Installer_20090604_US.zip</def>
			 </arch>
		 </sav>
	 </root>
	 */
	NSSortDescriptor* nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	logit(lcl_vInfo,@"Generating XML representation of AV def packages.");
	
	NSMutableArray *mastArrayPPC = [[NSMutableArray alloc] init];
	NSMutableArray *mastArrayX86 = [[NSMutableArray alloc] init];
	
	NSEnumerator *enumerator = [[avDefsDict objectForKey:@"ppc"] objectEnumerator];
	id anObject;
	
	// Loop Through PPC
	while (anObject = [enumerator nextObject]) {
		NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
		[tmpDict setObject:[self returnAVDefsFileDate:anObject] forKey:@"date"];
		[tmpDict setObject:anObject forKey:@"file"];
		[tmpDict setObject:@"NO" forKey:@"current"];
		[mastArrayPPC addObject:tmpDict];
		[tmpDict release];
	}
	
	// Loop Through X86
	enumerator = [[avDefsDict objectForKey:@"x86"] objectEnumerator];
	while (anObject = [enumerator nextObject]) {
		NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
		[tmpDict setObject:[self returnAVDefsFileDate:anObject] forKey:@"date"];
		[tmpDict setObject:anObject forKey:@"file"];
		[tmpDict setObject:@"NO" forKey:@"current"];
		[mastArrayX86 addObject:tmpDict];
		[tmpDict release];
	}

	NSArray* sortedArray = [[NSArray arrayWithArray:mastArrayPPC] sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameSortDescriptor]];
	
	[[sortedArray objectAtIndex:0] setObject:@"YES" forKey:@"current"];
	[mastArrayPPC removeAllObjects];
	[mastArrayPPC addObjectsFromArray:[NSArray arrayWithArray:sortedArray]];
	
	sortedArray = [[NSArray arrayWithArray:mastArrayX86] sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameSortDescriptor]];
	[[sortedArray objectAtIndex:0] setObject:@"YES" forKey:@"current"];
	[mastArrayX86 removeAllObjects];
	[mastArrayX86 addObjectsFromArray:[NSArray arrayWithArray:sortedArray]];
	
	
	
	// XML
	// Set Root Element
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"root"];
	avXMLData = [[NSXMLDocument alloc] initWithRootElement:root];
	[avXMLData setVersion:@"1.0"];
	[avXMLData setCharacterEncoding:@"UTF-8"];
	
	// Define the SAV Element
	NSXMLElement *savElement = [NSXMLNode elementWithName:@"sav"];
	[root addChild:savElement];
	// Define ARCH Element
	NSXMLElement *archElement = [NSXMLNode elementWithName:@"arch"];
	[savElement addChild:archElement];
	[archElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"ppc"]];
	//Define def Element
	NSXMLElement *defElement;
	
	// PPC
	// Add the defs to the right arch type
	enumerator = [mastArrayPPC objectEnumerator];
	id obj;
	while (obj = [enumerator nextObject]) {
		defElement = [NSXMLNode elementWithName:@"def"];
		[defElement setStringValue:[NSString stringWithFormat:@"%@/%@",dlFilePath,[obj objectForKey:@"file"]]];
		[defElement addAttribute:[NSXMLNode attributeWithName:@"date" stringValue:[obj objectForKey:@"date"]]];
		[defElement addAttribute:[NSXMLNode attributeWithName:@"current" stringValue:[obj objectForKey:@"current"]]];
		[archElement addChild:defElement];
	}
	
	// X86
	// Add the defs to the right arch type
	archElement = [NSXMLNode elementWithName:@"arch"];
	[archElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"x86"]];
	[savElement addChild:archElement];
	
	enumerator = [mastArrayX86 objectEnumerator];
	while (obj = [enumerator nextObject]) {
		defElement = [NSXMLNode elementWithName:@"def"];
		[defElement setStringValue:[NSString stringWithFormat:@"%@/%@",dlFilePath,[obj objectForKey:@"file"]]];
		[defElement addAttribute:[NSXMLNode attributeWithName:@"date" stringValue:[obj objectForKey:@"date"]]];
		[defElement addAttribute:[NSXMLNode attributeWithName:@"current" stringValue:[obj objectForKey:@"current"]]];
		[archElement addChild:defElement];
	}
	
	[mastArrayPPC release];
	[mastArrayX86 release];
	[nameSortDescriptor release];
	return avXMLData;
}
								
- (NSString *)returnAVDefsFileDate:(NSString *)avFileName
{
	NSString *regexString = @"_([0-9].*)_"; 
	NSString *matchedString = [avFileName stringByMatching:regexString capture:1]; 
	return matchedString;
}


-(NSString *)getFileHash:(NSString *)localFilePath hashType:(NSString *)type
{
	NSString *hashResult = nil;
	SSCrypto *crypto;
	NSData *fileData	= [NSData dataWithContentsOfFile:localFilePath];
	
	if (!fileData)
		return NULL;
	
	crypto = [[SSCrypto alloc] init];
	[crypto setClearTextWithData:fileData];
	
	if ([type isEqualToString:@"MD5"]) {
		hashResult = [[crypto digest:@"MD5"] hexval];
	} else if ([type isEqualToString:@"SHA1"]) {
		hashResult = [[crypto digest:@"SHA1"] hexval];
	}
	
    [crypto release];
	return hashResult;
}

- (void) dealloc {
	[avDefsDict release];
	[avDefsDictArray release];
	[remoteAVURL release];
	[avXMLData release];
	[rawHttpResults release];
	[super dealloc]; 
}

@end
