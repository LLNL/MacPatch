//
//  MPKeychain.h
//  MPLibrary
//
//  Created by Heizer, Charles on 8/14/14.
//
//

#import <Foundation/Foundation.h>

@interface MPKeychain : NSObject
{
    SecKeychainRef keychainItem;
    NSString *accessLabel;
    NSError *error;
}

@property (nonatomic, strong) NSString *accessLabel;
@property (nonatomic, strong) NSError *error;

- (id)initWithKeychainFile:(NSString *)aKeychain;
- (id)initWithKeychainFile:(NSString *)aKeychain accessLabel:(NSString *)aAccessLabel;

// Set SecItems
- (OSStatus)addPassword:(NSString *)aPassword username:(NSString *)aUserName serviceName:(NSString *)aServiceName;
- (OSStatus)addPasswordItemToKeychain:(NSString *)aPassword username:(NSString *)aUserName serviceName:(NSString *)aServiceName;
- (OSStatus)addP12CertificateToKeychain:(NSString *)aCertPath certPassword:(NSString *)aPassword;

- (OSStatus)addCAToSystemKeychain:(NSData *)aCACert;

// Get SecItems
- (NSString *)passwordForGenericService:(NSString*)service forAccount:(NSString*)account;

// Misc
- (OSStatus)lockKeychain;
@end
