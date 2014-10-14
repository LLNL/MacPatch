//
//  RSACrypto.h
//  MPLibrary
//
//  Created by Heizer, Charles on 8/12/14.
//
//

#import <Foundation/Foundation.h>
#import <openssl/evp.h>
#import <openssl/rand.h>
#import <openssl/rsa.h>
#import <openssl/engine.h>
#import <openssl/sha.h>
#import <openssl/pem.h>
#import <openssl/bio.h>
#import <openssl/err.h>
#import <openssl/ssl.h>
#import <openssl/md5.h>

@interface RSACrypto : NSObject
{
    NSData *publicKey;
	NSData *privateKey;
}

@property (nonatomic, strong) NSData *publicKey;
@property (nonatomic, strong) NSData *privateKey;

- (id)initWithPublicKey:(NSData *)pub;
- (id)initWithPrivateKey:(NSData *)priv;
- (id)initWithPublicKey:(NSData *)pub privateKey:(NSData *)priv;

- (BOOL)setPublicKeyFromContentsOfFile:(NSString *)aPubKey;
- (BOOL)setPrivateKeyFromContentsOfFile:(NSString *)aPriKey;

- (NSData *)encrypt:(NSString *)stringToEncrypt;
- (NSString *)encryptAndReturnEncoded:(NSString *)stringToEncrypt;

- (NSString *)decryptData:(NSData *)dataToDecrypt;
- (NSString *)decryptB64EncodedData:(NSString *)b64StringToDecrypt;

@end
