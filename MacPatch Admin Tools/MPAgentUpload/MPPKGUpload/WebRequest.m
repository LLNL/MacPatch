//
//  WebRequest.m
//  MPPKGUpload
//
//  Created by Heizer, Charles on 5/13/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "WebRequest.h"

@interface WebRequest ()

@property (nonatomic, assign, readwrite) BOOL isRunnng;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, assign, readwrite) BOOL connectionDidFinishLoading;

@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSString *host;

@property (nonatomic, assign) SecTrustRef serverTrust;
@property (nonatomic, assign) BOOL useUnTrustedCert;

@end

@implementation WebRequest

@synthesize isRunnng                    = _isRunnng;
@synthesize responseData                = _responseData;
@synthesize error                       = _error;
@synthesize connectionDidFinishLoading  = _connectionDidFinishLoading;
@synthesize encoding                    = _encoding;
@synthesize connection                  = _connection;
@synthesize response                    = _response;
@synthesize receivedData                = _receivedData;
@synthesize condition                   = _condition;
@synthesize serverTrust                 = _serverTrust;
@synthesize useUnTrustedCert            = _useUnTrustedCert;

/*
- (id)initWithURL:(NSURL *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
	return [self initWithNSURLRequest:request];
}

- (id)initWithNSURLRequest:(NSURLRequest *)urlRequest
{
    if (self = [super init])
	{
        self.condition = [[NSCondition alloc] init];
        self.connection = nil;
        self.connectionDidFinishLoading = NO;
        self.error = nil;
        self.responseData = [NSData data];
        self.useUnTrustedCert = NO;

        _connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        [_connection start];
    }
    return self;
}
 */

- (id)init
{
    if (self = [super init])
	{
        self.condition = [[NSCondition alloc] init];
        self.connection = nil;
        self.connectionDidFinishLoading = NO;
        self.error = nil;
        self.responseData = [NSData data];
        self.useUnTrustedCert = NO;
        self.host = @"localhost";
    }
    return self;
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)aResponse error:(NSError **)error
{
    self.host = [[request URL] host];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[[NSOperationQueue alloc] init]];
    [self.connection start];
    [self waitForDidFinishLoading];
    if (self.error != nil) {
        if (aResponse) *aResponse = nil;
        if (error) *error = self.error;
        return nil;
    } else {
        if (aResponse) *aResponse = self.response;
        if (error) *error = nil;
        return self.responseData;
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

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)aError
{
    [self.condition lock];
    self.error = aError;
    self.connectionDidFinishLoading = YES;
    [self.condition signal];
    [self.condition unlock];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.condition lock];

    self.connectionDidFinishLoading = YES;
    _responseData = [_receivedData copy];
    NSString *result = [[NSString alloc] initWithData:_receivedData encoding:_encoding];
	NSLog(@"%@", result);

    [self.condition signal];
    [self.condition unlock];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// every response could mean a redirect
	_receivedData = nil;

	// need to record the received encoding
	// http://stackoverflow.com/questions/1409537/nsdata-to-nsstring-converstion-problem
	CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)[response textEncodingName]);
	_encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!_receivedData)
	{
		_receivedData = [[NSMutableData alloc] initWithData:data];
	}
	else
	{
		[_receivedData appendData:data];
	}
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		// we only trust our own domain
		if ([challenge.protectionSpace.host isEqualToString:self.host])
		{
			NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
		}
	}

	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


@end
