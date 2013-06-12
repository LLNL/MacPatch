//
//  MPPatchScan.m
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

#import "MPPatchScan.h"
#import "MPSoap.h"
#import "MPDefaults.h"
#import "MPDataMgr.h"
#import "MPOSCheck.h"
#import "MPBundle.h"
#import "MPFileCheck.h"
#import "MPScript.h"
#include <unistd.h>

#undef  ql_component
#define ql_component lcl_cMPPatchScan

@implementation MPPatchScan

- (BOOL)useDistributedNotification
{
    return useDistributedNotification;
}
- (void)setUseDistributedNotification:(BOOL)flag
{
    useDistributedNotification = flag;
}

#pragma mark -

- (id)init;
{
    MPServerConnection *_srvObj = [[[MPServerConnection alloc] init] autorelease];
	return [self initWithServerConnection:_srvObj];
}

- (id)initWithServerConnection:(MPServerConnection *)aSrvObj
{
    self = [super init];
	if (self) 
    {
        mpServerConnection = aSrvObj;
        [self setUseDistributedNotification:NO];
    }
	return self;
}


-(NSArray *)scanForPatches:(MPSoap *)aSoapObj
{
	NSArray *resultArr = nil;
	NSMutableArray *patchesNeeded = [[NSMutableArray alloc] init];
	NSDictionary *notifyInfo;
	notifyInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"patchesNeeded"];
	
	/*
	 1. Get Scan List
	 2. Scan for patches
	 3. Post patches needed
	 */ 
	
	// 1. Get the list
	NSDictionary *tmpDict;
	NSArray *customPatches;
	customPatches = [self retrieveCustomPatchScanList];
	if ([customPatches count] == 0)
		goto done;
	
	// 2. Scan the host
	NSMutableDictionary *patch;
	BOOL result = NO;
	int i = 0;
	for(i=0;i<[customPatches count];i++) {
		tmpDict = [NSDictionary dictionaryWithDictionary:[customPatches objectAtIndex:i]];
		qlinfo(@"*******************");
		qlinfo(@"Scanning for %@(%@)",[tmpDict objectForKey:@"pname"],[tmpDict objectForKey:@"pversion"]);
		[self sendNotificationTo:@"ScanForNotification" userInfo:tmpDict];
		
		[NSThread sleepForTimeInterval:0.3];
		
		result = [self scanHostForPatch:tmpDict];
		if (result == YES) {
			patch = [[NSMutableDictionary alloc] init];
            @try {
                [patch setObject:[tmpDict objectForKey:@"pname"] forKey:@"patch"];
                [patch setObject:[tmpDict objectForKey:@"pversion"] forKey:@"version"];
                [patch setObject:@"Third" forKey:@"type"];
                [patch setObject:[NSString stringWithFormat:@"%@(%@)",[tmpDict objectForKey:@"pname"],[tmpDict objectForKey:@"pversion"]] forKey:@"description"];
                [patch setObject:@"0" forKey:@"size"];
                [patch setObject:@"Y" forKey:@"recommended"];
                [patch setObject:[tmpDict objectForKey:@"reboot"] forKey:@"restart"];
                [patch setObject:[tmpDict objectForKey:@"puuid"] forKey:@"patch_id"];
                [patch setObject:[tmpDict objectForKey:@"bundleID"] forKey:@"bundleID"];
                [patchesNeeded addObject:patch];
            }
            @catch (NSException *exception) {
                qlerror("%@",exception);
            }
			
			[patch release];
			patch = nil;
		}
	}
	
	// 3. Post patches needed to web service
	MPDataMgr *dataMgr = [[[MPDataMgr alloc] init] autorelease];
	NSString *resXML = [NSString stringWithString:[dataMgr GenXMLForDataMgr:patchesNeeded dbTable:@"client_patches_third" 
															  dbTablePrefix:@"mp_"
															  dbFieldPrefix:@""
															   updateFields:@"cuuid,patch"
																  deleteCol:@"NA"
															 deleteColValue:@""]];
	
	// Encode to base64 and send to web service	
	qldebug(@"Patch scan info to send to web service:\n%@",resXML);
	NSString *xmlBase64String = [[resXML dataUsingEncoding:NSUTF8StringEncoding] encodeBase64WithNewlines:NO];
	NSString *message = [aSoapObj createSOAPMessage:@"ProcessXML" argName:@"encodedXML" argType:@"string" argValue:xmlBase64String];
	NSError *err = nil;
	NSData *soapResult = [aSoapObj invoke:message isBase64:NO error:&err];
	if (err) {
		qlerror(@"%@",[err localizedDescription]);
		goto done;
	}
	
	
	NSString *ws = [[[NSString alloc] initWithData:soapResult encoding:NSUTF8StringEncoding] autorelease];
	
	if ([ws isEqualTo:@"1"] == TRUE || [ws isEqualTo:@"true"] == TRUE) {
		qlinfo(@"Install results posted to webservice.");
	} else {
		qlerror(@"Install results posted to webservice returned false.");
	}
	
	// Notify with completion result
	notifyInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:(int)[patchesNeeded count]] forKey:@"patchesNeeded"];
	
