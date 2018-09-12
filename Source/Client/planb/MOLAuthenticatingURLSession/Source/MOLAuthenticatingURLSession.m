/// Copyright 2015 Google Inc. All rights reserved.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///    http://www.apache.org/licenses/LICENSE-2.0
///
///    Unless required by applicable law or agreed to in writing, software
///    distributed under the License is distributed on an "AS IS" BASIS,
///    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///    See the License for the specific language governing permissions and
///    limitations under the License.

#import "MOLAuthenticatingURLSession.h"

#import "MOLCertificate.h"
#import "MOLDERDecoder.h"

@interface MOLAuthenticatingURLSession ()
@property NSURLSessionConfiguration *sessionConfig;
@property(copy, nonatomic) NSArray *anchors;
@end

@implementation MOLAuthenticatingURLSession

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
  self = [super init];
  if (self) {
    _sessionConfig = configuration;
  }
  return self;
}

- (instancetype)init {
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  [config setTLSMinimumSupportedProtocol:kTLSProtocol12];
  [config setHTTPShouldUsePipelining:YES];
  return [self initWithSessionConfiguration:config];
}

#pragma mark Session Fetching

- (NSURLSession *)session {
  return [NSURLSession sessionWithConfiguration:self.sessionConfig
                                       delegate:self
                                  delegateQueue:nil];
}

#pragma mark User Agent property

- (NSString *)userAgent {
  return self.sessionConfig.HTTPAdditionalHeaders[@"User-Agent"];
}

- (void)setUserAgent:(NSString *)userAgent {
  NSMutableDictionary *addlHeaders = [self.sessionConfig.HTTPAdditionalHeaders mutableCopy];
  if (!addlHeaders) addlHeaders = [NSMutableDictionary dictionary];
  addlHeaders[@"User-Agent"] = userAgent;
  self.sessionConfig.HTTPAdditionalHeaders = addlHeaders;
}

#pragma mark Server Roots

- (void)setServerRootsPemFile:(NSString *)serverRootsPemFile {
  if (!serverRootsPemFile) return [self setServerRootsPemData:nil];
  NSError *error;
  NSData *rootsData = [NSData dataWithContentsOfFile:serverRootsPemFile
                                             options:0
                                               error:&error];
  if (!rootsData) {
    return [self log:@"Unable to read server root certificate file %@ with error: %@",
            serverRootsPemFile, error.localizedDescription];
  }
  [self setServerRootsPemData:rootsData];
}

- (void)setServerRootsPemData:(NSData *)serverRootsPemData {
  if (!serverRootsPemData) {
    self.anchors = nil;
    return;
  }
  NSString *pemStrings = [[NSString alloc] initWithData:serverRootsPemData
                                               encoding:NSASCIIStringEncoding];
  NSArray *certs = [MOLCertificate certificatesFromPEM:pemStrings];
  if (!certs.count) {
    return [self log:@"Unable to read server root certificates from data %@", serverRootsPemData];
  }
  // Make a new array of the SecCertificateRef's from the MOLCertificate's.
  NSMutableArray *certRefs = [[NSMutableArray alloc] initWithCapacity:certs.count];
  for (MOLCertificate *cert in certs) {
    [certRefs addObject:(id)cert.certRef];
  }
  self.anchors = certRefs;
}

#pragma mark NSURLSessionDelegate methods

- (void)URLSession:(NSURLSession *)session
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                  NSURLCredential *credential))completionHandler {
  NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;

  if (challenge.previousFailureCount > 0) {
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    return;
  }

  if (self.serverHostname && ![self.serverHostname isEqual:protectionSpace.host]) {
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    return;
  }

  if (![protectionSpace.protocol isEqual:NSURLProtectionSpaceHTTPS]) {
    [self log:@"%@ is not a secure protocol", protectionSpace.protocol];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    return;
  }

  if (!protectionSpace.receivesCredentialSecurely) {
    [self log:@"Secure authentication or protocol cannot be established."];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    return;
  }

  NSString *authMethod = [protectionSpace authenticationMethod];

  if (authMethod == NSURLAuthenticationMethodClientCertificate) {
    NSURLCredential *cred = [self clientCredentialForProtectionSpace:protectionSpace];
    if (cred) {
      completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
      return;
    } else {
      [self log:@"Server asked for client authentication but no usable client certificate found."];
      completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
      return;
    }
  } else if (authMethod == NSURLAuthenticationMethodServerTrust) {
    NSURLCredential *cred = [self serverCredentialForProtectionSpace:protectionSpace];
    if (cred) {
      completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
      return;
    } else {
      [self log:@"Unable to verify server identity."];
      completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
      return;
    }
  }

  completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)URLSession:(NSURLSession *)session
                          task:(NSURLSessionTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                    newRequest:(NSURLRequest *)request
             completionHandler:(void (^)(NSURLRequest *))completionHandler {
  if (self.redirectHandlerBlock) {
    completionHandler(self.redirectHandlerBlock(task, response, request));
  } else if (self.refusesRedirects) {
    completionHandler(NULL);
  } else {
    completionHandler(request);
  }
}

- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
  if (self.taskDidCompleteWithErrorBlock) {
    self.taskDidCompleteWithErrorBlock(session, task, error);
  }
}

