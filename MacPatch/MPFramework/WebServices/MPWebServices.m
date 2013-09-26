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



#define WS_BASE_URI     @"/Services/MPWSClient.cfc"



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

-(id)initWithDefaults:(NSDictionary *)aDefaults
{
	self = [super init];
	if (self)
    {
        [self set_cuuid:[MPSystemInfo clientUUID]];
        [self set_osver:[[MPSystemInfo osVersionOctets] objectForKey:@"minor"]];
        [self set_defaults:aDefaults];
	}
    return self;
}

- (NSDictionary *)getCatalogURLSForHostOS:(NSError **)err
{
	NSDictionary *jsonResult = nil;
	
	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=getAsusCatalogs&clientID=%@&osminor=%@",WS_BASE_URI,self._cuuid,self._osver];
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

- (NSDictionary *)getPatchGroupContent:(NSError **)err
{
	NSDictionary *jsonResult = nil;
	
	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=GetPatchGroupPatches&PatchGroup=%@",WS_BASE_URI,[_defaults objectForKey:@"PatchGroup"]];
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

#define appleScanResults    0
#define customScanResults   1

- (BOOL)postPatchScanResultsForType:(NSInteger)aPatchScanType results:(NSDictionary *)resultsDictionary error:(NSError **)err
{
    NSString            *scanType   = @"NA";
	BOOL                result      = NO;
	NSDictionary        *jsonResult = nil;

	// Create the JSON String
	NSError *l_err = nil;
	NSString *jData = [resultsDictionary JSONStringWithOptions:JKSerializeOptionEscapeUnicode error:&l_err];
	if (l_err) {
		qlerror(@"%@",[l_err localizedDescription]);
		goto done;
	}

    // Set the Scan Type
    switch ((int)aPatchScanType) {
        case appleScanResults:
            scanType = @"apple";
            break;
        case customScanResults:
            scanType = @"third";
            break;
        default:
            break;
    }

    // Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=PostPatchesFound&ClientID=%@&type=%@&jsonData=%@",WS_BASE_URI,_cuuid,scanType,jData];
	qldebug(@"JSON URL: %@",urlString);

    NSString        *requestData;
    NSDictionary    *userInfoDict;
    NSError         *error = nil;
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

- (BOOL)postPatchInstallResultsToWebService:(NSString *)aPatch patchType:(NSString *)aPatchType error:(NSError **)err
{
	BOOL                result      = NO;
	NSDictionary        *jsonResult = nil;

    // Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=PostInstalledPatch&ClientID=%@&patch=%@&patchType=%@",WS_BASE_URI,_cuuid,aPatch,aPatchType];
	qldebug(@"JSON URL: %@",urlString);

    NSString        *requestData;
    NSDictionary    *userInfoDict;
    NSError         *error = nil;
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

- (NSArray *)getCustomPatchScanList:(NSError **)err
{
    NSArray *jsonResult = nil;
    
    NSString *patchState;
	if ([[_defaults allKeys] containsObject:@"PatchState"] == YES) {
		patchState = [NSString stringWithString:[_defaults objectForKey:@"PatchState"]];
	} else {
		patchState = @"Production";
	}

	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=GetScanList&clientID=%@&state=%@",WS_BASE_URI,_cuuid,patchState];
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
        jsonResult = [deserializedData objectForKey:@"result"];
        if ([[deserializedData objectForKey:@"errorCode"] intValue] != 0) {
            if (err != NULL) {
                userInfoDict = [NSDictionary dictionaryWithObject:[deserializedData objectForKey:@"errorMessage"] forKey:NSLocalizedDescriptionKey];
                *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[[deserializedData objectForKey:@"errorCode"] intValue] userInfo:userInfoDict];
            } else {
                qlerror(@"Error[%@]: %@",[deserializedData objectForKey:@"errorCode"],[deserializedData objectForKey:@"errorMessage"]);
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
	return jsonResult;
}

- (BOOL)postClientAVData:(NSDictionary *)aDict error:(NSError **)err
{
    BOOL         result = NO;
    NSError      *error = nil;
    NSDictionary *userInfoDict = nil;
    NSDictionary *deserializedData = nil;

    // Create Post Args
    NSDictionary *postArgs = [NSDictionary dictionaryWithObjectsAndKeys:_cuuid, @"clientID", @"SAV", @"avAgent",[aDict JSONString], @"jsonData", nil];

    // Send the request
    error = nil;
    deserializedData = [self sendRequestUsingMethodAndArgs:@"PostClientAVData"
                                            argsDictionary:postArgs
                                                     error:&error];

	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
        }
		return result;
	}

    // Have data to parse
    @try {
        if ([[deserializedData objectForKey:@"errorno"] isEqualToString:@"0"]) {
            qlinfo(@"SAV Client Data was posted to webservice.");
            result = YES;
        } else {
            qlerror(@"SAV Client Data was not posted to webservice.");
            userInfoDict = [NSDictionary dictionaryWithObject:[deserializedData objectForKey:@"errormsg"] forKey:NSLocalizedDescriptionKey];
            if (err != NULL) {
                *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
            } else {
                qlerror(@"%@",[deserializedData objectForKey:@"errormsg"]);
            }
        }
    }
    @catch (NSException *exception)
    {
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
        qlerror(@"%@",exception);
    }

	return result;
}

- (NSString *)getLatestAVDefsDate:(NSError **)err
{
    // Get Host Arch Type
    NSString *_theArch = @"x86";
	if ([[MPSystemInfo hostArchitectureType] isEqualToString:@"ppc"]) {
		_theArch = @"ppc";
	}

	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=GetAVDefsDate&clientID=%@&avAgent=SAV&theArch=%@",WS_BASE_URI,_cuuid,_theArch];
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
		return @"NA";
	}

	NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        return [deserializedData objectForKey:@"result"];
    }
    @catch (NSException *exception) {
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
        qlerror(@"%@",exception);
        return @"NA";
    }

	return @"NA";
}

- (NSString *)getAvUpdateURL:(NSError **)err
{
    // Get Host Arch Type
    NSString *_theArch = @"x86";
	if ([[MPSystemInfo hostArchitectureType] isEqualToString:@"ppc"]) {
		_theArch = @"ppc";
	}

	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=GetAVDefsFile&clientID=%@&avAgent=SAV&theArch=%@",WS_BASE_URI,_cuuid,_theArch];
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
		return @"NA";
	}

	NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        return [deserializedData objectForKey:@"result"];
    }
    @catch (NSException *exception) {
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
        qlerror(@"%@",exception);
        return @"NA";
    }
    
	return @"NA";
}