done:
	
	[self sendNotificationTo:@"ScanForNotificationFinished" userInfo:notifyInfo];
	resultArr = [NSArray arrayWithArray:patchesNeeded];
	[patchesNeeded release];
	return resultArr;
}

-(NSArray *)scanForPatches:(MPSoap *)aSoapObj bundleID:(NSString *)aBundleID
{
    NSArray *resultArr = nil;
	NSMutableArray *patchesNeeded = [[NSMutableArray alloc] init];
	NSDictionary *notifyInfo;
	notifyInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"patchesNeeded"];
	
	/*
	 1. Get Scan List
	 2. Scan for patches
	 3. Post patches needed
	 */ 
	
	// 1. Get the list
	NSDictionary *tmpDict;
	NSArray *customPatches;
	customPatches = [self retrieveCustomPatchScanList];
	if ([customPatches count] == 0)
		goto done;
	
	// 2. Scan the host
	NSMutableDictionary *patch;
	BOOL result = NO;
	int i = 0;
    
    qlinfo(@"Patching bundleID: %@",aBundleID);
    
	for(i=0;i<[customPatches count];i++) {
		tmpDict = [NSDictionary dictionaryWithDictionary:[customPatches objectAtIndex:i]];
        if ([tmpDict hasKey:@"bundleID"]) {
            if ([[tmpDict objectForKey:@"bundleID"] isEqualToString:aBundleID] == NO) {
                continue;
            }
        }

		qlinfo(@"*******************");
		qlinfo(@"Scanning for %@(%@)",[tmpDict objectForKey:@"pname"],[tmpDict objectForKey:@"pversion"]);
        
		[NSThread sleepForTimeInterval:0.3];
		result = [self scanHostForPatch:tmpDict];
		if (result == YES) {
			patch = [[NSMutableDictionary alloc] init];
            @try {
                [patch setObject:[tmpDict objectForKey:@"pname"] forKey:@"patch"];
                [patch setObject:[tmpDict objectForKey:@"pversion"] forKey:@"version"];
                [patch setObject:@"Third" forKey:@"type"];
                [patch setObject:[NSString stringWithFormat:@"%@(%@)",[tmpDict objectForKey:@"pname"],[tmpDict objectForKey:@"pversion"]] forKey:@"description"];
                [patch setObject:@"0" forKey:@"size"];
                [patch setObject:@"Y" forKey:@"recommended"];
                [patch setObject:[tmpDict objectForKey:@"reboot"] forKey:@"restart"];
                [patch setObject:[tmpDict objectForKey:@"puuid"] forKey:@"patch_id"];
                [patch setObject:[tmpDict objectForKey:@"bundleID"] forKey:@"bundleID"];
                [patchesNeeded addObject:patch];
            }
            @catch (NSException *exception) {
                qlerror("%@",exception);
            }
			
			[patch release];
			patch = nil;
		}
	}

done:
	resultArr = [NSArray arrayWithArray:patchesNeeded];
	[patchesNeeded release];
	return resultArr;
}

/* Example Dict
 pname = "Microsoft Office 2008";
 puuid = "184D6FF9-0B2A-44AF-8942CA916C5C252A";
 pversion = "12.2.4";
 query =         (
 "OSType@Mac OS X, Mac OS X Server",
 "OSVersion@*",
 "File@EXISTS@/Applications/Microsoft Office 2008/Office/MicrosoftOffice.framework@True;EQ",
 "File@VERSION@/Applications/Microsoft Office 2008/Office/MicrosoftOffice.framework@12.2.4;LT"
 );
 reboot = No;
 */ 

