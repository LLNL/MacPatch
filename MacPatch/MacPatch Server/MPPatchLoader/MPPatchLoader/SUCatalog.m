//
//  SUCatalog.m
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

#import "SUCatalog.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSData+Base64.h"
#import "lcl.h"
#import "MPManager.h"
#import "RegexKitLite.h"



// Alt URL
#define SUCATALOG_105	@"index-leopard.merged-1.sucatalog"
#define SUCATALOG_106	@"index-leopard-snowleopard.merged-1.sucatalog"
#define SUCATALOG_107	@"index-lion-snowleopard-leopard.merged-1.sucatalog"
#define SUCATALOG_108   @"index-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
#define SAMPLEDIST		@"[NEED SERVER ADDRESS]/content/downloads/22/18/061-7116/DWK9NtpsggcpsQ9VKZpNP49qv6bRNHgZp2/061-7116.English.dist"


@implementation SUCatalog
@synthesize products;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		sm = [MPManager sharedManager];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSString *)downloadSUContent:(NSString *)aASUSURL catalog:(NSString *)aCatalogURL osver:(NSString *)aOSVer
{
	NSString *l_osVer = NULL;
	NSString *l_asusURL = NULL;
	l_osVer = aOSVer;
	l_asusURL = [NSString stringWithFormat:@"%@/%@",[[sm g_Defaults] objectForKey:@"ASUSServer"],aCatalogURL];

	NSError *error = nil;
	NSString *result = nil;
	result = [self readSUCatalogURLAsString:l_asusURL error:&error];
	if (error) {
		logit(lcl_vError,@"%@",[error localizedDescription]);
		return NULL;
	}
	
	NSString *errorDesc = nil;
	NSPropertyListFormat format;
	NSDictionary *sucatalogPlist = [NSPropertyListSerialization propertyListFromData:[result dataUsingEncoding:NSUTF8StringEncoding] 
																	mutabilityOption:NSPropertyListImmutable
																			  format:&format
																	errorDescription:&errorDesc];
	
	

	NSMutableDictionary *l_prods = [NSMutableDictionary dictionaryWithDictionary:[sucatalogPlist objectForKey:@"Products"]];
	logit(lcl_vInfo,@"Patch entires found %lu for %@",[[l_prods allKeys] count],aOSVer);
	
	NSDictionary *curPatch;
	NSDictionary *smdPlist = nil;
	NSDictionary *distData = nil;
	NSMutableDictionary *l_patch = nil;
	NSString *descStr = nil;
	NSData *descData = nil;
	NSMutableArray *newProds = [[NSMutableArray alloc] init];
	NSDateFormatter *dformat = [[NSDateFormatter alloc] init];
	[dformat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	for (id aKey in [l_prods allKeys]) {
		curPatch = nil;
		curPatch = [l_prods objectForKey:aKey];
		
		l_patch = [[NSMutableDictionary alloc] init];
		[l_patch setObject:aKey forKey:@"akey"];
		[l_patch setObject:[curPatch objectForKey:@"ServerMetadataURL"] forKey:@"ServerMetadataURL"];
		
		
		[l_patch setObject:[dformat stringFromDate:[curPatch objectForKey:@"PostDate"]] forKey:@"postdate"];
		[l_patch setObject:l_osVer forKey:@"osver"];
		[l_patch setObject:aKey forKey:@"patchname"];
		
		if ([[curPatch objectForKey:@"Distributions"] objectForKey:@"English"]) {
			[l_patch setObject:[[curPatch objectForKey:@"Distributions"] objectForKey:@"English"] forKey:@"Distribution"];	
		} else if ([[curPatch objectForKey:@"Distributions"] objectForKey:@"en"]) {
			[l_patch setObject:[[curPatch objectForKey:@"Distributions"] objectForKey:@"en"] forKey:@"Distribution"];
		}
		
		smdPlist = [self readSMDFile:[curPatch objectForKey:@"ServerMetadataURL"] error:NULL];
		if (smdPlist != nil) {
			if ([smdPlist objectForKey:@"CFBundleShortVersionString"]) {
				[l_patch setObject:[smdPlist objectForKey:@"CFBundleShortVersionString"] forKey:@"CFBundleShortVersionString"];
			} else {
				[l_patch setObject:@"0.1" forKey:@"CFBundleShortVersionString"];
			}
			if ([smdPlist objectForKey:@"IFPkgFlagRestartAction"]) {
				[l_patch setObject:[smdPlist objectForKey:@"IFPkgFlagRestartAction"] forKey:@"IFPkgFlagRestartAction"];
			} else {
				[l_patch setObject:@"RequireRestart" forKey:@"IFPkgFlagRestartAction"];
			}
			if ([[smdPlist objectForKey:@"localization"] objectForKey:@"English"]) {
				if ([[[smdPlist objectForKey:@"localization"] objectForKey:@"English"] objectForKey:@"description"]) {
					descData = [[[smdPlist objectForKey:@"localization"] objectForKey:@"English"] objectForKey:@"description"];
					descStr = [descData base64EncodedString];
					[l_patch setObject:descStr forKey:@"description"];
				}	
				if ([[[smdPlist objectForKey:@"localization"] objectForKey:@"English"] objectForKey:@"title"])
					[l_patch setObject:[[[smdPlist objectForKey:@"localization"] objectForKey:@"English"] objectForKey:@"title"] forKey:@"title"];
			} else if ([[smdPlist objectForKey:@"localization"] objectForKey:@"en"]) {				
				if ([[[smdPlist objectForKey:@"localization"] objectForKey:@"en"] objectForKey:@"description"]) {
					descData = [[[smdPlist objectForKey:@"localization"] objectForKey:@"en"] objectForKey:@"description"];
					descStr = [descData base64EncodedString];
					[l_patch setObject:descStr forKey:@"description"];
				}	
				if ([[[smdPlist objectForKey:@"localization"] objectForKey:@"en"] objectForKey:@"title"])
					[l_patch setObject:[[[smdPlist objectForKey:@"localization"] objectForKey:@"en"] objectForKey:@"title"] forKey:@"title"];
			}
		} else {
			logit(lcl_vWarning,@"Patch %@, content was not found. Skipping %@",aKey,aKey);
			[l_patch release];
			l_patch = nil;
			continue;
		}
		
		[l_patch setObject:[NSString stringWithFormat:@"%@-%@",aKey,[l_patch objectForKey:@"CFBundleShortVersionString"]] forKey:@"supatchname"];
		
		distData = [self readDistFile:[l_patch objectForKey:@"Distribution"] error:NULL];
		if ([[distData objectForKey:@"suPatchName"] isEqual:NULL] == NO) {
			if ([distData objectForKey:@"suPatchName"]) {
				[l_patch setObject:[distData objectForKey:@"suPatchName"] forKey:@"patchname"];
                // If Blank of 0.1 do another check ...
                if ([[l_patch objectForKey:@"CFBundleShortVersionString"] isEqualToString:@""]) {
                    [l_patch setObject:[distData objectForKey:@"altVersion"] forKey:@"CFBundleShortVersionString"];
                    [l_patch setObject:[NSString stringWithFormat:@"%@-%@",[distData objectForKey:@"suPatchName"],[l_patch objectForKey:@"CFBundleShortVersionString"]] forKey:@"supatchname"];
                } else if ([[l_patch objectForKey:@"CFBundleShortVersionString"] isEqualToString:@"0.1"]) {
                    [l_patch setObject:[distData objectForKey:@"altVersion"] forKey:@"CFBundleShortVersionString"];
                    [l_patch setObject:[NSString stringWithFormat:@"%@-%@",[distData objectForKey:@"suPatchName"],[l_patch objectForKey:@"CFBundleShortVersionString"]] forKey:@"supatchname"];
                }
                
                [l_patch setObject:[NSString stringWithFormat:@"%@-%@",[distData objectForKey:@"suPatchName"],[l_patch objectForKey:@"CFBundleShortVersionString"]] forKey:@"supatchname"];
			} else if ([[l_patch objectForKey:@"ServerMetadataURL"] rangeOfString:@"_PrinterSupport.smd"].location != NSNotFound) {
				[l_patch setObject:aKey forKey:@"patchname"];
				[l_patch setObject:[NSString stringWithFormat:@"%@-%@",aKey,[l_patch objectForKey:@"CFBundleShortVersionString"]] forKey:@"supatchname"];
			}
				
			// Set Reboot Override
			if ([[distData objectForKey:@"altReboot"] isEqual:NULL] == NO)
				if ([[distData objectForKey:@"altReboot"] isEqualToString:[l_patch objectForKey:@"IFPkgFlagRestartAction"]] == NO)
					[l_patch setObject:@"RequireRestart" forKey:@"IFPkgFlagRestartAction"];
				
		}
		
		[l_patch removeObjectForKey:@"ServerMetadataURL"];
		[l_patch removeObjectForKey:@"Distribution"];
		[newProds addObject:l_patch];
		[l_patch release];
		l_patch = nil;
	}
	
	logit(lcl_vInfo,@"Patches to add: %d",(int)[newProds count]);
	NSString *fileNamePath = [NSString stringWithFormat:@"/tmp/suPatches_%@.plist",l_osVer]; 
	[newProds writeToFile:fileNamePath atomically:YES];
	[newProds release];
	newProds = nil;
	
	return fileNamePath;
}
- (NSString *)readSUCatalogURLAsString:(NSString *)catalogURL error:(NSError **)err
{	
	NSString *result = NULL;
	NSAutoreleasePool *inPool = [[NSAutoreleasePool alloc] init];
	
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	[[NSURLCache sharedURLCache] setDiskCapacity:0];  
	 
    NSError *error = nil;
    NSString *fileContents = [[[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:catalogURL]
															 encoding:NSUTF8StringEncoding error:&error] autorelease];
	NSDictionary *userInfoDict;
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
		logit(lcl_vError,@"%@",[error localizedDescription]);
		goto done;
	} else {
		result = [fileContents retain];
	}
	
    [inPool drain];

done:
	return result;
}

