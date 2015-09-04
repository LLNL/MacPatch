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
#import "MPDefaults.h"
#import "MPFailedRequests.h"


@interface MPWebServices ()

@property (strong) NSString *_cuuid;
@property (strong) NSString *_osver;
@property (strong) NSDictionary *_defaults;

- (BOOL)isPatchGroupHashValid:(NSError **)err;
- (void)writePatchGroupCacheFileData:(NSString *)aData;

- (NSData *)requestWithMethodAndParams:(NSString *)aMethod params:(NSDictionary *)aParams error:(NSError **)err;
- (NSData *)postRequestWithMethodAndParams:(NSString *)aMethod params:(NSDictionary *)aParams error:(NSError **)err;

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

#pragma mark requests

- (NSData *)requestWithMethodAndParams:(NSString *)aMethod params:(NSDictionary *)aParams error:(NSError **)err
{
    MPNetConfig *mpNetConfig = [[MPNetConfig alloc] init];

    NSError *error = nil;
    NSURLResponse *response;

    MPNetRequest *req;
    NSURLRequest *urlReq;
    NSData *res = nil;
    NSArray *servers = [mpNetConfig servers];
    for (MPNetServer *srv in servers)
    {
        qlinfo(@"Trying Server %@",srv.host);
        req = [[MPNetRequest alloc] initWithMPServer:srv];
        [req setApiURI:WS_CLIENT_FILE];
        error = nil;
        urlReq = [req buildGetRequestForWebServiceMethod:aMethod formData:aParams error:&error];
        if (error) {
            if (err != NULL) {
                *err = error;
            }
            qlerror(@"[%@][%d](%@ %d): %@",srv.host,(int)srv.port,error.domain,(int)error.code,error.localizedDescription);
            continue;
        }
        error = nil;
        if (urlReq)
        {
            res = nil;
            res = [req sendSynchronousRequest:urlReq returningResponse:&response error:&error];
            if (error) {
                if (err != NULL) {
                    *err = error;
                }
                qlerror(@"[%@][%d](%@ %d): %@",srv.host,(int)srv.port,error.domain,(int)error.code,error.localizedDescription);
                continue;
            }
            // Make any previouse error pointers nil, now that we have a valid host/connection
            if (err != NULL) {
                *err = nil;
            }
            break;
        } else {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"NSURLRequest was nil." forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:-1001 userInfo:userInfo];
            qlerror(@"%@",error.localizedDescription);
            if (err != NULL) {
                *err = error;
            }
            continue;
        }
    }

    return res;
}

- (NSData *)postRequestWithMethodAndParams:(NSString *)aMethod params:(NSDictionary *)aParams error:(NSError **)err
{
    MPNetConfig *mpNetConfig = [[MPNetConfig alloc] init];

    NSError *error = nil;
    NSURLResponse *response;

    MPNetRequest *req;
    NSURLRequest *urlReq;
    NSData *res = nil;
    NSArray *servers = [mpNetConfig servers];
    for (MPNetServer *srv in servers)
    {
        qlinfo(@"Trying Server %@",srv.host);
        req = [[MPNetRequest alloc] initWithMPServer:srv];
        [req setApiURI:WS_CLIENT_FILE];
        error = nil;
        urlReq = [req buildRequestForWebServiceMethod:aMethod formData:aParams error:&error];
        if (error) {
            if (err != NULL) {
                *err = error;
            }
            qlerror(@"[%@][%d](%@ %d): %@",srv.host,(int)srv.port,error.domain,(int)error.code,error.localizedDescription);
            continue;
        }
        error = nil;
        if (urlReq)
        {
            res = nil;
            res = [req sendSynchronousRequest:urlReq returningResponse:&response error:&error];
            if (error) {
                if (err != NULL) {
                    *err = error;
                }
                qlerror(@"[%@][%d](%@ %d): %@",srv.host,(int)srv.port,error.domain,(int)error.code,error.localizedDescription);
                continue;
            }
            // Make any previouse error pointers nil, now that we have a valid host/connection
            if (err != NULL) {
                *err = nil;
            }
            break;
        } else {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"NSURLRequest was nil." forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:-1001 userInfo:userInfo];
            qlerror(@"%@",error.localizedDescription);
            if (err != NULL) {
                *err = error;
            }
            continue;
        }
    }

    return res;
}

