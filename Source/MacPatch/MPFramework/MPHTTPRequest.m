//
//  MPHTTPRequest.m
//  MPAgent
//
//  Created by Charles Heizer on 9/15/17.
//  Copyright © 2017 LLNL. All rights reserved.
//

#import "MPHTTPRequest.h"
#import "MacPatch.h"
#import "MPWSResult.h"
#import "STHTTPRequest.h"

#import <CommonCrypto/CommonHMAC.h>

#undef  ql_component
#define ql_component lcl_cMPHTTPRequest

@interface MPHTTPRequest ()
{
    NSFileManager *fm;
}

@property (nonatomic)         BOOL      allowSelfSignedCert;
@property (nonatomic, strong) NSArray   *serverArray;
@property (nonatomic)         NSInteger requestCount;
@property (nonatomic, strong) NSString  *clientKey;

@property (nonatomic, weak, readwrite) NSError *error;

@end

@implementation MPHTTPRequest

@synthesize serverArray;
@synthesize allowSelfSignedCert;
@synthesize clientKey;
@synthesize error;

- (id)init
{
    self = [super init];
    if (self)
    {
        fm = [NSFileManager defaultManager];
        
        self.requestCount = -1;
        self.allowSelfSignedCert = NO;
        
        [self populateServerArray];
        [self setClientKey:@"NA"];
    }
    
    return self;
}

- (id)initWithAgentPlist
{
    self = [super init];
    if (self)
    {
        fm = [NSFileManager defaultManager];
        
        self.requestCount = -1;
        self.allowSelfSignedCert = NO;
        
        [self populateServerArrayUsingAgentPlist];
        [self setClientKey:@"NA"];
    }
    
    return self;
}

- (void)populateServerArray
{
    MPServerList *s = [MPServerList new];
    NSArray *servers = [s getLocalServerArray];
    self.serverArray = [servers copy];
    if (self.serverArray.count <= 0) {
        [self populateServerArrayUsingAgentPlist];
    }
}

- (void)populateServerArrayUsingAgentPlist
{
    NSMutableArray *_servers = [NSMutableArray new];
    
    NSDictionary *agentData = [NSDictionary dictionaryWithContentsOfFile:MP_AGENT_DEPL_PLIST];
    NSDictionary *server = @{@"host": agentData[@"MPServerAddress"], @"port": agentData[@"MPServerPort"], @"serverType": @(1),
                             @"allowSelfSigned": agentData[@"MPServerAllowSelfSigned"], @"useHTTPS": agentData[@"MPServerSSL"]};
    [_servers addObject:server];
    
    NSDictionary *proxy = nil;
    if (agentData[@"MPProxyEnabled"])
    {
        if ([agentData[@"MPProxyEnabled"] integerValue] == 1)
        {
            proxy = @{@"host": agentData[@"MPProxyServerAddress"], @"port": agentData[@"MPProxyServerPort"], @"serverType": @(2),
                      @"allowSelfSigned": agentData[@"MPServerAllowSelfSigned"], @"useHTTPS": agentData[@"MPServerSSL"]};
            [_servers addObject:proxy];
        }
    }
    
    self.serverArray = _servers;
}

- (NSString *)createTempDownloadDir:(NSString *)urlPath
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
    
    tempFilePath = [tempDirectoryPath stringByAppendingPathComponent:[urlPath lastPathComponent]];
    return tempFilePath;
}

#pragma mark - Public ASyncronus Methdos