- (NSDictionary *)readSMDFile:(NSString *)smdURL  error:(NSError **)err
{
	NSDictionary *result = nil;
	
	NSError *error = nil;
	NSString *requestString = NULL;
	requestString = [self readSUCatalogURLAsString:smdURL error:&error];
	if (error) {
		logit(lcl_vError,@"%@",[error localizedDescription]);
		goto done;
	}
	
	NSPropertyListFormat format;
	error = nil;
	result = [NSPropertyListSerialization propertyListWithData:[requestString dataUsingEncoding:NSUTF8StringEncoding] 
													   options:NSPropertyListImmutable 
														format:&format 
														 error:&error];
	NSDictionary *userInfoDict;
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
		logit(lcl_vError,@"%@",[error localizedDescription]);
		goto done;	
	}
done:
	return result;
}

- (NSDictionary *)readDistFile:(NSString *)distURL  error:(NSError **)err
{
	NSMutableDictionary *resTmpDict = [[NSMutableDictionary alloc] init];
	// Define empty result
	[resTmpDict setValue:NULL forKey:@"suPatchName"];
	[resTmpDict setValue:NULL forKey:@"altReboot"];
    [resTmpDict setValue:@"0.1" forKey:@"altVersion"];
	
	
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:resTmpDict];
	NSError *error = nil;
	NSString *requestString = nil;
	requestString = [self readSUCatalogURLAsString:distURL error:&error];
	NSDictionary *userInfoDict = nil;
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
		logit(lcl_vError,@"%@",[error localizedDescription]);
		[resTmpDict release];
		goto done;
	}
	
	// Parse the XML Result
	error = nil;
	NSXMLDocument *distXML = [[NSXMLDocument alloc] initWithData:[requestString dataUsingEncoding:NSUTF8StringEncoding] 
														 options:NSXMLDocumentXMLKind 
														   error:&error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
		logit(lcl_vError,@"%@",[error localizedDescription]);
		[distXML release];
		[resTmpDict release];
		goto done;
	}
	
	// Search for "Choice XML Node containing id=su and suDisabledGroupID attributes
	error = nil;
	NSArray *qrySUPatchName = [distXML nodesForXPath:@"//choice[@id='su' and @suDisabledGroupID]" error:&error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
		logit(lcl_vError,@"%@",[error localizedDescription]);
		[distXML release];
		[resTmpDict release];
		goto done;
	}
	
	// Parse the results to get the patch name and alt renboot
	if ([qrySUPatchName count] == 1) {
		NSXMLElement *element = [qrySUPatchName objectAtIndex:0];
		[resTmpDict setValue:[[element attributeForName:@"suDisabledGroupID"] stringValue] forKey:@"suPatchName"];
		if ([element attributeForName:@"onConclusion"]) {
			if ([[[element attributeForName:@"onConclusion"] stringValue] isEqualToString:@"RequireRestart"]) {
				[resTmpDict setValue:@"RequireRestart" forKey:@"altReboot"];
			}
		}
        NSString *altVerString = [self readSUVERS:qrySUPatchName distData:requestString];
        [resTmpDict setValue:altVerString forKey:@"altVersion"];
        
	} else {
		// Log Error 	
	}
	[distXML release];
	distXML = nil;
	
	result = [NSDictionary dictionaryWithDictionary:resTmpDict];
	[resTmpDict release];
	resTmpDict = nil;
	