#pragma mark main methods

- (BOOL)getIsClientAgentRegistered:(NSError **)err
{
    return NO;
}

- (NSDictionary *)getServerPubKey:(NSError **)err
{
    return nil;
}

- (BOOL)getIsValidPubKeyHash:(NSString *)aHash error:(NSError **)err
{
    return NO;
}

- (NSDictionary *)getRegisterAgent:(NSString *)aRegKey hostName:(NSString *)hostName clientKey:(NSString *)clientKey error:(NSError **)err
{
    return nil;
}


- (NSDictionary *)getMPServerList:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:@"1" forKey:@"listID"];
    NSData *res = [self requestWithMethodAndParams:@"getServerList" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (NSDictionary *)getMPServerListVersion:(NSString *)aVersion listid:(NSString *)aListID error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:aListID forKey:@"listID"];
    NSData *res = [self requestWithMethodAndParams:@"getServerListVersion" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (NSDictionary *)getCatalogURLSForHostOS:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:self._osver forKey:@"osminor"];
    NSData *res = [self requestWithMethodAndParams:@"getAsusCatalogs" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (NSDictionary *)getPatchGroupContent:(NSError **)err
{
    MPJsonResult *jres = [[MPJsonResult alloc] init];

	NSDictionary *jsonResult = nil;
    // Check to see if local content is up to date
    NSError *isErr = nil;
    BOOL isValid = [self isPatchGroupHashValid:&isErr];
    if (isValid) {
        NSString *preJData = [self getPatchGroupCacheFileDataForGroup];
        if ([preJData isEqualToString:@"ERROR"] == NO) {
            @try {
                qlinfo(@"Using patch group cache data.");
                jsonResult = [jres deserializeJSONString:preJData error:NULL];
                return jsonResult;
            }
            @catch (NSException *exception) {
                qlerror(@"%@",exception);
            }
        }
    }

    // Request
    NSError *error = nil;
    NSDictionary *param = [NSDictionary dictionaryWithObject:[[_defaults objectForKey:@"PatchGroup"] urlEncode] forKey:@"PatchGroup"];
    NSData *res = [self requestWithMethodAndParams:@"GetPatchGroupPatches" params:param error:&error];

    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    error = nil;
    NSString *jstr = [jres serializeJSONDataAsString:(NSDictionary *)result error:NULL];
    [self writePatchGroupCacheFileData:jstr];
    if (error) {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (BOOL)isPatchGroupHashValid:(NSError **)err
{
    /* Had a problem with the hash, will now use
       revision instead
    */
    return [self isPatchGroupDataCurrent:err];
}

- (BOOL)isPatchGroupDataCurrent:(NSError **)err
{
    /* 
     Switching to isPatchGroupDataCurrent from isPatchGroupHashValid
     NSJSONSerialization was reordering the JSON causing the hash to 
     not match.
    */
    NSDictionary    *PatchGroupCacheFileData;
    NSString        *PatchGroupCacheFile = @"/Library/MacPatch/Client/Data/.gov.llnl.mp.patchgroup.data.plist";
    int             patchGroupRevision = -1;
    /*
     PatchGroup Cache File Layout
     NSDictionary:
        PatchGroupName: Default
        hash: xxxx
        data: ....
        rev: ###
     NSDictionary:
        PatchGroupName: QA
        hash: xxxx
        data: ....
        rev: ###
     */
    if ([[NSFileManager defaultManager] fileExistsAtPath:PatchGroupCacheFile])
    {
        PatchGroupCacheFileData = [NSDictionary dictionaryWithContentsOfFile:PatchGroupCacheFile];
        if (!PatchGroupCacheFileData) {
            return NO;
        } else {
            if ([PatchGroupCacheFileData objectForKey:[_defaults objectForKey:@"PatchGroup"]])
            {
                if ([[PatchGroupCacheFileData objectForKey:[_defaults objectForKey:@"PatchGroup"]] objectForKey:@"rev"]) {
                    patchGroupRevision = (int)[[PatchGroupCacheFileData objectForKey:[_defaults objectForKey:@"PatchGroup"]] objectForKey:@"rev"];
                    qlinfo(@"[isPatchGroupDataCurrent]: Revision = %d",patchGroupRevision);
                }
            }
        }
    }
    if (patchGroupRevision == -1)
    {
        qlinfo(@"Cached data did not contain a revision.");
        return NO;
    }
    
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[[_defaults objectForKey:@"PatchGroup"] urlEncode] forKey:@"PatchGroup"];
    [params setObject:[NSNumber numberWithInt:patchGroupRevision] forKey:@"revision"];
    NSData *res = [self requestWithMethodAndParams:@"GetIsLatestRevisionForPatchGroup" params:(NSDictionary *)params error:&error];
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }
    
    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }
    
    // Has Object
    if ([result objectForKey:@"result"]) {
        if ([[result objectForKey:@"result"] integerValue] == 1) {
            qlinfo(@"Patch group hash is valid.");
            return YES;
        } else {
            qlinfo(@"Patch group hash is not valid.");
            return NO;
        }
    }
    
    // Should not get here
    return NO;
}

