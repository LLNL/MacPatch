//
//  MPNetRequest.m
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

#import "MPNetRequest.h"
#import "MPNetServer.h"
#import "Reachability.h"
#import "MPNetReach.h"

#define URI             @"/Service/MPClientService.cfc"
#define URL_TIMEOUT     5.0 // Does not, need to be longer

#undef  ql_component
#define ql_component lcl_cMPNetRequest

OSStatus extractIdentityAndTrust(CFDataRef inPKCS12Data, SecIdentityRef *outIdentity, SecTrustRef *outTrust, CFStringRef keyPassword);

@interface NSString (MPNetRequestAdditions)
- (NSString *)urlEncodeString;
- (NSString *)urlDecodeString;
@end

@implementation NSString (MPNetRequestAdditions)

- (NSString *)urlEncodeString
{
    CFStringRef encodedCFString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                          (__bridge CFStringRef) self,
                                                                          nil,CFSTR("?!@#$^&%*+,:;='\"`<>()[]{}/\\| "), kCFStringEncodingUTF8);

    NSString *encodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString *)encodedCFString];

    if(!encodedString) {
        encodedString = @"";
    }
    return encodedString;
}

- (NSString *)urlDecodeString
{
    CFStringRef decodedCFString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,(__bridge CFStringRef) self,CFSTR(""),kCFStringEncodingUTF8);
    // We need to replace "+" with " " because the CF method above doesn't do it
    NSString *decodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString *)decodedCFString];
    return (!decodedString) ? @"" : [decodedString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
}

@end

@interface MPNetRequest()

@property (nonatomic, assign, readwrite) BOOL useController;
@property (nonatomic, assign, readwrite) int errorCode;

@property (nonatomic, assign) BOOL isRunnng;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) BOOL connectionDidFinishLoading;
@property (nonatomic, assign) SecTrustRef serverTrust;
@property (nonatomic, assign) BOOL useUnTrustedCert;

@property (nonatomic, assign, readwrite) BOOL isFileDownload;
@property (nonatomic, strong, readwrite) NSString *dlFilePath;

- (int)networkIsReachable:(NSError **)error;
- (int)testAndSetServerBasedOnReachability:(NSError **)error;

@end

@implementation MPNetRequest
{
    NSMutableData *webData;
    NSFileHandle *handleFile;
    NSString *dlFilePath;
}

@synthesize useController;
@synthesize errorCode;

@synthesize mpServer;
@synthesize mpServerArray;
@synthesize httpMethod;
@synthesize method;
@synthesize apiArgs;
@synthesize apiURI;

@synthesize isFileDownload = _isFileDownload;
@synthesize dlFilePath = _dlFilePath;

// User Auth
@synthesize userName;
@synthesize userPass;
// TLS Auth
@synthesize tlsCert;
@synthesize tlsCertPass;

- (id)initWithMPServer:(MPNetServer *)aServer
{
    mpServerArray = [NSArray arrayWithObject:aServer];
    return [self initWithMPServerArray:mpServerArray];
}

- (id)initWithMPServerArray:(NSArray *)aServerArray
{
    self = [super init];

    if (self)
    {
        self.httpMethod = @"POST";
        self.apiURI = URI;
        self.condition = [[NSCondition alloc] init];
        self.connection = nil;
        self.connectionDidFinishLoading = NO;
        self.error = nil;
        self.response = nil;
        self.responseData = [NSData data];
        self.useUnTrustedCert = NO;
        self.mpServerArray = aServerArray;
        self.useController = NO;
    }

    return self;
}

- (id)initWithMPServerAndController:(id <MPNetRequestController>)cont server:(MPNetServer *)aServer
{
    mpServerArray = [NSArray arrayWithObject:aServer];
    return [self initWithMPServerArrayAndController:cont servers:mpServerArray];
}

- (id)initWithMPServerArrayAndController:(id <MPNetRequestController>)cont servers:(NSArray *)aServerArray
{
    self = [super init];

    if (self)
    {
        controller = cont;
        isRunning = NO;
        errorCode = -1;
        
        self.httpMethod = @"POST";
        self.apiURI = URI;
        self.condition = [[NSCondition alloc] init];
        self.connection = nil;
        self.connectionDidFinishLoading = NO;
        self.error = nil;
        self.response = nil;
        self.responseData = [NSData data];
        self.useUnTrustedCert = NO;
        self.mpServerArray = aServerArray;
        self.useController = YES;
    }

    return self;
}