- (void)runASyncGET:(NSString *)urlPath completion:(void (^)(MPWSResult *result, NSError *error))completion
{
    
    if (self.requestCount == -1) {
        self.requestCount++;
    } else {
        if (self.requestCount >= (self.serverArray.count - 1)) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Error, could not complete request, failed all servers."};
            NSError *err = [NSError errorWithDomain:@"gov.llnl.mphttprequest" code:1001 userInfo:userInfo];
            completion(nil, err);
            return;
        } else {
            self.requestCount++;
        }
    }
    
    self.allowSelfSignedCert = NO;
    MPNetServer *server = [MPNetServer serverObjectWithDictionary:[self.serverArray objectAtIndex:self.requestCount]];
    self.allowSelfSignedCert = server.allowSelfSigned;
    
    NSString *url = [NSString stringWithFormat:@"%@://%@:%d%@",server.useHTTPS ? @"https":@"http", server.host, (int)server.port, urlPath];
    qlinfo(@"URL: %@",url);
    
    __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:url];
    r.allowSelfSignedCert = server.allowSelfSigned;
    
    NSString *ts = [self generateTimeStampForSignature];
    NSString *sg = [self signWSRequest:urlPath timeStamp:ts key:[self readClientKey]];
    [r setHeaderWithName:@"X-API-TS" value:ts];
    [r setHeaderWithName:@"X-API-Signature" value:sg];
    [r setHeaderWithName:@"X-Agent-ID" value:@"MacPatch"];
    
    
    __weak STHTTPRequest *wr = r;
    __block __typeof(self) weakSelf = self;
    
    r.completionDataBlock = ^(NSDictionary *headers, NSData *data)
    {
        __strong STHTTPRequest *sr = wr;
        if(sr == nil) return;
        
        if (sr.responseStatus >= 200 && sr.responseStatus <= 299) {
            completion([[MPWSResult alloc] initWithJSONData:data], nil);
        } else {
            [weakSelf runASyncGET:urlPath completion:(void (^)(MPWSResult *result, NSError *error))completion];
        }
    };
    // Error block
    r.errorBlock = ^(NSError *error)
    {
        [weakSelf runASyncGET:urlPath completion:(void (^)(MPWSResult *result, NSError *error))completion];
    };
    
    [r startAsynchronous];
}

- (void)runASyncPOST:(NSString *)urlPath body:(NSDictionary *)body completion:(void (^)(MPWSResult *result, NSError *error))completion
{
    
    if (self.requestCount == -1) {
        self.requestCount++;
    } else {
        if (self.requestCount >= (self.serverArray.count - 1)) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Error, could not complete request, failed all servers."};
            NSError *err = [NSError errorWithDomain:@"gov.llnl.mphttprequest" code:1001 userInfo:userInfo];
            completion(nil, err);
            return;
        } else {
            self.requestCount++;
        }
    }
    
    self.allowSelfSignedCert = NO;
    MPNetServer *server = [MPNetServer serverObjectWithDictionary:[self.serverArray objectAtIndex:self.requestCount]];
    self.allowSelfSignedCert = server.allowSelfSigned;
    
    NSString *url = [NSString stringWithFormat:@"%@://%@:%d%@",server.useHTTPS ? @"https":@"http", server.host, (int)server.port, urlPath];
    qlinfo(@"URL: %@",url);
    
    __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:url];
    r.allowSelfSignedCert = server.allowSelfSigned;
    r.HTTPMethod = @"POST";
    [r setHeaderWithName:@"content-type" value:@"application/json; charset=utf-8"];
    [r setHeaderWithName:@"Accept" value:@"application/json"];
    [r setHeaderWithName:@"X-Agent-ID" value:@"MacPatch"];
    
    NSError *jerror = nil;
    // Convert body to JSON Data
    NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jerror];
    if (!jerror) {
        r.rawPOSTData = jsonData;
    }
    
    NSString *bodyDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *ts = [self generateTimeStampForSignature];
    NSString *sg = [self signWSRequest:bodyDataStr timeStamp:ts key:[self readClientKey]];
    [r setHeaderWithName:@"X-API-TS" value:ts];
    [r setHeaderWithName:@"X-API-Signature" value:sg];
    
    __weak STHTTPRequest *wr = r;
    __block __typeof(self) weakSelf = self;
    
    r.completionDataBlock = ^(NSDictionary *headers, NSData *data)
    {
        __strong STHTTPRequest *sr = wr;
        if(sr == nil) return;
        
        if (sr.responseStatus >= 200 && sr.responseStatus <= 299) {
            completion([[MPWSResult alloc] initWithJSONData:data], nil);
        } else {
            [weakSelf runASyncPOST:urlPath body:body completion:(void (^)(MPWSResult *result, NSError *error))completion];
        }
    };
    // Error block
    r.errorBlock = ^(NSError *error)
    {
        [weakSelf runASyncPOST:urlPath body:body completion:(void (^)(MPWSResult *result, NSError *error))completion];
    };
    
    [r startAsynchronous];
}

