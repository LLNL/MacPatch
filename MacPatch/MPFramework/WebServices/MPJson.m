//
//  MPJson.m
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

#import "MPJson.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "MPServerConnection.h"
#import "MPASINet.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"
#import "NSDictionary+Helper.h"

#undef  ql_component
#define ql_component            lcl_cMPJson

#define	JSONURI                 @"/Services/index.cfm"

@interface MPJson()

@end

@implementation MPJson

@synthesize useSSL;
@synthesize mpHostIsReachable;
@synthesize l_Host;
@synthesize l_Port;
@synthesize l_jsonURL;
@synthesize l_jsonURLPlain;
@synthesize l_defaults;
@synthesize l_cuuid;

-(id)init
{	
    MPServerConnection *_srvObj = [[[MPServerConnection alloc] init] autorelease]; 
	return [self initWithServerConnection:_srvObj cuuid:[MPSystemInfo clientUUID]];
}

- (id)initWithServerConnection:(MPServerConnection *)aSrvObj cuuid:(NSString *)aCUUID
{
    self = [super init];
	if (self) 
    {
        mpServerConnection = aSrvObj;
        [self setL_defaults:mpServerConnection.mpDefaults];
        [self setL_cuuid:[MPSystemInfo clientUUID]];
        
		// Set the Values
		[self setL_Host:mpServerConnection.HTTP_HOST];
		[self setL_Port:mpServerConnection.HTTP_HOST_PORT];
		[self setMpHostIsReachable:[mpServerConnection.HTTP_HOST_REACHABLE boolValue]];
		[self setL_jsonURL:[NSString stringWithFormat:@"%@%@",mpServerConnection.MP_JSON_URL_PLAIN,JSONURI]];
        [self setL_jsonURLPlain:[NSString stringWithFormat:@"%@/Services",mpServerConnection.MP_JSON_URL_PLAIN]];
    }
    return self;
}

- (void)dealloc
{
    [l_Host autorelease];
    [l_Port autorelease];
    [l_jsonURL autorelease];
    [l_defaults autorelease];
    [l_cuuid autorelease];
	
    [super dealloc];
}

#pragma mark -
#pragma mark JSON Methods

- (NSDictionary *)getCatalogURLSForOS:(NSString *)aOSVer error:(NSError **)err
{
	NSDictionary *jsonResult = nil;
	
	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"/Services/MPWSControllerCocoa.cfc?method=getAsusCatalogs&clientID=%@&osminor=%@",l_cuuid,aOSVer];
    qldebug(@"JSON URL: %@",urlString);
	
	// Make Request
    NSDictionary    *userInfoDict;
    NSError         *error = nil;
    NSString        *requestData;
    if (asiNet) {
        [asiNet release], asiNet = nil;
    }
    asiNet = [[MPASINet alloc] initWithServerConnection:mpServerConnection];
    requestData = [asiNet synchronousRequestForURL:urlString error:&error];
	
	if (error) {
		NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
        }
		goto done;
	}
    
    // Have data to parse
    NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        jsonResult = [[deserializedData objectForKey:@"result"] objectFromJSONString];
    }
    @catch (NSException *exception) {
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:1  userInfo:userInfoDict];
        qlerror(@"%@",exception);
        goto done;
    }
	
done:
	return jsonResult;
}

- (NSDictionary *)downloadPatchGroupContent:(NSError **)err
{
	NSDictionary *jsonResult = nil;
	
	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"/Services/MPWSControllerCocoa.cfc?method=GetPatchGroupPatches&PatchGroup=%@",[l_defaults objectForKey:@"PatchGroup"]];
	qldebug(@"JSON URL: %@",urlString);
	
	// Make Request
    NSDictionary    *userInfoDict;
    NSError         *error = nil;
    NSString        *requestData;
    if (asiNet) {
        [asiNet release], asiNet = nil;
    }
    asiNet = [[MPASINet alloc] initWithServerConnection:mpServerConnection];
    requestData = [asiNet synchronousRequestForURL:urlString error:&error];
    
    if (error) {
		NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
        }
		goto done;
	}
    
    // Have data to parse
    NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        jsonResult = [[deserializedData objectForKey:@"result"] objectFromJSONString];
    }
    @catch (NSException *exception) {
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:1  userInfo:userInfoDict];
        qlerror(@"%@",exception);
        goto done;
    }

done:
	return jsonResult;
}

- (BOOL)postJSONDataForMethod:(NSString *)aMethod data:(NSDictionary *)aData error:(NSError **)err
{
	BOOL jPostResult = NO;
	NSDictionary *jPostResultDict = nil;
	
	NSMutableArray		*resultsData	= [[[NSMutableArray alloc] init] autorelease];
	NSMutableDictionary *resultDict		= [[[NSMutableDictionary alloc] init] autorelease];
	// Get Data As Array
	[resultsData addObject:[aData allValues]];
	
	// Create final Dictionary to gen JSON data for...
	[resultDict setObject:[aData allKeys] forKey:@"COLUMNS"];
	[resultDict setObject:resultsData forKey:@"DATA"];
	
	// Create the JSON String
	NSError *l_err = nil;
	NSString *jData = [resultDict JSONStringWithOptions:JKSerializeOptionEscapeUnicode error:&l_err];
	if (l_err) {
		qlerror(@"%@",[l_err localizedDescription]);
		goto done;	
	}
	NSString *jDataSigned = @"NA";
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:l_jsonURL]];
	qldebug(@"JSON URL:%@",l_jsonURL);
	[request setUserAgent:@"MacPatchAgent"];
	[request setPostValue:aMethod forKey:@"method"];
	[request setPostValue:@"json" forKey:@"type"];
	[request setPostValue:jData forKey:@"data"];
	[request setPostValue:jDataSigned forKey:@"signature"];
	[request setValidatesSecureCertificate:NO];	
	[request setTimeOutSeconds:300];
	[request startSynchronous];
	
	NSString *requestString;
	requestString = [request responseString];
	qldebug(@"POST JSON Result:%@",requestString);
	
	NSDictionary *userInfoDict;
	NSError *error = [request error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:[error code]  userInfo:userInfoDict];
		qlerror(@"%@",[error localizedDescription]);
		qlerror(@"%@",l_jsonURL);
		return FALSE;
	}
	
	if (requestString) {
		error = nil;
		JSONDecoder *jkDecoder = [JSONDecoder decoder];
		jPostResultDict = [jkDecoder objectWithData:[requestString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
		qldebug(@"JSONDecoder Object: %@",jPostResultDict);
		
		if (error) {
			userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
			if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:[error code]  userInfo:userInfoDict];
			qlerror(@"%@",[error localizedDescription]);
			return FALSE;
		}	
		if ([[jPostResultDict objectForKey:@"errorCode"] intValue] == 0) {
			jPostResult = YES;
		} else {
			jPostResult = NO;
			qlerror(@"Error[%@]: %@",[jPostResultDict objectForKey:@"errorCode"],[jPostResultDict objectForKey:@"errorMessage"]);
		}
	}
	
done:
	return jPostResult;	
}


@end