- (int)networkIsReachable:(NSError **)error
{
    NSDictionary *eInfo;
    Reachability *internetReachable = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    if (internetStatus == NotReachable)
    {
        qlerror(@"The internet is down.");
        eInfo = [NSDictionary dictionaryWithObject:@"The internet connection is down." forKey:NSLocalizedDescriptionKey];
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:1001  userInfo:eInfo];
        }
        return 1001;
    }

    // Set the Server Info
    if ([mpServerArray count] >= 1) {
        self.mpServer = nil;
        self.mpServer = [mpServerArray objectAtIndex:0];
    }
    
    return 0;
}

- (int)testAndSetServerBasedOnReachability:(NSError **)error
{
    NSDictionary *eInfo;
    Reachability *internetReachable = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    if (internetStatus == NotReachable)
    {
        qlerror(@"The internet is down.");
        eInfo = [NSDictionary dictionaryWithObject:@"The internet connection is down." forKey:NSLocalizedDescriptionKey];
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:1001  userInfo:eInfo];
        }
        return 1001;
    }

    int res = -1;
    if (mpServerArray)
    {
        self.mpServer = nil;
        for (MPNetServer *s in mpServerArray)
        {
            qlinfo(@"%@ is reachable.",s.host);
            self.mpServer = s;
            res = 1000;
            break;
        }
    }

    return res;
}

- (NSURLRequest *)buildRequestForWebServiceMethod:(NSString *)wsMethodName formData:(NSDictionary *)paramDict error:(NSError **)error
{
    NSError *netErr = nil;
    [self networkIsReachable:&netErr];
    if (netErr) {
        if (error) {
            NSDictionary *eInfo = [NSDictionary dictionaryWithObject:netErr.localizedDescription forKey:NSLocalizedDescriptionKey];
            if (error != NULL) {
                *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:netErr.code  userInfo:eInfo];
            }
        }
        return nil;
    }

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *theURL = [NSString stringWithFormat:@"%@://%@:%d%@?method=%@",(mpServer.useHTTPS ? @"https" : @"http"),mpServer.host,(int)mpServer.port,URI,[wsMethodName urlEncodeString]];
    qldebug(@"%@",theURL);
    [request setURL:[NSURL URLWithString:theURL]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:URL_TIMEOUT];
    [request setHTTPMethod:self.httpMethod];

    NSString *boundary = @"MP_BOUNDARY_STRING";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];

    NSMutableData *bodyData = [NSMutableData data];
    NSArray *keyArray = [paramDict allKeys];
    for (int i=0; i < [keyArray count]; i++)
    {
        [bodyData appendData: [[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData: [[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
                                [keyArray objectAtIndex:i],
                                [paramDict valueForKey:[keyArray objectAtIndex:i]]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [bodyData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *bodyDataStr = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    qldebug(@"%@",bodyDataStr);

    [request setHTTPBody:bodyData];
    return request;
}

- (NSURLRequest *)buildGetRequestForWebServiceMethod:(NSString *)wsMethodName formData:(NSDictionary *)paramDict error:(NSError **)error
{
    NSError *netErr = nil;
    [self networkIsReachable:&netErr];
    if (netErr) {
        if (error) {
            NSDictionary *eInfo = [NSDictionary dictionaryWithObject:netErr.localizedDescription forKey:NSLocalizedDescriptionKey];
            if (error != NULL) {
                *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:netErr.code  userInfo:eInfo];
            }
        }
        return nil;
    }

    NSMutableString *theURL = [[NSMutableString alloc] init];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];

    [theURL appendFormat:@"%@://%@:%d%@?method=%@",(mpServer.useHTTPS ? @"https" : @"http"),mpServer.host,(int)mpServer.port,URI,[wsMethodName urlEncodeString]];

    for (NSString *key in [paramDict allKeys])
    {
        if ([[paramDict objectForKey:key] isKindOfClass:[NSString class]]) {
            [theURL appendFormat:@"&%@=%@",[key urlEncodeString],[[paramDict objectForKey:key] urlEncode]];
        } else {
            [theURL appendFormat:@"&%@=%@",[key urlEncodeString],[paramDict objectForKey:key]];
        }

    }
    qldebug(@"%@",theURL);
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:URL_TIMEOUT];
    [request setURL:[NSURL URLWithString:(NSString *)theURL]];
    [request setHTTPMethod:@"GET"];
    return request;
}

- (NSURLRequest *)buildDownloadRequest:(NSString *)url
{
    NSError *netErr = nil;
    [self networkIsReachable:&netErr];
    if (netErr) {
        qlerror(@"%@",netErr.localizedDescription);
        return nil;
    }
    // Downloads use http only
    NSString *theURL = [NSString stringWithFormat:@"http://%@%@",mpServer.host,url];

    _dlFilePath = [self createTempDirFromURL:theURL];
    qldebug(@"buildDownloadRequest url: %@",theURL);
    qldebug(@"buildDownloadRequest tempFilePath: %@",_dlFilePath);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:URL_TIMEOUT];
    [request setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    [request setURL:[NSURL URLWithString:(NSString *)theURL]];
    return request;
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    self.isFileDownload = NO;
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[[NSOperationQueue alloc] init]];
    [self.connection start];

    if (useController) {
        [controller downloadStarted];
        self.errorCode = 0;
    }

    [self waitForDidFinishLoading];
    if (self.error != nil) {
        if (response) *response = nil;
        if (error) *error = self.error;
        return nil;
    } else {
        if (response) *response = self.response;
        if (error) *error = nil;
        return self.responseData;
    }
}

- (NSString *)downloadFileRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    self.isFileDownload = YES;
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[[NSOperationQueue alloc] init]];
    [self.connection start];
    [self waitForDidFinishLoading];

    if (useController) {
        [controller downloadStarted];
    }

    if (self.error != nil) {
        if (response) *response = nil;
        if (error) *error = self.error;
        return nil;
    } else {
        if (response) *response = self.response;
        if (error) *error = nil;
        return _dlFilePath;
    }
}