- (void)runDownloadRequest:(NSString *)urlPath downloadDirectory:(NSString *)dlDir
                  progress:(NSProgressIndicator *)progressBar progressPercent:(id)progressPercent
                completion:(void (^)(NSString *fileName, NSString *filePath, NSError *error))completion
{
    // Create Download Directory if it does not exist
    if (![fm fileExistsAtPath:dlDir]) {
        [fm createDirectoryAtPath:dlDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    // Set File name and File path
    __block NSString *flName = [urlPath lastPathComponent];
    __block NSString *flPath = [dlDir stringByAppendingPathComponent:flName];
    
    if (self.requestCount == -1)
    {
        self.requestCount++;
    } else {
        if (self.requestCount >= (self.serverArray.count - 1))
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Error, could not download file, failed all servers."};
            NSError *err = [NSError errorWithDomain:@"gov.llnl.mphttprequest" code:1001 userInfo:userInfo];
            completion(nil, nil, err);
            return;
        } else {
            self.requestCount++;
        }
    }
    
    // Create URL
    self.allowSelfSignedCert = NO;
    MPNetServer *server = [MPNetServer serverObjectWithDictionary:[self.serverArray objectAtIndex:self.requestCount]];
    self.allowSelfSignedCert = server.allowSelfSigned;
    NSString *url = [NSString stringWithFormat:@"%@://%@:%d%@",server.useHTTPS ? @"https":@"http", server.host, (int)server.port, urlPath];
    qlinfo(@"Download URL: %@",url);
    
    __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:url];
    r.allowSelfSignedCert = server.allowSelfSigned;
    [r setHeaderWithName:@"X-Agent-ID" value:@"MacPatch"];
    
    __weak STHTTPRequest *wr = r;
    __block __typeof(self) weakSelf = self;
    
    // Create if does not exist, if exists then delete and create
    if (![fm fileExistsAtPath:flPath])
    {
        [fm createFileAtPath:flPath contents:nil attributes:nil];
    } else {
        [fm removeItemAtPath:flPath error:NULL];
        [fm createFileAtPath:flPath contents:nil attributes:nil];
    }
    
    r.downloadProgressBlock = ^(NSData *dataJustReceived, int64_t totalBytesReceived, int64_t totalBytesExpectedToReceive)
    {
        // Calculate Download Percentage
        // Return as NSProgressIndicator and NSTextField
        float progress = ((float)totalBytesReceived) / totalBytesExpectedToReceive;
        double percentComplete = progress*100.0;
        
        if (progressPercent) {
            [progressPercent setStringValue:[NSString stringWithFormat:@"%d",(int)percentComplete]];
        }
        if (progressBar) {
            [progressBar setDoubleValue:percentComplete];
        }
        
        // Write Streamed Data to file
        NSFileHandle *file1 = [NSFileHandle fileHandleForUpdatingAtPath:flPath];
        [file1 seekToEndOfFile];
        [file1 writeData:dataJustReceived];
        [file1 closeFile];
    };
    
    r.completionDataBlock = ^(NSDictionary *headers, NSData *data)
    {
        __strong STHTTPRequest *sr = wr;
        if(sr == nil) return;
        completion(flName, flPath,  nil);
    };
    // Error block
    r.errorBlock = ^(NSError *error)
    {
        [weakSelf runDownloadRequest:urlPath downloadDirectory:(NSString *)dlDir
                            progress:progressBar progressPercent:progressPercent
                          completion:(void (^)(NSString *fileName, NSString *filePath, NSError *error))completion];
    };
    
    [r startAsynchronous];
}

#pragma mark - Public Syncronus Methdos
- (MPWSResult *)runSyncGET:(NSString *)urlPath
{
    return [self runSyncGET:urlPath body:nil];
}

- (MPWSResult *)runSyncGET:(NSString *)urlPath body:(NSDictionary *)body
{
    MPWSResult *wsResult = nil;
    MPNetServer *server;
    NSString *url;
    
    for (NSDictionary *srvDict in self.serverArray)
    {
        self.allowSelfSignedCert = NO;
        
        server = [MPNetServer serverObjectWithDictionary:srvDict];
        self.allowSelfSignedCert = server.allowSelfSigned;
        
        url = [NSString stringWithFormat:@"%@://%@:%d%@",server.useHTTPS ? @"https":@"http", server.host, (int)server.port, urlPath];
        qlinfo(@"URL: %@",url);
        wsResult = [self syncronusGETWithURL:url body:body];
        if ((int)wsResult.statusCode == 200 || (int)wsResult.statusCode == 201) {
            qldebug(@"WSResult: %@",wsResult.toDictionary);
            break;
        }
    }
    
    return wsResult;
}