- (NSDictionary *)getAgentUpdates:(NSString *)curAppVersion build:(NSString *)curBuildVersion error:(NSError **)err
{
    NSString            *requestData;
	NSDictionary        *jsonResult = nil;

    // Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=GetAgentUpdates&clientID=%@&agentVersion=%@&agentBuild=%@",WS_BASE_URI,_cuuid,curAppVersion,curBuildVersion];
	qldebug(@"JSON URL: %@",urlString);

    NSDictionary *userInfoDict;
    NSError *error = nil;
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
		return nil;
	}

    NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        if ([[jsonResult objectForKey:@"errorCode"] intValue] == 0)
        {
			return [deserializedData objectForKey:@"result"];
		} else {
            if (err != NULL)
            {
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
    
	return nil;
}

- (NSDictionary *)getAgentUpdaterUpdates:(NSString *)curAppVersion error:(NSError **)err
{
    NSString            *requestData;
	NSDictionary        *jsonResult = nil;

    // Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=GetAgentUpdaterUpdates&clientID=%@&agentUp2DateVer=%@",WS_BASE_URI,_cuuid,curAppVersion];
	qldebug(@"JSON URL: %@",urlString);

    NSDictionary *userInfoDict;
    NSError *error = nil;
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
		return nil;
	}

    NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        if ([[jsonResult objectForKey:@"errorCode"] intValue] == 0)
        {
			return [deserializedData objectForKey:@"result"];
		} else {
            if (err != NULL)
            {
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

	return nil;
}

- (BOOL)postDataMgrXML:(NSString *)aDataMgrXML error:(NSError **)err
{
    BOOL result = NO;

	// Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=PostDataMgrXML",WS_BASE_URI];
	qldebug(@"JSON URL: %@",urlString);

	// Make request
    NSDictionary    *userInfoDict;
    NSError         *error = nil;
    NSString        *requestData;
    if (asiNet) {
        [asiNet release], asiNet = nil;
    }
	asiNet = [[MPASINet alloc] init];
    requestData =  [asiNet synchronousRequestForURLWithFormData:urlString
                                                          form:[NSDictionary dictionaryWithObjectsAndKeys:_cuuid,@"clientID",aDataMgrXML,@"encodedXML", nil]
                                                         error:&error];

    if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
        }
		return result;
	}

	NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        if ([[deserializedData objectForKey:@"errorCode"] intValue] == 0) {
			result = YES;
		} else {
            result = NO;
            if (err != NULL)
            {
                userInfoDict = [NSDictionary dictionaryWithObject:[deserializedData objectForKey:@"errorMessage"] forKey:NSLocalizedDescriptionKey];
                *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[[deserializedData objectForKey:@"errorCode"] intValue] userInfo:userInfoDict];
            } else {
                qlerror(@"Error[%@]: %@",[deserializedData objectForKey:@"errorCode"],[deserializedData objectForKey:@"errorMessage"]);
            }
		}
    }
    @catch (NSException *exception)
    {
        result = NO;
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",exception);
        }
    }

    return result;
}