- (void)writePatchGroupCacheFileData:(NSString *)jData
{
    /*
     PatchGroup Cache File Layout
     NSDictionary:
     PatchGroupName: Default
     hash: xxxx
     data: ....
     PatchGroupName: QA
     hash: xxxx
     data: ....
     */
    MPCrypto *mpc = [[MPCrypto alloc] init];
    NSMutableDictionary *PatchGroupInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *PatchGroupCacheFileData = [NSMutableDictionary dictionary];
    NSString *PatchGroupCacheFile = @"/Library/MacPatch/Client/Data/.gov.llnl.mp.patchgroup.data.plist";

    if ([[NSFileManager defaultManager] fileExistsAtPath:PatchGroupCacheFile])
    {
        PatchGroupCacheFileData = [NSMutableDictionary dictionaryWithContentsOfFile:PatchGroupCacheFile];
    }
    [jData writeToFile:@"/tmp/fooMD" atomically:NO];
    [PatchGroupInfo setObject:[mpc getHashFromStringForType:jData type:@"MD5"] forKey:@"hash"];
    [PatchGroupInfo setObject:jData forKey:@"data"];
    [PatchGroupInfo setObject:jData forKey:@"version"];
    qlinfo(@"Write patch group hash and data to filesystem.");
    
    [PatchGroupCacheFileData setObject:PatchGroupInfo forKey:[_defaults objectForKey:@"PatchGroup"]];
    [PatchGroupCacheFileData writeToFile:PatchGroupCacheFile atomically:YES];

#if !__has_feature(objc_arc)
    [mpc release];
#endif

}

- (NSString *)getPatchGroupCacheFileDataForGroup
{
    NSString *result = @"ERROR";
    NSDictionary *PatchGroupCacheFileData;
    NSString *PatchGroupCacheFile = [MP_ROOT_CLIENT stringByAppendingPathComponent:@"/Data/.gov.llnl.mp.patchgroup.data.plist"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:PatchGroupCacheFile])
    {
        PatchGroupCacheFileData = [NSMutableDictionary dictionaryWithContentsOfFile:PatchGroupCacheFile];
        if ([PatchGroupCacheFileData objectForKey:[_defaults objectForKey:@"PatchGroup"]]) {
            NSDictionary *pInfo = [PatchGroupCacheFileData objectForKey:[_defaults objectForKey:@"PatchGroup"]];
            if ([pInfo objectForKey:@"data"]) {
                result = [pInfo objectForKey:@"data"];
            }
        }
    }

    return result;
}

