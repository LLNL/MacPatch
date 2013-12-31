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
//#import "NSData+Base64.h"
#import "lcl.h"
#import "MPManager.h"
#import "RegexKitLite.h"
#import "MPApplePatch.h"
#import "NSString+Helper.h"
#include <Security/Security.h>


// Alt URL
#define SUCATALOG_105	@"index-leopard.merged-1.sucatalog"
#define SUCATALOG_106	@"index-leopard-snowleopard.merged-1.sucatalog"
#define SUCATALOG_107	@"index-lion-snowleopard-leopard.merged-1.sucatalog"
#define SUCATALOG_108   @"index-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
#define SUCATALOG_109   @"index-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
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


- (NSString *)downloadSUContent:(NSString *)aASUSURL catalog:(NSString *)aCatalogURL osver:(NSString *)aOSVer
{
	NSString *l_asusURL = [NSString stringWithFormat:@"%@/%@",[[sm g_Defaults] objectForKey:@"ASUSServer"],aCatalogURL];

    NSError *error = nil;
	NSString *result = nil;
	result = [self readSUCatalogURLAsString:l_asusURL error:&error];
	if (error) {
		logit(lcl_vError,@"%@",[error localizedDescription]);
		return NULL;
	}

    // Create a proper PLIST from the SoftwareUpdate catalog URL result
	NSString *errorDesc = nil;
	NSPropertyListFormat format;
	NSDictionary *suCatalogPlist = [NSPropertyListSerialization propertyListFromData:[result dataUsingEncoding:NSUTF8StringEncoding]
																	mutabilityOption:NSPropertyListImmutable
																			  format:&format
																	errorDescription:&errorDesc];

    // Create a dictionary containing all of the Products (Patches) from the plist
    NSMutableDictionary *patches = [NSMutableDictionary dictionaryWithDictionary:[suCatalogPlist objectForKey:@"Products"]];
	logit(lcl_vInfo,@"Patch entires found %lu for %@",[[patches allKeys] count],aOSVer);

    NSDictionary *curPatch;
	NSDictionary *smdPlist = nil;
	NSDictionary *distData = nil;

    MPApplePatch *aPatch;

	NSData *descData = nil;
	NSMutableArray *_products = [[NSMutableArray alloc] init];
	NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
	[dateformat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    for (id aKey in [patches allKeys])
    {
        if ([aKey isEqualToString:@"061-4089"]){
            sleep(1);
        }


		curPatch = nil;
		curPatch = [patches objectForKey:aKey];
        aPatch = nil;
        aPatch = [[MPApplePatch alloc] init];
        [aPatch setAkey:aKey];
        [aPatch setOsver:aOSVer];
        [aPatch setPatchname:aKey];

        // Set ServerMetadataURL
        if ([curPatch objectForKey:@"ServerMetadataURL"]) {
            [aPatch setServerMetadataURL:[curPatch objectForKey:@"ServerMetadataURL"]];
        }

        // Set PostDate
        if ([curPatch objectForKey:@"PostDate"]) {
            [aPatch setPostdate:[dateformat stringFromDate:[curPatch objectForKey:@"PostDate"]]];
        }

        // Set Distributions for English
        if ([curPatch objectForKey:@"Distributions"]) {
            if ([[curPatch objectForKey:@"Distributions"] objectForKey:@"English"]) {
                [aPatch setDistribution:[[curPatch objectForKey:@"Distributions"] objectForKey:@"English"]];
            } else if ([[curPatch objectForKey:@"Distributions"] objectForKey:@"en"]) {
                [aPatch setDistribution:[[curPatch objectForKey:@"Distributions"] objectForKey:@"en"]];
            }
        }

        // Read SMD file
        error = nil;
        smdPlist = nil;
        smdPlist = [self readSMDFile:[curPatch objectForKey:@"ServerMetadataURL"] error:&error];
        if (error) {
            // Skip, no data
            logit(lcl_vWarning,@"Patch %@, content was not found. Skipping %@",aKey,aKey);
            aPatch = nil;
            continue;
        }

        if (smdPlist)
        {
            // Set Patch Version
            if ([smdPlist objectForKey:@"CFBundleShortVersionString"]) {
                [aPatch setCFBundleShortVersionString:[smdPlist objectForKey:@"CFBundleShortVersionString"]];
			}

            // Set Reboot
            if ([smdPlist objectForKey:@"IFPkgFlagRestartAction"]) {
                [aPatch setIFPkgFlagRestartAction:[smdPlist objectForKey:@"IFPkgFlagRestartAction"]];
			}

            // Set Description & title from localization for English
            if ([smdPlist objectForKey:@"localization"])
            {
                if ([[smdPlist objectForKey:@"localization"] objectForKey:@"English"]) {
                    if ([[[smdPlist objectForKey:@"localization"] objectForKey:@"English"] objectForKey:@"description"]) {
                        descData = [[[smdPlist objectForKey:@"localization"] objectForKey:@"English"] objectForKey:@"description"];
                        NSString *descDataStr = [[NSString alloc] initWithData:descData encoding:NSUTF8StringEncoding];
                        NSData *encodedData = [descDataStr dataUsingEncoding:NSUTF8StringEncoding];
                        [aPatch setPatchDescription:[encodedData base64Encoding]];
                        descDataStr = nil;
                    }
                    if ([[[smdPlist objectForKey:@"localization"] objectForKey:@"English"] objectForKey:@"title"]) {
                        [aPatch setTitle:[[[smdPlist objectForKey:@"localization"] objectForKey:@"English"] objectForKey:@"title"]];
                    }
                } else if ([[smdPlist objectForKey:@"localization"] objectForKey:@"en"]) {
                    if ([[[smdPlist objectForKey:@"localization"] objectForKey:@"en"] objectForKey:@"description"]) {
                        descData = [[[smdPlist objectForKey:@"localization"] objectForKey:@"en"] objectForKey:@"description"];
                        NSString *descDataStr = [[NSString alloc] initWithData:descData encoding:NSUTF8StringEncoding];
                        NSData *encodedData = [descDataStr dataUsingEncoding:NSUTF8StringEncoding];
                        [aPatch setPatchDescription:[encodedData base64Encoding]];
                        descDataStr = nil;
                    }
                    if ([[[smdPlist objectForKey:@"localization"] objectForKey:@"en"] objectForKey:@"title"]) {
                        [aPatch setTitle:[[[smdPlist objectForKey:@"localization"] objectForKey:@"en"] objectForKey:@"title"]];
                    }
                }
            }
        } else {
            // Skip, no data
            logit(lcl_vWarning,@"Patch %@, content was not found. Skipping %@",aKey,aKey);
            aPatch = nil;
            continue;
        }

        // Set suPatchName name and version
        [aPatch setSupatchname:[NSString stringWithFormat:@"%@-%@",aKey,[aPatch CFBundleShortVersionString]]];

        // Read Dist Data
        error = nil;
        distData = nil;
        distData = [self readDistFile:[aPatch Distribution] error:&error];
        if (error) {
            // Skip, no data
            logit(lcl_vWarning,@"[ReadDistFile]Patch %@, content was not found. Skipping %@",aKey,aKey);
            aPatch = nil;
            continue;
        }
        if (distData)
        {
            if ([distData objectForKey:@"suPatchName"]) {
                [aPatch setPatchname:[distData objectForKey:@"suPatchName"]];
                if ([[aPatch CFBundleShortVersionString] isEqualToString:@""] || [[aPatch CFBundleShortVersionString] isEqualToString:@"0.1"]) {
                    if ([distData objectForKey:@"altVersion"]) {
                        [aPatch setCFBundleShortVersionString:[distData objectForKey:@"altVersion"]];
                    }
                }

                [aPatch setSupatchname:[NSString stringWithFormat:@"%@-%@",[distData objectForKey:@"suPatchName"],[aPatch CFBundleShortVersionString]]];
            }

            if ([distData objectForKey:@"altReboot"]) {
                if ([[distData objectForKey:@"altReboot"] isEqualToString:[aPatch IFPkgFlagRestartAction]] == NO) {
                    [aPatch setIFPkgFlagRestartAction:[distData objectForKey:@"altReboot"]];
                }
            }
        }

        // Remove the ServerMetadataURL & Distribution values, not needed anymore
        [aPatch setServerMetadataURL:@""];
        [aPatch setDistribution:@""];

        // Add Patch as a Dictionary to the Array
        [_products addObject:[aPatch patchAsDictionary]];
        aPatch = nil;
	}

    logit(lcl_vInfo,@"Patches to add: %d",(int)[_products count]);
	NSString *fileNamePath = [NSString stringWithFormat:@"/tmp/suPatches_%@.plist",aOSVer];
	[_products writeToFile:fileNamePath atomically:YES];
	_products = nil;

	return fileNamePath;
}

- (NSString *)readSUCatalogURLAsString:(NSString *)catalogURL error:(NSError **)err
{	
	NSString *result = NULL;
    @autoreleasepool
    {
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0];

        NSError *error = nil;
        NSString *fileContents = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:catalogURL]
                                                                 encoding:NSUTF8StringEncoding error:&error];
        NSDictionary *userInfoDict;
        if (error) {
            userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
            if (err != NULL) {
                *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
            } else {
                logit(lcl_vError,@"%@",[error localizedDescription]);
            }
        } else {
            result = fileContents;
        }

        return result;
    }
}

