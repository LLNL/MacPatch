//
//  MPWebServices.m
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

#import "MPWebServices.h"
#import "MPASINet.h"
#import "MPDefaults.h"
#import "JSONKit.h"


@interface MPWebServices ()

@property (retain) NSString *_cuuid;
@property (retain) NSString *_osver;
@property (retain) NSDictionary *_defaults;

@end

#undef  ql_component
#define ql_component lcl_cMPWEBServices

@implementation MPWebServices

@synthesize _cuuid;
@synthesize _osver;
@synthesize _defaults;

-(id)init
{
	self = [super init];
	if (self)
    {
        [self set_cuuid:[MPSystemInfo clientUUID]];
        [self set_osver:[[MPSystemInfo osVersionOctets] objectForKey:@"minor"]];
        
        MPDefaults *d = [[MPDefaults alloc] init];
        [self set_defaults:[d defaults]];
        [d autorelease];
	}
    return self;
}

- (NSDictionary *)getCatalogURLSForHostOS:(NSError **)err
{
	NSDictionary *jsonResult = nil;
	
	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"/MPWSControllerCocoa.cfc?method=getAsusCatalogs&clientID=%@&osminor=%@",self._cuuid,self._osver];
    qldebug(@"JSON URL: %@",urlString);
	
	// Make Request
    NSDictionary    *userInfoDict;
    NSError         *error = nil;
    NSString        *requestData;
    if (asiNet) {
        [asiNet release], asiNet = nil;
    }
    asiNet = [[MPASINet alloc] init];
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
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
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
	NSString *urlString = [NSString stringWithFormat:@"/?method=GetPatchGroupPatches&PatchGroup=%@",[_defaults objectForKey:@"PatchGroup"]];
	qldebug(@"JSON URL: %@",urlString);
	
	// Make request
    NSDictionary    *userInfoDict;
    NSError         *error = nil;
    NSString        *requestData;
    if (asiNet) {
        [asiNet release], asiNet = nil;
    }
	asiNet = [[MPASINet alloc] init];
    requestData = [asiNet synchronousRequestForURL:urlString error:&error];
    
    if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
        }
		goto done;
	}
	
	NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        jsonResult = [[deserializedData objectForKey:@"result"] objectFromJSONString];
    }
    @catch (NSException *exception) {
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
        qlerror(@"%@",exception);
        goto done;
    }
	
done:
	return jsonResult;
}

- (BOOL)postJSONDataForMethod:(NSString *)aURL data:(NSDictionary *)aData error:(NSError **)err
{
    NSString            *requestData;
	BOOL                result      = NO;
	NSDictionary        *jsonResult = nil;
    
	NSMutableDictionary *postFormData   = [[[NSMutableDictionary alloc] init] autorelease];
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
    
    [postFormData setObject:jData forKey:@"data"];
    [postFormData setObject:@"NA" forKey:@"signature"];
    
    NSDictionary *userInfoDict;
    NSError *error = nil;
    if (asiNet) {
        [asiNet release], asiNet = nil;
    }
    asiNet = [[MPASINet alloc] init];
    requestData = [asiNet synchronousRequestForURLWithFormData:aURL form:postFormData error:&error];
    
    if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
        }
		goto done;
	}
    
    NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        jsonResult = [[deserializedData objectForKey:@"result"] objectFromJSONString];
        if ([[jsonResult objectForKey:@"errorCode"] intValue] == 0) {
			result = YES;
		} else {
			result = NO;
            if (err != NULL) {
                userInfoDict = [NSDictionary dictionaryWithObject:[jsonResult objectForKey:@"errorMessage"] forKey:NSLocalizedDescriptionKey];
                *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[[jsonResult objectForKey:@"errorCode"] intValue] userInfo:userInfoDict];
            } else {
                qlerror(@"Error[%@]: %@",[jsonResult objectForKey:@"errorCode"],[jsonResult objectForKey:@"errorMessage"]);
            }
		}
    }
    @catch (NSException *exception) {
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",exception);
        }
    }
   
done:
	return result;
}

@end