#define appleScanResults    0
#define customScanResults   1

- (BOOL)postPatchScanResultsForType:(NSInteger)aPatchScanType results:(NSDictionary *)resultsDictionary error:(NSError **)err
{
	// Create the JSON String
    MPJsonResult *jres = [[MPJsonResult alloc] init];
	NSError *l_err = nil;
	NSString *jData = [jres serializeJSONDataAsString:resultsDictionary error:&l_err];
	if (l_err) {
		qlerror(@"%@",[l_err localizedDescription]);
		return NO;
	}

    // Set the Scan Type
    NSString *scanType = @"NA";
    switch ((int)aPatchScanType) {
        case appleScanResults:
            scanType = @"apple";
            break;
        case customScanResults:
            scanType = @"third";
            break;
        default:
            scanType = @"NA";
            break;
    }

    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"ClientID"];
    [params setObject:scanType forKey:@"type"];
    [params setObject:jData forKey:@"jsonData"];
    NSData *res = [self requestWithMethodAndParams:@"PostPatchesFound" params:(NSDictionary *)params error:&error];
    if (error)
    {
        NSMutableDictionary *errDict = [[NSMutableDictionary alloc] init];
        [errDict setObject:[NSNumber numberWithInteger:aPatchScanType] forKey:@"aPatchScanType"];
        [errDict setObject:resultsDictionary forKey:@"resultsDictionary"];
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"postPatchScanResultsForType" params:errDict errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;

		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    NSDictionary *jResult;
    error = nil;
    jResult = [jres deserializeJSONString:[result objectForKey:@"result"] error:&error];
    if (error) {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    if ([[jResult objectForKey:@"errorCode"] intValue] == 0) {
        qlinfo(@"Data was successfully posted.");
        return YES;
    } else {
        if (err != NULL) {
            NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:[jResult objectForKey:@"errorMessage"] forKey:NSLocalizedDescriptionKey];
            *err = [NSError errorWithDomain:@"gov.llnl.MPWebServices" code:[[jResult objectForKey:@"errorCode"] intValue] userInfo:userInfoDict];
        } else {
            qlerror(@"Error[%@]: %@",[jResult objectForKey:@"errorCode"],[jResult objectForKey:@"errorMessage"]);
        }
        return NO;
    }

    // Should not get here
    return NO;
}

- (BOOL)postPatchInstallResultsToWebService:(NSString *)aPatch patchType:(NSString *)aPatchType error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"ClientID"];
    [params setObject:aPatch forKey:@"patch"];
    [params setObject:aPatchType forKey:@"patchType"];
    NSData *res = [self requestWithMethodAndParams:@"PostInstalledPatch" params:(NSDictionary *)params error:&error];
    if (error)
    {
        NSMutableDictionary *errDict = [[NSMutableDictionary alloc] init];
        [errDict setObject:aPatchType forKey:@"aPatchType"];
        [errDict setObject:aPatch forKey:@"aPatch"];
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"postPatchInstallResultsToWebService" params:errDict errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;

		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    return YES;
}