-(BOOL)scanHostForPatch:(NSDictionary *)aPatch
{
	MPOSCheck	*mpos;
	MPBundle	*mpbndl;
	MPFileCheck	*mpfile;
	MPScript	*mpscript;
	
	
	BOOL result = NO;
	int count = 0;
	
	NSArray *queryArray;
	queryArray = [aPatch objectForKey:@"query"];
	
	// Loop vars
	NSArray *qryArr;
	NSString *typeQuery;
	NSString *typeQueryString;
	NSString *typeResult;
	
	qldebug(@"scanHostForPatch: %@",aPatch);
	
	int i = 0;
	for (i=0;i<[queryArray count];i++)
	{	
		qryArr = [[queryArray objectAtIndex:i] componentsSeparatedByString:@"@" escapeString:@"@@"];
		if ([@"OSArch" isEqualToString:[qryArr objectAtIndex:0]]) {
			mpos = [[MPOSCheck alloc] init];
			if ([mpos checkOSArch:[qryArr objectAtIndex:1]]) {
				qlinfo(@"OSArch=TRUE: %@",[qryArr objectAtIndex:1]);
				count++;
			} else {
				qlinfo(@"OSArch=FALSE: %@",[qryArr objectAtIndex:1]);
			}
			[mpos release];	 
		}
		
		if ([@"OSType" isEqualToString:[qryArr objectAtIndex:0]]) {
			mpos = [[MPOSCheck alloc] init];
			if ([mpos checkOSType:[qryArr objectAtIndex:1]]) {
				qlinfo(@"OSType=TRUE: %@",[qryArr objectAtIndex:1]);
				count++;
			} else {
				qlinfo(@"OSType=FALSE: %@",[qryArr objectAtIndex:1]);
			}
			[mpos release];	 
		}
		
		if ([@"OSVersion" isEqualToString:[qryArr objectAtIndex:0]]) {
			mpos = [[MPOSCheck alloc] init];
			if ([mpos checkOSVer:[qryArr objectAtIndex:1]]) {
				qlinfo(@"OSVersion=TRUE: %@",[qryArr objectAtIndex:1]);
				count++;
			} else {
				qlinfo(@"OSVersion=FALSE: %@",[qryArr objectAtIndex:1]);
			}
			[mpos release];	 
		}
		
		if ([@"BundleID" isEqualToString:[qryArr objectAtIndex:0]]) {
			mpbndl = [[MPBundle alloc] init];
			if ([qryArr count] != 4) {
				qlerror(@"Error, not enough args for patch query entry.");
				[mpbndl release];
				goto done;
			}
			
			/*
			 typeQuery		= [qryArr objectAtIndex:1];
			 typeQueryString = [qryArr objectAtIndex:2];
			 typeResult		= [qryArr objectAtIndex:3];
			 */
			
			if ([mpbndl queryBundleID:[qryArr objectAtIndex:2] action:[qryArr objectAtIndex:1] result:[qryArr objectAtIndex:3]]) {
				qlinfo(@"BundleID=TRUE: %@",[qryArr objectAtIndex:1]);
				count++;
			} else {
				qlinfo(@"BundleID=FALSE: %@",[qryArr objectAtIndex:1]);
			}
			[mpbndl release];	 
		}
		
		if ([@"File" isEqualToString:[qryArr objectAtIndex:0]]) {
			mpfile = [[MPFileCheck alloc] init];
			if ([qryArr count] != 4) {
				qlerror(@"Error, not enough args for patch query entry.");
				[mpfile release];
				goto done;	
			}
			
			typeQuery		= [qryArr objectAtIndex:1];
			typeQueryString = [qryArr objectAtIndex:2];
			typeResult		= [qryArr objectAtIndex:3];
			
			if ([mpfile queryFile:typeQueryString action:typeQuery param:typeResult]) {
				qlinfo(@"File=TRUE: %@",[qryArr objectAtIndex:1]);
				count++;
			} else {
				qlinfo(@"File=FALSE: %@",[qryArr objectAtIndex:1]);
			}
			[mpfile release];	 
		}
		
		if ([@"Script" isEqualToString:[qryArr objectAtIndex:0]]) {
			mpscript = [[MPScript alloc] init];
			if ([qryArr count] > 2) {
				qlerror(@"Error, too many args. Sript will not be run.");
				[mpscript release];
				goto done;
			}
			
			if ([mpscript runScript:[qryArr objectAtIndex:1]]) {
				qlinfo(@"SCRIPT=TRUE");
				count++;
			} else {
				qlinfo(@"SCRIPT=FALSE");
			}
			[mpscript release];	 
		}
	}
	
	goto done;
	
done:
	if (count == [queryArray count]) {
		qlinfo(@"Patch needed.");
		result = YES;
	} else {
		qlinfo(@"Patch not needed.");
	}
	
	return result;
}

