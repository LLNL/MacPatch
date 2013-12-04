//
//  MPASINet.m
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

#import "MPASINet.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import <Security/Security.h>

@interface MPASINet ()

- (NSString *)startSynchRequest:(NSString *)aURL error:(NSError **)err;
- (NSString *)startSynchronousRequestForURLWithFormData:(NSString *)aURL form:(NSDictionary *)aFormData error:(NSError **)err;

// Client Cert Auth
- (BOOL)authIdentity:(SecIdentityRef *)authIdentity;
- (BOOL)extractIdentity:(SecIdentityRef *)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data;

@end

@implementation MPASINet

@synthesize connectionRetries;
@synthesize connectionTimeOut;
@synthesize validatesSecureCertificate;
@synthesize useClientCertAuth;


- (id)init
{
    MPServerConnection *_srvObj = [[[MPServerConnection alloc] init] autorelease];
    return [self initWithServerConnection:_srvObj];
}

- (id)initWithDefaults:(NSDictionary *)aDefaults
{
    MPServerConnection *_srvObj = [[[MPServerConnection alloc] initWithDefaults:aDefaults] autorelease];
    return [self initWithServerConnection:_srvObj];
}

- (id)initWithServerConnection:(MPServerConnection *)aSrvObj
{
    self = [super init];
	if (self) {
        fm = [NSFileManager defaultManager];
		mpServerConnection = aSrvObj;
        [self setConnectionRetries:5];
        [self setConnectionTimeOut:120];
        [self setValidatesSecureCertificate:NO];
        [self setUseClientCertAuth:NO];
    }
	
    return self;
}

- (id)initWithServerConnectionUsingTLSAuth:(MPServerConnection *)aSrvObj
{
    self = [super init];
	if (self) {
        fm = [NSFileManager defaultManager];
        mpServerConnection = aSrvObj;
        [self setConnectionRetries:5];
        [self setConnectionTimeOut:120];
        [self setValidatesSecureCertificate:NO];
        [self setUseClientCertAuth:YES];
    }
	
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSString *)synchronousRequestForURL:(NSString *)aURI error:(NSError **)err;
{
    int t = 0;
	int	s = 0;
	// Get the patch group patches
    NSDictionary *hostConfig;
	NSString *result = nil;
	NSString *_url;
	NSError *_Err = nil;
    
start:
    // mpHostConfig method will test if main server is reachable and then the proxy
    // if the proxy server is enabled for use.
	hostConfig = [mpServerConnection mpConnection];
    
    // Set the url to connect to based on the correct host info which is being returned
    _url = [NSString stringWithFormat:@"%@://%@:%@%@",[hostConfig objectForKey:@"HTTP_PREFIX"],[hostConfig objectForKey:@"HTTP_HOST"],[hostConfig objectForKey:@"HTTP_HOST_PORT"],aURI];
    qldebug(@"Requesting URL: %@",_url);
    
    // Start the request
    _Err = nil;
    result = [self startSynchRequest:_url error:&_Err];
	if (_Err) {
		qlerror(@"[%@][%@]: %@",[hostConfig objectForKey:@"HTTP_HOST"],[hostConfig objectForKey:@"HTTP_HOST_PORT"],[_Err localizedDescription]);
		if (t < 5) {
			t++;
			srand((unsigned)time(NULL));
			s = 30 + rand() % 300;
			qlerror(@"Trying again in %d seconds.",s);
			sleep(s);
			goto start;
		}
		goto done;
	}
	
	if ([result length] <= 1) {
		qlerror(@"Result was zero length.");
		goto done;
	}
    
done:
    if (_Err) {
        if (err != NULL) {
            NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:[_Err localizedDescription] forKey:NSLocalizedDescriptionKey];
            *err = [NSError errorWithDomain:@"gov.llnl.mp.ASIHTTPRequest" code:[_Err code]  userInfo:userInfoDict];
        }
    }
	return result;
}