- (NSArray *)getCustomPatchScanList:(NSError **)err
{
    NSString *patchState;
	if ([[_defaults allKeys] containsObject:@"PatchState"] == YES) {
		patchState = [NSString stringWithString:[_defaults objectForKey:@"PatchState"]];
	} else {
		patchState = @"Production";
	}


    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:patchState forKey:@"state"];
    NSData *res = [self requestWithMethodAndParams:@"GetScanList" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (BOOL)postClientAVData:(NSDictionary *)aDict error:(NSError **)err
{
    MPJsonResult *jres = [[MPJsonResult alloc] init];

    // Request
    NSError *error = nil;
    NSString *jSrlData = [jres serializeJSONDataAsString:aDict error:&error];
    if (error) {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_cuuid, @"clientID", @"SAV", @"avAgent",jSrlData, @"jsonData", nil];
    NSData *res = [self requestWithMethodAndParams:@"PostClientAVData" params:params error:&error];
    if (error)
    {
        NSMutableDictionary *errDict = [[NSMutableDictionary alloc] init];
        [errDict setObject:aDict forKey:@"aDict"];
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"PostClientAVData" params:errDict errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;

		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        qlerror(@"SAV Client Data was not posted to webservice.");
        return NO;
    }

    qlinfo(@"SAV Client Data was posted to webservice.");
    return YES;
}

- (NSString *)getLatestAVDefsDate:(NSError **)err
{
    // Get Host Arch Type
    NSString *_theArch = @"x86";
	if ([[MPSystemInfo hostArchitectureType] isEqualToString:@"ppc"]) {
		_theArch = @"ppc";
	}

    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:@"SAV" forKey:@"avAgent"];
    [params setObject:_theArch forKey:@"theArch"];
    NSData *res = [self requestWithMethodAndParams:@"GetAVDefsDate" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return @"NA";
    }

    return result;
}

- (NSString *)getAvUpdateURL:(NSError **)err
{
    // Get Host Arch Type
    NSString *_theArch = @"x86";
	if ([[MPSystemInfo hostArchitectureType] isEqualToString:@"ppc"]) {
		_theArch = @"ppc";
	}

    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:@"SAV" forKey:@"avAgent"];
    [params setObject:_theArch forKey:@"theArch"];
    NSData *res = [self requestWithMethodAndParams:@"GetAVDefsFile" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return @"NA";
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return @"NA";
    }

    return [result objectForKey:@"result"];
}

- (NSDictionary *)getAgentUpdates:(NSString *)curAppVersion build:(NSString *)curBuildVersion error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:curAppVersion forKey:@"agentVersion"];
    [params setObject:curBuildVersion forKey:@"agentBuild"];
    NSData *res = [self requestWithMethodAndParams:@"GetAgentUpdates" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (NSDictionary *)getAgentUpdaterUpdates:(NSString *)curAppVersion error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:curAppVersion forKey:@"agentUp2DateVer"];
    NSData *res = [self requestWithMethodAndParams:@"GetAgentUpdaterUpdates" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (BOOL)postClientScanDataWithType:(NSArray *)scanData type:(NSInteger)aType error:(NSError **)err
{
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    
    // Request
    NSError *error = nil;
    NSDictionary *pData = [NSDictionary dictionaryWithObjectsAndKeys:scanData, @"rows", nil];
    NSString *jData = [jres serializeJSONDataAsString:pData error:&error];
    if (error) {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }
    
    NSDictionary *params;
    // 1 = Apple, 2 = Third
    if (aType == 0) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:_cuuid, @"clientID", @"1", @"type", jData, @"jsonData", nil];
    } else if ( aType == 1 ) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:_cuuid, @"clientID", @"2", @"type", jData, @"jsonData", nil];
    } else {
        //Err
    }
    
    NSData *res = [self postRequestWithMethodAndParams:@"PostClientScanData" params:params error:&error];
    if (error)
    {
        NSMutableDictionary *errDict = [[NSMutableDictionary alloc] init];
        [errDict setObject:scanData forKey:@"aDict"];
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"PostClientScanData" params:errDict errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;
        
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }
    
    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        qlerror(@"Client Scan Data was not posted to webservice.");
        return NO;
    }
    
    qlinfo(@"Client Scan Data was posted to webservice.");
    return YES;
}

// deprecated as of 2.5 release
- (BOOL)postDataMgrXML:(NSString *)aDataMgrXML error:(NSError **)err __deprecated
{
    qlerror(@"[postDataMgrXML]: has been removed.");
    return NO;
}

- (BOOL)postDataMgrJSON:(NSString *)aDataMgrJSON error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:aDataMgrJSON forKey:@"encodedData"];
    NSData *res = [self postRequestWithMethodAndParams:@"PostDataMgrJSON" params:(NSDictionary *)params error:&error];
    if (error)
    {
        NSMutableDictionary *errDict = [[NSMutableDictionary alloc] init];
        [errDict setObject:aDataMgrJSON forKey:@"aDataMgrJSON"];
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"postDataMgrJSON" params:errDict errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;

		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    qlinfo(@"Data was successfully posted.");
    return YES;
}