- (MPWSResult *)runSyncPOST:(NSString *)urlPath body:(NSDictionary *)body
{
    MPWSResult *wsResult = nil;
    
    MPNetServer *server;
    NSString *url;
    for (NSDictionary *srvDict in self.serverArray)
    {
        self.allowSelfSignedCert = NO;
        server = [MPNetServer serverObjectWithDictionary:srvDict];
        self.allowSelfSignedCert = server.allowSelfSigned;
        
        url = [NSString stringWithFormat:@"%@://%@:%d%@",server.useHTTPS ? @"https":@"http", server.host, (int)server.port, urlPath];
        qldebug(@"[runSyncPOST] URL: %@",url);
        wsResult = [self syncronusPOSTWithURL:url body:body];
        if ((int)wsResult.statusCode == 200 || (int)wsResult.statusCode == 201) {
            qldebug(@"WSResult: %@",wsResult.toDictionary);
            break;
        }
    }
    
    return wsResult;
}

- (NSString *)runSyncFileDownload:(NSString *)urlPath downloadDirectory:(NSString *)dlDir error:(NSError **)err
{
    __block NSString *_fileName;
    __block NSString *_filePath;
    __block NSError *_err;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self runDownloadRequest:urlPath
           downloadDirectory:dlDir
                    progress:nil
             progressPercent:nil
                  completion:^(NSString *fileName, NSString *filePath, NSError *_error)
     {
         if (_error)
         {
             _err = [_error copy];
         }
         else
         {
             _fileName = fileName;
             _filePath = filePath;
         }
         dispatch_semaphore_signal(semaphore);
     }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (err != NULL) {
        if (_err) *err = _err;
    }
    
    return _filePath;
}

#pragma mark - Private Methdos
- (MPWSResult *)syncronusGETWithURL:(NSString *)aURL body:(NSDictionary *)body
{
    __block MPWSResult *res = nil;
    
    // Result
    __block NSInteger statusCode = 9999;
    NSError *_error = nil;
    
    // Convert body to JSON Data
    NSData  *jsonData;
    if (body) {
        jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&_error];
        if (_error) {
            qlerror(@"%@",_error.localizedDescription);
            error = _error;
            return res;
        }
    }
    
    // Create URLRequest
    NSURL *url = [NSURL URLWithString:aURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"MacPatch" forHTTPHeaderField:@"X-Agent-ID"];
    
    NSString *sg;
    NSString *ts = [self generateTimeStampForSignature];
    
    // If Get Request with out a body pass nil for the dictionary
    if (body != nil) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setHTTPBody:jsonData];
        
        NSString *bodyDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        sg = [self signWSRequest:bodyDataStr timeStamp:ts key:[self readClientKey]];
    } else {
        sg = [self signWSRequest:[url path] timeStamp:ts key:[self readClientKey]];
    }
    
    [request setValue:[self generateTimeStampForSignature] forHTTPHeaderField:@"X-API-TS"];
    [request setValue:sg forHTTPHeaderField:@"X-API-Signature"];
    
    // Create session for request
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.timeoutIntervalForRequest = 10;
    sessionConfig.timeoutIntervalForResource = 60;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    __block NSError *sesErr = nil;
    __block NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    
    // Create semaphore, to wait for block to end
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // Make Request Task
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *_error)
                                  {
                                      if (!_error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                          statusCode = httpResponse.statusCode;
                                          res = [[MPWSResult alloc] initWithJSONData:data];
                                          res.statusCode = statusCode;
                                      }
                                      else
                                      {
                                          qlerror(@"Error: %@", _error.localizedDescription);
                                          sesErr = _error;
                                      }
                                      
                                      dispatch_semaphore_signal(semaphore);
                                  }];
    // Run Task
    [task resume];
    
    // Wait for semaphore signal
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (sesErr) {
        error = sesErr;
    }
    
    return res;
}