- (NSString *)synchronousRequestForURLWithFormData:(NSString *)aURI form:(NSDictionary *)aFormData error:(NSError **)err
{
    int t = 0;
	int	s = 0;
	// Get the patch group patches
    NSDictionary *hostConfig;
	NSString *result = nil;
	NSString *_url;
	NSError *_Err = nil;
    
start:
    // mpHostConfig method will test if main server is reachable and then the proxy
    // if the proxy server is enabled for use.
	hostConfig = [mpServerConnection mpConnection];
    
    // Set the url to connect to based on the correct host info which is being returned
    _url = [NSString stringWithFormat:@"%@://%@:%@%@",[hostConfig objectForKey:@"HTTP_PREFIX"],[hostConfig objectForKey:@"HTTP_HOST"],[hostConfig objectForKey:@"HTTP_HOST_PORT"],aURI];
    qldebug(@"Requesting URL: %@",_url);
    
    // Start the request
    _Err = nil;
    result = [self startSynchronousRequestForURLWithFormData:_url form:aFormData error:&_Err];    
	if (_Err) {
		qlerror(@"[%@][%@]: %@",[hostConfig objectForKey:@"HTTP_HOST"],[hostConfig objectForKey:@"HTTP_HOST_PORT"],[_Err localizedDescription]);
		if (t < 5) {
			t++;
			srand((unsigned)time(NULL));
			s = 30 + rand() % 300;
			qlerror(@"Trying again in %d seconds.",s);
			sleep(s);
			goto start;
		}
		goto done;
	}
	
	if ([result length] <= 1) {
		qlerror(@"Result was zero length.");
		goto done;
	}
    
done:
    if (_Err) {
        if (err != NULL) {
            NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:[_Err localizedDescription] forKey:NSLocalizedDescriptionKey];
            *err = [NSError errorWithDomain:@"gov.llnl.mp.ASIHTTPRequest" code:[_Err code]  userInfo:userInfoDict];
        }
    }
	return result;
}

#pragma mark - Private

- (NSString *)startSynchRequest:(NSString *)aURL error:(NSError **)err
{
    NSDictionary *userInfoDict;
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:aURL]];
    if (self.useClientCertAuth) {
        SecIdentityRef identity = NULL;
        if ([self authIdentity:&identity]) {
            [request setClientCertificateIdentity:identity];
            [request setValidatesSecureCertificate:NO];
        } else {
            userInfoDict = [NSDictionary dictionaryWithObject:@"Get Client Auth Failed." forKey:NSLocalizedDescriptionKey];
            if (err != NULL) {
                *err = [NSError errorWithDomain:@"gov.llnl.mp.ASIHTTPRequest" code:101  userInfo:userInfoDict];
            }
            return nil;
        }
    } else {
        [request setValidatesSecureCertificate:self.validatesSecureCertificate];
    }
	[request setTimeOutSeconds:self.connectionTimeOut];
    [request setShouldAttemptPersistentConnection:NO];
	[request startSynchronous];
	
    NSString *sData = nil;
	NSError *error = [request error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.mp.ASIHTTPRequest" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
        }
		return nil;
	} else {
        sData = [request responseString];
	}
    
    if ([request responseStatusCode] != 200) {
        userInfoDict = [NSDictionary dictionaryWithObject:[request responseStatusMessage] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:[request responseStatusCode]  userInfo:userInfoDict];
            qlerror(@"%@",[request responseStatusMessage]);
            qlerror(@"%@",aURL);
        } else {
            qlerror(@"%@",[request responseStatusMessage]);
            qlerror(@"%@",aURL);
        } 
    }
    
    return sData;
}

- (NSString *)startSynchronousRequestForURLWithFormData:(NSString *)aURL form:(NSDictionary *)aFormData error:(NSError **)err
{
    NSString        *responseString = @"NA";
    NSDictionary    *userInfoDict;
    // Get Method Name from the URL
    NSString *methodName = nil;
    for (NSString *param in [[[NSURL URLWithString:aURL] query] componentsSeparatedByString:@"&"]) {
        NSArray *valKeys = [param componentsSeparatedByString:@"="];
        if([valKeys count] < 2) continue;
        if ([[[valKeys objectAtIndex:0] lowercaseString] isEqualToString:@"method"]) {
            methodName = [valKeys objectAtIndex:1];
            break;
        }
    }
    // If no method name was fround, we need to bail.
    if (!methodName) {
		if (err != NULL) {
            userInfoDict = [NSDictionary dictionaryWithObject:@"Method name was undefined." forKey:NSLocalizedDescriptionKey];
            *err = [NSError errorWithDomain:@"gov.llnl.mp.ASIHTTPRequest" code:1  userInfo:userInfoDict];
        } else {
            qlerror(@"Method name was undefined.");
        }
    }
    
    // Now we need top parse the URL for just the base URL
    NSString *requestURL = [[aURL componentsSeparatedByString:@"?"] objectAtIndex:0];
    
    
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestURL]];
    if (self.useClientCertAuth) {
        SecIdentityRef identity = NULL;
        if ([self authIdentity:&identity]) {
            [request setClientCertificateIdentity:identity];
            [request setValidatesSecureCertificate:NO];
        } else {
            // Error
            goto done;
        }
    } else {
        [request setValidatesSecureCertificate:self.validatesSecureCertificate];
    }
	
	[request setUserAgent:@"MacPatchAgent"];
	[request setPostValue:methodName forKey:@"method"];
    [request setPostValue:@"json" forKey:@"type"];
    for (id item in [aFormData allKeys]) {
        [request setPostValue:[aFormData objectForKey:item] forKey:item];
    }
    [request setShouldAttemptPersistentConnection:NO];
	[request startSynchronous];
	
	responseString = [request responseString];
	qldebug(@"POST Result:%@",responseString);
	
	NSError *error = [request error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
            qlerror(@"%@",aURL);
        }
	}
    
    if ([request responseStatusCode] != 200) {
        userInfoDict = [NSDictionary dictionaryWithObject:[request responseStatusMessage] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:[request responseStatusCode]  userInfo:userInfoDict];
            qlerror(@"%@",[request responseStatusMessage]);
            qlerror(@"%@",aURL);
        } else {
            qlerror(@"%@",[request responseStatusMessage]);
            qlerror(@"%@",aURL);
        }
    }
    
