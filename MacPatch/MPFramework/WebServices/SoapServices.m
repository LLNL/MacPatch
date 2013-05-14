//
//  SoapServices.m
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

#import "SoapServices.h"

@implementation SoapServices

@synthesize _defaults;
@synthesize _cuuid;

- (id)init
{
    MPServerConnection *_srvObj = [[[MPServerConnection alloc] init] autorelease];
    return [self initWithServerConnection:_srvObj];
}

- (id)initWithServerConnection:(MPServerConnection *)aSrvObj
{
    self = [super init];
    if (self) {
        mpServerConnection = aSrvObj;
        [self set_cuuid:[MPSystemInfo clientUUID]];
        mpSoap      = [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:@"http://MPWSController.cfc"];
        mpDataMgr   = [[MPDataMgr alloc] init];
    }
    
    return self;
}

- (void)dealloc 
{
    [mpSoap release];
    [mpDataMgr release];
    [super dealloc];
}

- (int)postInstallResultsToWebService:(NSString *)aPatch type:(NSString *)aType
{
    int result = 0;
	NSData *soapResult;
	// First we need to post the installed patch
	NSArray *patchInstalledArray;
	patchInstalledArray = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:aPatch,@"patch",aType,@"type",nil]];

	NSString *resXML = [NSString stringWithString:[mpDataMgr GenXMLForDataMgr:patchInstalledArray dbTable:@"installed_patches" 
															  dbTablePrefix:@"mp_"
															  dbFieldPrefix:@""
															   updateFields:@"cuuid,patch"]];
	
	NSString *xmlBase64String = [[resXML dataUsingEncoding: NSASCIIStringEncoding] encodeBase64WithNewlines:NO]; 
	NSString *message = [mpSoap createSOAPMessage:@"ProcessXML" argName:@"encodedXML" argType:@"string" argValue:xmlBase64String];
	
	NSError *err = nil;
	soapResult = [mpSoap invoke:message isBase64:NO error:&err];
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
        return 1;
	}
	NSString *ws1 = [[[NSString alloc] initWithData:soapResult encoding:NSUTF8StringEncoding] autorelease];
	
	// Now we need to update the client patch tables and remove the entry.
	// datamgr can not do this since it's a different table
	NSDictionary *soapMsgData = [NSDictionary dictionaryWithObjectsAndKeys:aPatch,@"patch",aType,@"type",_cuuid,@"cuuid",nil];
	message = [mpSoap createBasicSOAPMessage:@"UpdateInstalledPatches" argDictionary:soapMsgData];
	
    err = nil;
	soapResult = [mpSoap invoke:message isBase64:NO error:&err];
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
        return 1;
	}
	
    NSString *ws2 = [[[NSString alloc] initWithData:soapResult encoding:NSUTF8StringEncoding] autorelease];

	if ([ws1 isEqualTo:@"1"] == TRUE || [ws1 isEqualTo:@"true"] == TRUE) {
		logit(lcl_vInfo,@"Patch (%@) install result was posted to webservice.",aPatch);
	} else {
		logit(lcl_vError,@"Patch (%@) install result was not posted to webservice.",aPatch);
        result++;
	}
	if ([ws2 isEqualTo:@"0"] == YES  || [ws2 isEqualTo:@"false"] == TRUE) {
		logit(lcl_vError,@"Client patch state for (%@) was not posted to webservice.",aPatch);
        result++;
	}
    
    return result;
}

- (id)postBasicSOAPMessage:(NSString *)aMethod argDictionary:(NSDictionary *)aDict
{
	id result = @"NA";
	NSData *soapResult;
	NSString *message = [mpSoap createBasicSOAPMessage:aMethod argDictionary:aDict];
	
	NSError *err = nil;
	soapResult = [mpSoap invoke:message isBase64:NO error:&err];
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
        return @"NA";
	}

	NSString *sRes = [[[NSString alloc] initWithData:soapResult encoding:NSASCIIStringEncoding] autorelease];
	if (sRes) {
		result = [NSString stringWithString:sRes];
	}
	
	return result;	
}

- (id)postBasicSOAPMessageUsingConvertDictionaryToXML:(NSString *)aMethod argName:(NSString *)aArgName dictToXml:(NSDictionary *)aDictToXML b64Encode:(BOOL)aEnc
{
	NSString *_xml = [mpSoap createBasicXMLFromDictionary:aDictToXML];
	if (aEnc) {
		NSData *_encXMLData = [_xml dataUsingEncoding:NSUTF8StringEncoding];
		_xml = [NSString stringWithString:[_encXMLData encodeBase64WithNewLines:NO]];
	}
	return [self postBasicSOAPMessage:aMethod argDictionary:[NSDictionary dictionaryWithObject:_xml forKey:aArgName]];
}

@end