- (NSDictionary *)readSMDFile:(NSString *)smdURL  error:(NSError **)err
{
	NSDictionary *result = nil;
	NSDictionary *userInfoDict;

    if (smdURL == nil) {
        return nil;
    }

	NSError *error = nil;
	NSString *requestString = NULL;
	requestString = [self readSUCatalogURLAsString:smdURL error:&error];
	if (error) {
        userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
        } else {
            logit(lcl_vError,@"%@",[error localizedDescription]);
        }
		goto done;
	}
	
	NSPropertyListFormat format;
	error = nil;
	result = [NSPropertyListSerialization propertyListWithData:[requestString dataUsingEncoding:NSUTF8StringEncoding] 
													   options:NSPropertyListImmutable 
														format:&format 
														 error:&error];

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
    [resTmpDict setValue:NULL forKey:@"altVersion"];
	
	
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:resTmpDict];
	NSError *error = nil;
	NSString *requestString = nil;
	requestString = [self readSUCatalogURLAsString:distURL error:&error];
	NSDictionary *userInfoDict = nil;
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
		logit(lcl_vError,@"%@",[error localizedDescription]);
		return result;
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
		return result;
	}
	
	// Search for "Choice XML Node containing id=su and suDisabledGroupID attributes
	error = nil;
	NSArray *qrySUPatchName = [distXML nodesForXPath:@"//choice[@id='su' and @suDisabledGroupID]" error:&error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.patchloader" code:[error code] userInfo:userInfoDict];
		logit(lcl_vError,@"%@",[error localizedDescription]);
		goto done;
	}
	
	// Parse the results to get the patch name and alt renboot
	if ([qrySUPatchName count] == 1) {
		NSXMLElement *element = [qrySUPatchName objectAtIndex:0];
        NSString *elementXML = [[qrySUPatchName objectAtIndex:0] XMLString];

        [resTmpDict setValue:[[element attributeForName:@"suDisabledGroupID"] stringValue] forKey:@"suPatchName"];
        if ([elementXML containsString:@"onConclusion" ignoringCase:YES]) {
            if ([elementXML containsString:@"RequireRestart" ignoringCase:YES] || [elementXML containsString:@"RequireShutdown" ignoringCase:YES]) {
                [resTmpDict setValue:@"RequireRestart" forKey:@"altReboot"];
            }
        }

        NSString *altVerString = [self readSUVERS:qrySUPatchName distData:requestString];
        [resTmpDict setValue:altVerString forKey:@"altVersion"];
        
	} else {
		// Log Error 	
	}
	distXML = nil;
	
	result = [NSDictionary dictionaryWithDictionary:resTmpDict];
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
            NSString *regexString	= @"(?i)(\"SU_VERS\")(\\s*=\\s*)(.*)";
            NSString *matchedString = [aDistData stringByMatching:regexString];
            NSString *matchedStringParse1 = [[matchedString componentsSeparatedByString:@"="] objectAtIndex:1];
            NSString *matchedStringTrim1 = [matchedStringParse1 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            NSString *matchedStringTrim2 = [matchedStringTrim1 stringByReplacingOccurrencesOfString:@";" withString:@""];
            suVersData = [matchedStringTrim2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        } else {
            suVersData = [[element attributeForName:@"versStr"] stringValue];
        }
    }
    if (suVersData == NULL || [suVersData isEqualTo:@""]) {
        suVersData = @"0.1";
    }
    return suVersData;
}

@end