- (BOOL)postSAVDefsDataXML:(NSString *)aAVXML encoded:(BOOL)aEncoded error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:aAVXML forKey:@"xml"];
    [params setObject:(aEncoded ? @"true" : @"false") forKey:@"encoded"];
    NSData *res = [self requestWithMethodAndParams:@"PostSavAVDefs" params:(NSDictionary *)params error:&error];
    if (error)
    {
        NSMutableDictionary *errDict = [[NSMutableDictionary alloc] init];
        [errDict setObject:aAVXML forKey:@"aAVXML"];
        [errDict setObject:[NSNumber numberWithBool:aEncoded] forKey:@"aEncoded"];
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"postSAVDefsDataXML" params:errDict errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;

		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    qlinfo(@"Data was successfully posted.");
    return YES;
}

- (BOOL)clientHasInvDataInDB:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    NSData *res = [self requestWithMethodAndParams:@"clientHasInventoryData" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    return [result boolValue];
}

- (int)postClientHasInvData:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    NSData *res = [self requestWithMethodAndParams:@"postClientHasInventoryData" params:(NSDictionary *)params error:&error];
    if (error)
    {
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"postClientHasInvData" params:nil errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;

		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return 1;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return 1;
    }

    qlinfo(@"Data was successfully posted.");
    return 0;
}

- (BOOL)postJSONDataForMethod:(NSString *)aMethod data:(NSDictionary *)aData error:(NSError **)err
{
    MPJsonResult        *jres           = [[MPJsonResult alloc] init];
	NSMutableArray		*resultsData	= [[NSMutableArray alloc] init];
	NSMutableDictionary *resultDict		= [[NSMutableDictionary alloc] init];
	// Get Data As Array
	[resultsData addObject:[aData allValues]];

	// Create final Dictionary to gen JSON data for...
	[resultDict setObject:[aData allKeys] forKey:@"COLUMNS"];
	[resultDict setObject:resultsData forKey:@"DATA"];

	// Create the JSON String
    NSError *l_err = nil;
    NSString *jData = [jres serializeJSONDataAsString:resultDict error:&l_err];
	if (l_err) {
		qlerror(@"%@",[l_err localizedDescription]);
		return NO;
	}

    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:@"json" forKey:@"type"];
    [params setObject:jData forKey:@"data"];
    [params setObject:@"NA" forKey:@"signature"];
    NSData *res = [self requestWithMethodAndParams:aMethod params:(NSDictionary *)params error:&error];
    if (error)
    {
        NSMutableDictionary *errDict = [[NSMutableDictionary alloc] init];
        [errDict setObject:aMethod forKey:@"aMethod"];
        [errDict setObject:aData forKey:@"aData"];
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"postJSONDataForMethod" params:errDict errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;

		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }
    if (!res) {
        return NO;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return NO;
    }

    qlinfo(@"Data was successfully posted.");
    return YES;
}