- (void)waitForDidFinishLoading
{
    [self.condition lock];
    while (!self.connectionDidFinishLoading)
    {
        [self.condition wait];
    }
    [self.condition unlock];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    //return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
    return YES;
}

// https://developer.apple.com/library/mac/#documentation/security/conceptual/CertKeyTrustProgGuide/iPhone_Tasks/iPhone_Tasks.html
OSStatus extractIdentityAndTrust(CFDataRef inPKCS12Data, SecIdentityRef *outIdentity, SecTrustRef *outTrust, CFStringRef keyPassword)
{
    OSStatus securityError = errSecSuccess;

    // Not working in 10.6.8
    //const void *keys[] =   { kSecImportExportPassphrase };

    const void *keys[] =   { CFSTR("passphrase") };
    const void *values[] = { keyPassword };
    CFDictionaryRef optionsDictionary = NULL;

    /* Create a dictionary containing the passphrase if one
     was specified.  Otherwise, create an empty dictionary. */
    optionsDictionary = CFDictionaryCreate(NULL, keys, values, (keyPassword ? 1 : 0), NULL, NULL);  // 6

    CFArrayRef items = NULL;
    securityError = SecPKCS12Import(inPKCS12Data, optionsDictionary, &items);                    // 7


    //
    if (securityError == 0) {                                   // 8
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
        const void *tempIdentity = NULL;
        // Not working in 10.6.8
        // tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, CFSTR("identity"));
        CFRetain(tempIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        // Not working in 10.6.8
        // tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, CFSTR("trust"));

        CFRetain(tempTrust);
        *outTrust = (SecTrustRef)tempTrust;
    }

    if (optionsDictionary)
        CFRelease(optionsDictionary);                           // 9
    
    if (items)
        CFRelease(items);
    
    return securityError;
}

/*
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
*/
 

// Code Example Taken & Modified from MKNetworkKit
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (challenge.previousFailureCount == 0)
    {
        if (((challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodDefault) ||
             (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic) ||
             (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest) ||
             (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM)) &&
            (self.userName && self.userPass))
        {

            // for NTLM, we will assume user name to be of the form "domain\\username"
            NSURLCredential *credential = [NSURLCredential credentialWithUser:self.userName
                                                                     password:self.userPass
                                                                  persistence:NSURLCredentialPersistenceForSession];

            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        }
        else if ((challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate) && self.tlsCert)
        {
            NSError *error = nil;
            NSData *certData = [[NSData alloc] initWithContentsOfFile:self.tlsCert options:0 error:&error];

            if (error) {
                qlerror(@"%@",error.localizedDescription);
                [[challenge sender] cancelAuthenticationChallenge:challenge];
                return;
            }

            SecIdentityRef identity;
            SecTrustRef trust;
            OSStatus status = extractIdentityAndTrust((__bridge CFDataRef) certData, &identity, &trust, (__bridge CFStringRef) self.tlsCertPass);
            if(status == errSecSuccess)
            {
                SecCertificateRef certificate;
                SecIdentityCopyCertificate(identity, &certificate);
                const void *certs[] = { certificate };
                CFArrayRef certsArray = CFArrayCreate(NULL, certs, 1, NULL);
                NSArray *certificatesForCredential = (__bridge NSArray *)certsArray;
                NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity certificates:certificatesForCredential persistence:NSURLCredentialPersistencePermanent];
                [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                CFRelease(identity);
                CFRelease(certificate);
                CFRelease(certsArray);
            } else {
                [challenge.sender cancelAuthenticationChallenge:challenge];
            }
        }
        else if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust)
        {

            if(challenge.previousFailureCount < 5) {

                self.serverTrust = challenge.protectionSpace.serverTrust;
                SecTrustResultType result;
                SecTrustEvaluate(self.serverTrust, &result);

                if(result == kSecTrustResultProceed ||
                   result == kSecTrustResultUnspecified || //The cert is valid, but user has not explicitly accepted/denied. Ok to proceed (Ch 15: iOS PTL :Pg 269)
                   result == kSecTrustResultRecoverableTrustFailure //The cert is invalid, but is invalid because of name mismatch. Ok to proceed (Ch 15: iOS PTL :Pg 269)
                   )
                {
                    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
                }
                else if(result == kSecTrustResultConfirm)
                {
                    if( self.mpServer.allowSelfSigned == YES )
                    {
                        // Cert not trusted, but user is OK with that
                        qlerror(@"Certificate is not trusted, but self.shouldContinueWithInvalidCertificate is YES");
                        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
                    } else {
                        qlerror(@"Certificate is not trusted, continuing without credentials. Might result in 401 Unauthorized");
                        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
                    }
                }
                else
                {
                    // invalid or revoked certificate
                    if(self.useUnTrustedCert) {
                        qlerror(@"Certificate is invalid, but useUnTrustedCert is YES");
                        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
                    } else {
                        qlerror(@"Certificate is invalid, continuing without credentials. Might result in 401 Unauthorized");
                        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
                    }
                }
            }
            else
            {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
            }
        }
        else
        {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
    else
    {
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    dlRecievedData = [NSNumber numberWithUnsignedInteger:0];
    dlSize = [NSNumber numberWithLongLong:[response expectedContentLength]];

    self.response = response;
    if (useController) {
        [receivedData setLength:0];
        dlSize = [NSNumber numberWithLongLong:[response expectedContentLength]];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //[receivedData appendData:data];

    if (useController)
    {
        dlRecievedData = [NSNumber numberWithUnsignedInteger:([dlRecievedData floatValue] + [data length])];
        NSNumber *resourceLength = [NSNumber numberWithUnsignedInteger:[dlRecievedData floatValue]];
        NSNumber *progress = [NSNumber numberWithFloat:([resourceLength floatValue] / [dlSize floatValue])];

        [controller appendDownloadProgress:([progress floatValue] * 100)];
		[controller appendDownloadProgressPercent:[NSString stringWithFormat:@"%.0f%%",([progress floatValue] * 100)]];
    }

    if (_isFileDownload) {
        NSFileManager *fileMan = [NSFileManager defaultManager];
        if (![fileMan fileExistsAtPath:_dlFilePath])
        {
            [fileMan createFileAtPath:_dlFilePath contents:nil attributes:nil];
        }

        NSFileHandle *file1 = [NSFileHandle fileHandleForUpdatingAtPath:_dlFilePath];
        [file1 seekToEndOfFile];
        [file1 writeData: data];
        [file1 closeFile];
    } else {
        NSMutableData *mutableResponse = self.responseData.mutableCopy;
        [mutableResponse appendData:data];
        self.responseData = mutableResponse.copy;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (useController) {
        [controller downloadError];
        controller = nil;
        self.errorCode = (int)error.code;
    }

    [self.condition lock];
    self.error = error;
    self.connectionDidFinishLoading = YES;
    [self.condition signal];
    [self.condition unlock];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (useController) {
        [controller downloadFinished];
        controller = nil;
        self.errorCode = 0;
    }

    [self.condition lock];
    self.connectionDidFinishLoading = YES;
    [self.condition signal];
    [self.condition unlock];
}

-(NSString *)createTempDirFromURL:(NSString *)aURL
{
	NSString *tempFilePath;
	NSString *appName = [[NSProcessInfo processInfo] processName];
	NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.XXXXXX",appName]];

	const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	char *tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
	strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
	char *result = mkdtemp(tempDirectoryNameCString);
	if (!result)
	{
        free(tempDirectoryNameCString);
		// handle directory creation failure
		qlerror(@"Error, trying to create tmp directory.");
        return [@"/private/tmp" stringByAppendingPathComponent:appName];
	}

	NSString *tempDirectoryPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(result)];
	free(tempDirectoryNameCString);

	//NSURL *tmpURL = [NSURL URLWithString:aURL];
	tempFilePath = [tempDirectoryPath stringByAppendingPathComponent:[aURL lastPathComponent]];

	return tempFilePath;
}

@end