- (BOOL)postSAVDefsDataXML:(NSString *)aAVXML encoded:(BOOL)aEncoded error:(NSError **)err
{
    BOOL result = NO;

	// Create JSON Request URL
    NSString *urlString = [NSString stringWithFormat:@"%@?method=PostSavAVDefs",WS_BASE_URI];
	qldebug(@"JSON URL: %@",urlString);

	// Make request
    NSDictionary    *userInfoDict;
    NSError         *error = nil;
    NSString        *requestData;
    if (asiNet) {
        [asiNet release], asiNet = nil;
    }
    asiNet = [[MPASINet alloc] initWithDefaults:_defaults];
    requestData =  [asiNet synchronousRequestForURLWithFormData:urlString
                                                           form:[NSDictionary dictionaryWithObjectsAndKeys:aAVXML,@"xml",aEncoded ? @"true" : @"false",@"encoded", nil]
                                                          error:&error];

    if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
        }
		return result;
	}

	NSDictionary *deserializedData;
    @try {
        deserializedData = [requestData objectFromJSONString];
        if ([[deserializedData objectForKey:@"errorCode"] intValue] == 0) {
			result = YES;
		} else {
            result = NO;
            if (err != NULL)
            {
                userInfoDict = [NSDictionary dictionaryWithObject:[deserializedData objectForKey:@"errorMessage"] forKey:NSLocalizedDescriptionKey];
                *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[[deserializedData objectForKey:@"errorCode"] intValue] userInfo:userInfoDict];
            } else {
                qlerror(@"Error[%@]: %@",[deserializedData objectForKey:@"errorCode"],[deserializedData objectForKey:@"errorMessage"]);
            }
		}
    }
    @catch (NSException *exception)
    {
        result = NO;
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",exception);
        }
    }

    return result;
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

- (NSDictionary *)sendRequestUsingMethodAndArgs:(NSString *)aMethod argsDictionary:(NSDictionary *)aDict error:(NSError **)err
{
    NSError *error = nil;
    NSString *requestData = nil;
    NSDictionary *userInfoDict = nil;

    // Create Default Return Value
    NSArray *keys = [NSArray arrayWithObjects:@"errorno",@"errormsg",@"result", nil];
    NSArray *vals = [NSArray arrayWithObjects:@"-1",@"",@"", nil];
    NSDictionary *defaultResults = [NSDictionary dictionaryWithObjects:vals forKeys:keys];
    NSMutableDictionary *results;
    results = [[[NSMutableDictionary alloc] initWithDictionary:defaultResults] autorelease];

    // If ASINet is nil, allocate
    if (!asiNet) {
        asiNet = [[MPASINet alloc] init];
    }

    // Make Request
    requestData = [asiNet synchronousRequestForURLWithFormData:[NSString stringWithFormat:@"%@?method=%@",WS_BASE_URI,aMethod] form:aDict error:&error];
    if (error) {
        qlerror(@"%@",[error localizedDescription]);
        if (err != NULL) {
            *err = error;
        }
		return results;
	}

    // Parse Request Data
    NSDictionary *deserializedData = nil;
    @try {
        deserializedData = [requestData objectFromJSONString];
        if ([deserializedData objectForKey:@"errorno"]) {
            if ([[deserializedData objectForKey:@"errorno"] isEqualTo:@"0"])
            {
                // If results return code is 0, then populate results
                results = [NSDictionary dictionaryWithDictionary:deserializedData];
            } else {
                // Return code is not 0, set results value and generate error
                [results setObject:[deserializedData objectForKey:@"errorno"] forKey:@"errorno"];
                [results setObject:[deserializedData objectForKey:@"errormsg"] forKey:@"errormsg"];

                userInfoDict = [NSDictionary dictionaryWithObject:[deserializedData objectForKey:@"errormsg"] forKey:NSLocalizedDescriptionKey];
                if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[[deserializedData objectForKey:@"errorno"] integerValue] userInfo:userInfoDict];

                return results;
            }
        }
    }
    @catch (NSException *exception) {
        userInfoDict = [NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:1 userInfo:userInfoDict];
        qlerror(@"%@",exception);
        return results;
    }

    return results;
}

@end
