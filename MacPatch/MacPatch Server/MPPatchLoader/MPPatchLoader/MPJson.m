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
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"
#import "MPManager.h"
#import "lcl.h"

#define SWUAD_PLIST			@"/Library/Preferences/gov.llnl.swuad.plist"
#define ASUS_PLIST			@"/Library/Preferences/com.apple.SoftwareUpdate.plist"
#define WSURLPATH			@"Services/index.cfm"


@implementation MPJson
@synthesize l_jsonURL;

-(id)init
{	
	if (self == [super init]) {
		sm = [MPManager sharedManager];
		[self buildJsonURL];
	}
    return self;
}

-(id)initWithJSONURL:(NSString *)aJsonURL
{	
	if (self == [super init]) {
		[self setL_jsonURL:aJsonURL];
		sm = [MPManager sharedManager];
	}
    return self;
}

-(void)buildJsonURL
{
	NSString *prefix = @"http";
	if ([[[sm g_Defaults] objectForKey:@"MPServerUseSSL"] boolValue] == YES) {
		prefix = @"https";
	}
	[self setL_jsonURL:[NSString stringWithFormat:@"%@://%@:%@/%@",prefix,[[sm g_Defaults] objectForKey:@"MPServerAddress"],[[sm g_Defaults] objectForKey:@"MPServerPort"],WSURLPATH]];
	logit(lcl_vDebug,@"JSON URL: %@",l_jsonURL);
}

- (void)dealloc
{	
    [super dealloc];
}

#pragma mark -
#pragma mark JSON Methods

- (BOOL)postJSONData:(NSString *)aMethod wsArgs:(NSDictionary *)aArgs error:(NSError **)err
{
	// Create http request
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:l_jsonURL]];
	[request setValidatesSecureCertificate:NO];
	[request startSynchronous];
	
	return NO;
}

- (BOOL)postJSONDataForMethod:(NSString *)aMethod data:(id)aData error:(NSError **)err
{
	return [self postJSONDataForMethodWithExtraKeyAndValue:aMethod key:NULL value:NULL data:aData error:err];
}

- (BOOL)postJSONDataForMethodWithExtraKeyAndValue:(NSString *)aMethod key:(NSString *)aKey value:(NSString *)aVal data:(id)aData error:(NSError **)err
{
	BOOL jPostResult = NO;
	NSDictionary *jPostResultDict = nil;
	
	NSMutableArray		*resultsData	= [[[NSMutableArray alloc] init] autorelease];
	NSMutableDictionary *resultDict		= [[[NSMutableDictionary alloc] init] autorelease];
	NSArray				*xCols = nil;
	// Get Data As Array
	if ([aData isKindOfClass:[NSDictionary class]]) {
		[resultsData addObject:[aData allValues]];
		xCols = [NSArray arrayWithArray:[aData allKeys]];
	}
	if ([aData isKindOfClass:[NSArray class]]) {
		if ([[aData objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
			xCols = [NSArray arrayWithArray:[[aData objectAtIndex:0] allKeys]];
			for (id row in aData) {
				if ([row isKindOfClass:[NSDictionary class]]) {
					[resultsData addObject:[row allValues]];
				}
			}
		} else {
			[resultsData addObjectsFromArray:aData];
		}
	}
	logit(lcl_vDebug,@"Data Array For JSON Serilization:\n%@",resultsData);
	
	// Create final Dictionary to gen JSON data for...
	if (aKey != NULL)
		[resultDict setObject:aVal forKey:aKey];
	
	[resultDict setObject:xCols forKey:@"COLUMNS"];
	[resultDict setObject:resultsData forKey:@"DATA"];

	// Create the JSON String
	NSError *l_err = nil;
	NSString *jData = [resultDict JSONStringWithOptions:JKSerializeOptionNone error:&l_err];
	logit(lcl_vDebug,@"JSON Data: %@",jData);
	
	if (l_err) {
		logit(lcl_vError,@"%@ %@",[l_err localizedDescription],[l_err localizedFailureReason]);
		goto done;	
	}
	NSString *jDataSigned = @"NA";
	//[jData writeToFile:@"/private/tmp/JSON105.txt" atomically:NO];
	logit(lcl_vError,@"[request][URL]: %@",l_jsonURL);
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:l_jsonURL]];
    [request setTimeOutSeconds:300];
	[request setUserAgent:@"MacPatchAgent"];
	[request setPostValue:aMethod forKey:@"method"];
	[request setPostValue:@"json" forKey:@"type"];
	[request setPostValue:jData forKey:@"data"];
	[request setPostValue:jDataSigned forKey:@"signature"];
	[request setValidatesSecureCertificate:NO];	
	[request startSynchronous];
	
	//NSData *requestData;
	//requestData = [request rawResponseData];
	
	NSString *requestString;
	requestString = [request responseString];
	if ([request responseStatusCode] != 200) {
		logit(lcl_vError,@"[request][returnCode]: %d",[request responseStatusCode]);
		logit(lcl_vError,@"[request][returnString]: %@",requestString);
	}
	
	NSDictionary *userInfoDict;
	NSError *error = [request error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.agent" code:[error code]  userInfo:userInfoDict];
		logit(lcl_vError,@"%@",[error localizedDescription]);
		goto done;
	}
	
	//if (requestData) {
	if (requestString) {
		error = nil;
		JSONDecoder *jkDecoder = [JSONDecoder decoder];
		//jPostResultDict = [jkDecoder objectWithData:requestData error:&error];
		jPostResultDict = [jkDecoder objectWithData:[requestString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
		if (error) {
			userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
			if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp.agent" code:[error code]  userInfo:userInfoDict];
			logit(lcl_vError,@"%@",[error localizedDescription]);
			goto done;
		}	
		if ([[jPostResultDict objectForKey:@"errorCode"] intValue] == 0) {
			jPostResult = YES;
		} else {
			jPostResult = NO;
			logit(lcl_vError,@"Error[%@]: %@",[jPostResultDict objectForKey:@"errorCode"],[jPostResultDict objectForKey:@"errorMessage"]);
		}
	}
	
done:
	return jPostResult;	
}


@end