#pragma mark NSURLSessionDataDelegate methods

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  if (self.dataTaskDidReceiveDataBlock) {
    self.dataTaskDidReceiveDataBlock(session, dataTask, data);
  }
}

#pragma mark Private Helpers for URLSession:didReceiveChallenge:completionHandler:

///
///  Handles the process of locating a valid client certificate for authentication.
///  Operates in one of four modes, depending on the configuration in config.plist
///
///  Mode 1: if syncClientAuthCertificateFile is set, use the identity in the pkcs file
///  Mode 2: if syncClientAuthCertificateCn is set, look for an identity in the keychain with a
///          matching common name and return it.
///  Mode 3: if syncClientAuthCertificateIssuer is set, look for an identity in the keychain with a
///          matching issuer common name and return it.
///  Mode 4: use the list of issuer details sent down by the server to find an identity in the
///          keychain.
///
///  If a valid identity cannot be found, returns nil.
///
- (NSURLCredential *)clientCredentialForProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
  __block SecIdentityRef foundIdentity = NULL;

  if (self.clientCertFile) {
    foundIdentity = [self identityFromFile:self.clientCertFile password:self.clientCertPassword];
  } else {
    CFArrayRef cfResults = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef) @{
      (id)kSecClass : (id)kSecClassCertificate,
      (id)kSecReturnRef : @YES,
      (id)kSecMatchLimit : (id)kSecMatchLimitAll
    }, (CFTypeRef *)&cfResults);
    NSArray *results = CFBridgingRelease(cfResults);

    NSMutableArray *allCerts = [[MOLCertificate certificatesFromArray:results] mutableCopy];

    if (self.clientCertCommonName) {
      foundIdentity = [self identityByFilteringArray:allCerts
                                          commonName:self.clientCertCommonName
                                    issuerCommonName:nil
                                   issuerCountryName:nil
                                       issuerOrgName:nil
                                       issuerOrgUnit:nil];
    } else if (self.clientCertIssuerCn) {
      foundIdentity = [self identityByFilteringArray:allCerts
                                          commonName:nil
                                    issuerCommonName:self.clientCertIssuerCn
                                   issuerCountryName:nil
                                       issuerOrgName:nil
                                       issuerOrgUnit:nil];
    } else {
      for (NSData *allowedIssuer in protectionSpace.distinguishedNames) {
        MOLDERDecoder *decoder = [[MOLDERDecoder alloc] initWithData:allowedIssuer];

        if (!decoder) {
          continue;
        }

        foundIdentity = [self identityByFilteringArray:allCerts
                                            commonName:nil
                                      issuerCommonName:decoder.commonName
                                     issuerCountryName:decoder.countryName
                                         issuerOrgName:decoder.organizationName
                                         issuerOrgUnit:decoder.organizationalUnit];
        if (foundIdentity) break;
      }
    }
  }

  if (foundIdentity) {
    SecCertificateRef certificate = NULL;
    SecIdentityCopyCertificate(foundIdentity, &certificate);
    MOLCertificate *clientCert = [[MOLCertificate alloc] initWithSecCertificateRef:certificate];
    if (certificate) CFRelease(certificate);
    if (clientCert) [self log:@"Client Trust: %@", clientCert];
    NSURLCredential *cred =
        [NSURLCredential credentialWithIdentity:foundIdentity
                                   certificates:nil
                                    persistence:NSURLCredentialPersistenceForSession];
    if (foundIdentity) CFRelease(foundIdentity);
    return cred;
  } else {
    return nil;
  }
}