done:
	return responseString;
}

- (NSString *)startSynchronousRequestWithFormData:(NSString *)aBaseURL method:(NSString *)aMethod form:(NSDictionary *)aFormData error:(NSError **)err
{
    NSString        *responseString = @"NA";
    NSDictionary    *userInfoDict;
    // Get Method Name from the URL


    // Now we need top parse the URL for just the base URL
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:aBaseURL]];
    if (self.useClientCertAuth) {
        SecIdentityRef identity = NULL;
        if ([self authIdentity:&identity]) {
            [request setClientCertificateIdentity:identity];
            [request setValidatesSecureCertificate:NO];
        } else {
            // Error
            goto done;
        }
    } else {
        [request setValidatesSecureCertificate:self.validatesSecureCertificate];
    }

	[request setUserAgent:@"MacPatchAgent"];
	[request setPostValue:aMethod forKey:@"method"];
    for (id item in [aFormData allKeys]) {
        [request setPostValue:[aFormData objectForKey:item] forKey:item];
    }
    [request setShouldAttemptPersistentConnection:NO];
	[request startSynchronous];

	responseString = [request responseString];
	qldebug(@"POST Result:%@",responseString);

	NSError *error = [request error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:[error code]  userInfo:userInfoDict];
        } else {
            qlerror(@"%@",[error localizedDescription]);
            qlerror(@"%@",aBaseURL);
        }
	}

    if ([request responseStatusCode] != 200) {
        userInfoDict = [NSDictionary dictionaryWithObject:[request responseStatusMessage] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) {
            *err = [NSError errorWithDomain:@"gov.llnl.mpjson" code:[request responseStatusCode]  userInfo:userInfoDict];
            qlerror(@"%@",[request responseStatusMessage]);
            qlerror(@"%@",aBaseURL);
        } else {
            qlerror(@"%@",[request responseStatusMessage]);
            qlerror(@"%@",aBaseURL);
        }
    }

done:
	return responseString;
}

- (BOOL)authIdentity:(SecIdentityRef *)authIdentity
{
    SecIdentityRef identity = NULL;
    SecTrustRef trust = NULL;
    NSString *p12File = [NSString stringWithFormat:@"%@/.certs/client.p12",MP_ROOT_CLIENT];
    if ([fm fileExistsAtPath:p12File]) {
        NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12File];
        if ([self extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data]) {
            *authIdentity = identity;
            return YES;
        } else {
            return NO;
        }
    } else {
        qlerror(@"Unable to locate client auth certificate.");
        return NO;
    }
}

- (BOOL)extractIdentity:(SecIdentityRef *)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data
{

	OSStatus securityError = errSecSuccess;
#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_7      
	NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[MPSystemInfo clientUUID] forKey:(id)kSecImportExportPassphrase];
#else    
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[MPSystemInfo clientUUID] forKey:@"passphrase"];
#endif    
	CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
	securityError = SecPKCS12Import((CFDataRef)inPKCS12Data,(CFDictionaryRef)optionsDictionary,&items);
    
	if (securityError == 0) { 
		CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
		const void *tempIdentity = NULL;
#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_7            
		tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);
#else        
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, "identity");
#endif        
		*outIdentity = (SecIdentityRef)tempIdentity;
		const void *tempTrust = NULL;
#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_7                    
		tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
#else        
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, "trust");
#endif        
		*outTrust = (SecTrustRef)tempTrust;
	} else {
		qlerror(@"Extracting identity failed with error code %d",(int)securityError);
		return NO;
	}
	return YES;   
}


@end