- (MPWSResult *)syncronusPOSTWithURL:(NSString *)aURL body:(NSDictionary *)body
{
    __block MPWSResult *res = nil;
    
    // Result
    __block NSInteger statusCode = 9999;
    NSError *jerror = nil;
    NSData  *jsonData;
    
    // Create URLRequest
    NSURL *url = [NSURL URLWithString:aURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"MacPatch" forHTTPHeaderField:@"X-Agent-ID"];
    
    // Generate Signture
    NSString *sg;
    NSString *ts = [self generateTimeStampForSignature];
    
    // If Request with out a body pass nil for the dictionary
    if (body != nil)
    {
        // Convert body to JSON Data
        jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jerror];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        if (!jerror)
        {
            [request setHTTPBody:jsonData];
            NSString *bodyDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            sg = [self signWSRequest:bodyDataStr timeStamp:ts key:[self readClientKey]];
        }
    } else {
        sg = [self signWSRequest:[url path] timeStamp:ts key:[self readClientKey]];
    }
    
    [request setValue:[self generateTimeStampForSignature] forHTTPHeaderField:@"X-API-TS"];
    [request setValue:sg forHTTPHeaderField:@"X-API-Signature"];
    
    // Create session for request
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.timeoutIntervalForRequest = 10;
    sessionConfig.timeoutIntervalForResource = 10;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    __block NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                                  delegate:self
                                                             delegateQueue:nil];
    // Create semaphore, to wait for block to end
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // Make Request Task
    NSURLSessionDataTask *task;
    task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *err)
    {
        if (!err)
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            statusCode = httpResponse.statusCode;
            res = [[MPWSResult alloc] initWithJSONData:data];
            res.statusCode = statusCode;
        }
        else
        {
            qlerror(@"Error: %@", err.localizedDescription);
        }

        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run Task
    [task resume];
    // Wait for semaphore signal
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return res;
}

- (NSString *)generateTimeStampForSignature
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:00"];
    NSDate *now = [NSDate date];
    NSString *nsstr = [format stringFromDate:now];
    return nsstr;
}

- (NSString *)signWSRequest:(NSString *)aData timeStamp:(NSString *)aTimeStamp key:(NSString *)aKey
{
    qldebug(@"Key for Signature: (%@)",[aKey substringFromIndex:MAX((int)[aKey length]-4, 0)]);
    qldebug(@"Data for Signature: (%@)",aData);
    qldebug(@"Time Stamp for Signature: (%@)",aTimeStamp);
    
    NSString *aStrToSign = [NSString stringWithFormat:@"%@-%@",aData,aTimeStamp];
    
    qltrace(@"String to Sign: (%@)",aStrToSign);
    
    const char *cKey  = [aKey cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [aStrToSign cStringUsingEncoding:NSUTF8StringEncoding];
    
    if (!cData || !cKey) {
        qlerror(@"Data or key to sign is null.");
        return @"";
    }
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *resData = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    //NSString *resStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
    
    NSString *result = [resData description];
    result = [result stringByReplacingOccurrencesOfString:@" " withString:@""];
    result = [result stringByReplacingOccurrencesOfString:@"<" withString:@""];
    result = [result stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    qldebug(@"Signature for request: %@",result);
    return result;
}

- (NSString *)readClientKey
{
    if ([self.clientKey isEqualToString:@"NA"]) {
        [self setClientKey:[self getClientKeyFromKeychain]];
        return self.clientKey;
    } else {
        return self.clientKey;
    }
    
    return @"NA";
}

- (NSString *)getClientKeyFromKeychain
{
    NSError *err = nil;
    MPSimpleKeychain *skc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_KEYCHAIN_FILE];
    MPKeyItem *keyItem = [skc retrieveKeyItemForService:kMPClientService error:&err];
    if (err) {
        logit(lcl_vWarning,@"getClientKey: %@",err.localizedDescription);
        return @"NA";
    }
    return keyItem.secret;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    // accept self-signed SSL certificates
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        NSURLCredential *credential = nil;
        
        if (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified) {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else if (result == kSecTrustResultConfirm || result == kSecTrustResultRecoverableTrustFailure) {
            if (self.allowSelfSignedCert) {
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            } else {
                
            }
        }
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end