///
///  Handles the process of evaluating the server's certificate chain.
///  Operates in one of three modes, depending on the configuration in config.plist
///
///  Mode 1: if syncServerAuthRootsData is set, evaluates the server's certificate chain contains
///          one of the certificates in the PEM data in the config plist.
///  Mode 2: if syncServerAuthRootsFile is set, evaluates the server's certificate chain contains
///          one of the certificates in the PEM data in the file specified.
///  Mode 3: evaluates the server's certificate chain is trusted by the keychain.
///
///  If the server's certificate chain does not evaluate for any reason, returns nil.
///
- (NSURLCredential *)serverCredentialForProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
  if (protectionSpace.serverTrust == NULL) {
    [self log:@"Server Trust: No server trust information available"];
    return nil;
  }

  OSStatus err = errSecSuccess;

  if (self.anchors) {
    // Set the anchors to be used during evaluation
    err = SecTrustSetAnchorCertificates(protectionSpace.serverTrust,
                                        (__bridge CFArrayRef)self.anchors);
    if (err != errSecSuccess) {
      [self log:@"Server Trust: Could not set anchor certificates: %d", err];
      return nil;
    }
  }

  // Print details about the server's leaf certificate.
  SecCertificateRef firstCert = SecTrustGetCertificateAtIndex(protectionSpace.serverTrust, 0);
  if (firstCert) {
    MOLCertificate *cert = [[MOLCertificate alloc] initWithSecCertificateRef:firstCert];
    [self log:@"Server Trust: %@", cert];
  }

  // Evaluate the server's cert chain.
  SecTrustResultType result = kSecTrustResultInvalid;
  err = SecTrustEvaluate(protectionSpace.serverTrust, &result);
  if (err != errSecSuccess) {
    [self log:@"Server Trust: Unable to evaluate certificate chain for server: %d", err];
    return nil;
  }

  // Having a trust level "unspecified" by the user is the usual result, described at
  // https://developer.apple.com/library/mac/qa/qa1360
  if (result != kSecTrustResultProceed && result != kSecTrustResultUnspecified) {
    [self log:@"Server Trust: Server isn't trusted. SecTrustResultType: %d", result];
    return nil;
  }

  // Create and return the credential
  return [NSURLCredential credentialForTrust:protectionSpace.serverTrust];
}

/**
  Given an array of MOLCertificate objects and some properties, filter the array
  repeatedly until an identity is found that fulfills the signing chain.
 */
- (SecIdentityRef)identityByFilteringArray:(NSArray *)array
                                commonName:(NSString *)commonName
                          issuerCommonName:(NSString *)issuerCommonName
                         issuerCountryName:(NSString *)issuerCountryName
                             issuerOrgName:(NSString *)issuerOrgName
                             issuerOrgUnit:(NSString *)issuerOrgUnit {
  NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:4];

  if (commonName) {
    [predicates addObject:[NSPredicate predicateWithFormat:@"SELF.commonName == %@",
                                                           commonName]];
  }
  if (issuerCommonName) {
    [predicates addObject:[NSPredicate predicateWithFormat:@"SELF.issuerCommonName == %@",
                                                           issuerCommonName]];
  }
  if (issuerCountryName) {
    [predicates addObject:[NSPredicate predicateWithFormat:@"SELF.issuerCountryName == %@",
                                                           issuerCountryName]];
  }
  if (issuerOrgName) {
    [predicates addObject:[NSPredicate predicateWithFormat:@"SELF.issuerOrgName == %@",
                                                           issuerOrgName]];
  }
  if (issuerOrgUnit) {
    [predicates addObject:[NSPredicate predicateWithFormat:@"SELF.issuerOrgUnit == %@",
                                                           issuerOrgUnit]];
  }

  NSCompoundPredicate *andPreds = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

  NSArray *filteredCerts = [array filteredArrayUsingPredicate:andPreds];
  if (!filteredCerts.count) return NULL;

  for (MOLCertificate *cert in filteredCerts) {
    SecIdentityRef identityRef = NULL;
    OSStatus status = SecIdentityCreateWithCertificate(NULL, cert.certRef, &identityRef);
    if (status == errSecSuccess) {
      return identityRef;
    } else {
      // Avoid infinite recursion from self-signed certs
      if ((cert.commonName && [cert.commonName isEqual:cert.issuerCommonName]) &&
          (cert.countryName && [cert.countryName isEqual:cert.issuerCountryName]) &&
          (cert.orgName && [cert.orgName isEqual:cert.issuerOrgName]) &&
          (cert.orgUnit && [cert.orgUnit isEqual:cert.issuerOrgUnit])) {
        continue;
      }

      return [self identityByFilteringArray:array
                                 commonName:nil
                           issuerCommonName:cert.commonName
                          issuerCountryName:cert.countryName
                              issuerOrgName:cert.orgName
                              issuerOrgUnit:cert.orgUnit];
    }
  }
  return NULL;
}

- (SecIdentityRef)identityFromFile:(NSString *)file password:(NSString *)password {
  NSError *error;
  NSData *data = [NSData dataWithContentsOfFile:file options:0 error:&error];
  if (error) {
    [self log:@"Client Trust: Couldn't open client certificate %@: %@",
        self.clientCertFile, [error localizedDescription]];
    return nil;
  }

  NSDictionary *options = (password ? @{(__bridge id)kSecImportExportPassphrase : password} : @{});
  CFArrayRef cfIdentities;
  OSStatus err = SecPKCS12Import(
      (__bridge CFDataRef)data, (__bridge CFDictionaryRef)options, &cfIdentities);
  NSArray *identities = CFBridgingRelease(cfIdentities);

  if (err != errSecSuccess) {
    [self log:@"Client Trust: Couldn't load client certificate %@: %d", self.clientCertFile, err];
    return nil;
  }

  return (__bridge SecIdentityRef)[identities firstObject][(__bridge id)kSecImportItemIdentity];
}

- (void)log:(NSString *)format, ... {
  if (self.loggingBlock) {
    va_list args;
    va_start(args, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    self.loggingBlock(line);
  }
}

@end