-(NSArray *)retrieveCustomPatchScanList
{
	NSArray  *patchGroupPatchesArray = NULL;
	NSDictionary *cDefaults = mpServerConnection.mpDefaults;
	MPSoap *mps = [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:@"http://MPWSController.cfc"];
	
	NSString *patchState;
	if ([[cDefaults allKeys] containsObject:@"PatchState"] == YES) {
		patchState = [NSString stringWithString:[cDefaults objectForKey:@"PatchState"]];
	} else {
		patchState = @"Production";
	}
	
	
	NSDictionary *mpsArgs = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"true",@"encode",
							 @"1",@"active",
							 patchState,@"state",
							 nil];
	
	NSString *message = [mps createBasicSOAPMessage:@"GetScanList" argDictionary:mpsArgs];
	NSError *err = nil;
	NSData *result = [mps invoke:message isBase64:YES error:&err];
	if (err) {
		qlerror(@"%@",[err localizedDescription]);
		goto done;
	}
	
	NSString *patchesXML = [[[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding] autorelease];
	qltrace(@"Custom Patch Scan List: %@",patchesXML);	

	NSString *xPathQuery = @"//patches/patch";
	patchGroupPatchesArray = [NSArray arrayWithArray:[self createPatchArrayFromXML:patchesXML xPath:xPathQuery]];
	
done:	
	[mps release];
	return patchGroupPatchesArray;
}

/* Example XML to parse
 
 <?xml version="1.0" encoding="UTF-8"?>
 <root>
 <patches>
 <patch pname="Microsoft Office 2008" puuid="184D6FF9-0B2A-44AF-8942CA916C5C252A" pversion="12.2.4" reboot="No">
 <query id="1">OSType@Mac OS X, Mac OS X Server</query>
 <query id="2">OSVersion@*</query>
 <query id="19">File@EXISTS@/Applications/Microsoft Office 2008/Office/MicrosoftOffice.framework@True;EQ</query>
 <query id="20">File@VERSION@/Applications/Microsoft Office 2008/Office/MicrosoftOffice.framework@12.2.4;LT</query>
 </patch>
 
 */ 

- (NSArray *)createPatchArrayFromXML:(NSString *)xmlText xPath:(NSString *)aXql
{
	NSMutableArray *tmpPatchArr = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpPatch;
	
	NSError *err=nil;
	NSArray *result=nil;
	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithXMLString:xmlText options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) error:&err]; // Removed NSXMLDocumentTidyXML option, messed up scripts
	if (err) {
		qlerror(@"%@:%@ Error reading XML string: %@", [self class], NSStringFromSelector(_cmd), [err localizedDescription]);
		goto done;
	}
	
	result = [NSArray arrayWithArray:[xmlDoc nodesForXPath:aXql error:&err]];
	if (err) {
		qlerror(@"%@:%@ Error in nodesForXPath: %@", [self class], NSStringFromSelector(_cmd), [err localizedDescription]);
		result = nil;
		goto done;
	}
	
	NSXMLElement *x;
	NSArray *objectElements;
	NSMutableArray *tmpQuery;
	int i = 0;
	int y = 0;
	for (i=0;i<[result count];i++)
	{	
        x = [result objectAtIndex:i];	
		tmpPatch = [[NSMutableDictionary alloc] init];
        @try {
            [tmpPatch setObject:[[x attributeForName:@"pname"] stringValue]		forKey:@"pname"];
            [tmpPatch setObject:[[x attributeForName:@"pversion"] stringValue]	forKey:@"pversion"];
            [tmpPatch setObject:[[x attributeForName:@"puuid"] stringValue]		forKey:@"puuid"];
            [tmpPatch setObject:[[x attributeForName:@"reboot"] stringValue]	forKey:@"reboot"];
            [tmpPatch setObject:[[x attributeForName:@"bundleID"] stringValue]	forKey:@"bundleID"];
            
            objectElements = [x elementsForName:@"query"]; //[x nodesForXpath:@"query" error:nil];
            if ([objectElements count] > 0)
            {
                tmpQuery = [[NSMutableArray alloc] init];
                for (y=0;y<[objectElements count];y++)
                    [tmpQuery addObject:[[objectElements objectAtIndex:y] stringValue]];
                [tmpPatch setObject:[NSArray arrayWithArray:tmpQuery] forKey:@"query"];
                [tmpQuery release];
            }
            qltrace(@"Patch Scan Object: %@",tmpPatch);
            [tmpPatchArr addObject:tmpPatch];
        }
        @catch (NSException *exception) {
            qlerror(@"%@",exception);
        }
		[tmpPatch release];
	}
    result = [NSArray arrayWithArray:tmpPatchArr];
	
done:	
	[xmlDoc release];
	[tmpPatchArr release];
	return result;
}

-(void)sendNotificationTo:(NSString *)aName userInfo:(NSDictionary *)aUserInfo
{
	if (useDistributedNotification) {
		qldebug(@"sendNotificationTo(G): %@ with %@",aName,aUserInfo);
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:aName object:nil userInfo:aUserInfo options:NSNotificationPostToAllSessions];        
	} else {
        qldebug(@"sendNotificationTo: %@ with %@",aName,aUserInfo);
		[[NSNotificationCenter defaultCenter] postNotificationName:aName object:nil userInfo:aUserInfo];
	}
}

@end