// Client Status
- (id)GetClientPatchStatusCount:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    NSData *res = [self requestWithMethodAndParams:@"GetClientPatchStatusCount" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (id)GetLastCheckIn:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    NSData *res = [self requestWithMethodAndParams:@"GetLastCheckIn" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    if (!res) {
        qlerror(@"No result for NSURLRequest.");
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

// SWDist
- (id)getSWDistGroups:(NSError **)err
{
    return [self getSWDistGroupsWithState:nil error:err];
}

- (id)getSWDistGroupsWithState:(NSString *)aState error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (aState) {
        [params setObject:aState forKey:@"state"];
    }
    NSData *res = [self requestWithMethodAndParams:@"GetSWDistGroups" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (NSString *)getHashForSWTaskGroup:(NSString *)aGroupName error:(NSError **)err
{
    NSString *resultHash = @"NA";

    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:aGroupName forKey:@"GroupName"];
    NSData *res = [self requestWithMethodAndParams:@"GetSoftwareTasksForGroupHash" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return resultHash;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return resultHash;
    }

    error = nil;
    NSDictionary *jsonResult = [jres deserializeJSONString:[result objectForKey:@"result"] error:&error];
    if (error) {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return resultHash;
    }

    // Does it have the right key?
    if (![jsonResult objectForKey:@"hash"])
    {
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:@"\"hash\" key is missing." forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:1  userInfo:userInfoDict];
        qlerror(@"%@",[userInfoDict objectForKey:NSLocalizedDescriptionKey]);
        return resultHash;
    } else {
        resultHash = [jsonResult objectForKey:@"hash"];
    }

    return resultHash;
}

- (id)getSWTasksForGroup:(NSString *)aGroupName error:(NSError **)err
{
    if (!aGroupName) {
        if (err != NULL) *err = [NSError errorWithDomain:NSCocoaErrorDomain
                                   code:-1000
                               userInfo:[NSDictionary dictionaryWithObject:@"No Group Name Found" forKey:NSLocalizedDescriptionKey]];
        return nil;
    }

    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:aGroupName forKey:@"GroupName"];
    NSData *res = [self requestWithMethodAndParams:@"GetSoftwareTasksForGroup" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

- (int)postSWInstallResults:(NSDictionary *)aParams error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSData *res = [self requestWithMethodAndParams:@"PostSoftwareInstallResults" params:aParams error:&error];
    if (error)
    {
        NSMutableDictionary *errDict = [[NSMutableDictionary alloc] init];
        [errDict setObject:aParams forKey:@"aParams"];
        MPFailedRequests *mpf = [[MPFailedRequests alloc] init];
        [mpf addFailedRequest:@"postSWInstallResults" params:errDict errorNo:error.code errorMsg:error.localizedDescription];
        mpf = nil;

		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return 1;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return 1;
    }

    qlinfo(@"Data was successfully posted.");
    return 0;
}

- (id)getSWTaskForID:(NSString *)aTaskID error:(NSError **)err
{
    if (!aTaskID) {
        if (err != NULL) *err = [NSError errorWithDomain:NSCocoaErrorDomain
                                   code:-1000
                               userInfo:[NSDictionary dictionaryWithObject:@"No TaskID Found" forKey:NSLocalizedDescriptionKey]];
        return nil;
    }

    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:aTaskID forKey:@"TaskID"];
    NSData *res = [self requestWithMethodAndParams:@"GetSoftwareTasksUsingID" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    return result;
}

// Profiles
- (NSArray *)getProfileIDDataForClient:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    NSData *res = [self requestWithMethodAndParams:@"GetProfileIDDataForClient" params:(NSDictionary *)params error:&error];
    if (error)
    {
		if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }

    // Parse Main JSON Result
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnJsonResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }
    
    return result;
}

- (NSString *)getHashForPluginName:(NSString *)pName pluginBunleID:(NSString *)bundleID pluginVersion:(NSString *)pVer error:(NSError **)err
{
    // Request
    NSError *error = nil;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self._cuuid forKey:@"clientID"];
    [params setObject:pName forKey:@"pluginName"];
    [params setObject:bundleID forKey:@"pluginBundle"];
    [params setObject:pVer forKey:@"pluginVersion"];
    NSData *res = [self requestWithMethodAndParams:@"GetPluginHash" params:(NSDictionary *)params error:&error];
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }
    
    // MPJsonResult does all of the error checking on the result
    MPJsonResult *jres = [[MPJsonResult alloc] init];
    [jres setJsonData:res];
    error = nil;
    id result = [jres returnResult:&error];
    qldebug(@"JSON Result: %@",result);
    if (error)
    {
        if (err != NULL) {
            *err = error;
        } else {
            qlerror(@"%@",error.localizedDescription);
        }
        return nil;
    }
    
    return result;
}

@end