done:
	return result;	
}

- (NSString  *)readSUVERS:(NSArray *)nodesForXPath distData:(NSString *)aDistData
{
    NSString *suVersData = @"0.1";
    NSXMLElement *element = [nodesForXPath objectAtIndex:0];
    if ([element attributeForName:@"versStr"]) {
        if ([[[element attributeForName:@"versStr"] stringValue] isEqualToString:@"SU_VERS"]) {
            // Search for "SU_VERS" = ...
            NSString *regexString	= @"(\"SU_VERS\" = )(.*?)+";
            NSString *matchedString = [aDistData stringByMatching:regexString];
            NSString *matchedStringParse1 = [[matchedString componentsSeparatedByString:@"="] objectAtIndex:1];
            NSString *matchedStringTrim1 = [matchedStringParse1 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            NSString *matchedStringTrim2 = [matchedStringTrim1 stringByReplacingOccurrencesOfString:@";" withString:@""];
            suVersData = [matchedStringTrim2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
        } else {
            suVersData = [[element attributeForName:@"versStr"] stringValue];
        }
    }
 
    return suVersData;
}

#pragma mark -
#pragma mark Test Methods

- (void)testReadDist
{
	NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
	// Define empty result
	[res setValue:NULL forKey:@"suPatchName"];
	[res setValue:@"NoRestart" forKey:@"altReboot"];
	
	NSError *error = nil;
	NSString *resultData = nil;
	resultData = [self readSUCatalogURLAsString:SAMPLEDIST error:&error];
	if (error) {
		NSLog(@"%@",[error localizedDescription]);
		[res release];
		return;
	}
	
	// Parse the XML Result
	error = nil;
	NSXMLDocument *distXML = [[NSXMLDocument alloc] initWithData:[resultData dataUsingEncoding:NSUTF8StringEncoding] options:NSXMLDocumentXMLKind error:&error];
	if (error) {
		NSLog(@"%@",[error localizedDescription]);
		[distXML release];
		[res release];
		return;
	}
	
	// Search for "Choice XML Node containing id=su and suDisabledGroupID attributes
	error = nil;
	NSArray *qrySUPatchName = [distXML nodesForXPath:@"//choice[@id='su' and @suDisabledGroupID]" error:&error];
	if (error) {
		NSLog(@"%@",[error localizedDescription]);
		[distXML release];
		[res release];
		return;
	}
	
	// Parse the results to get the patch name and alt renboot
	if ([qrySUPatchName count] == 1) {
		NSXMLElement *element = [qrySUPatchName objectAtIndex:0];
		[res setValue:[[element attributeForName:@"suDisabledGroupID"] stringValue] forKey:@"suPatchName"];
		if ([element attributeForName:@"onConclusion"]) {
			if ([[[element attributeForName:@"onConclusion"] stringValue] isEqualToString:@"RequireRestart"]) {
				[res setValue:@"RequireRestart" forKey:@"altReboot"];
			} else {
				[res setValue:@"NoRestart" forKey:@"altReboot"];
			}
		} else {
			[res setValue:@"NoRestart" forKey:@"altReboot"];
		}
	} else {
		// Log Error 	
	}
	[distXML release];
	distXML = nil;
	
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:res];
	[res release];
	res = nil;

	NSLog(@"Result = %@",result);
}

@end
