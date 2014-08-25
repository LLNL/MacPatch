//
//  RSACrypto.m
//  MPLibrary
//
//  Created by Heizer, Charles on 8/12/14.
//
//

#import "RSACrypto.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>

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

@interface NSData (B64Encoder)
- (NSString *)b64Encode;
@end

@interface NSString (B64DeCoder)
- (NSData *)b64Decode;
@end

@implementation NSData (B64Encoder)
- (NSString *)b64Encode
{
    NSData *strB64D = [self base64EncodedDataWithOptions:0];
    NSString *strB64 = [[NSString alloc] initWithData:strB64D encoding:NSUTF8StringEncoding];
    return strB64;
}
@end

@implementation NSString (B64DeCoder)
- (NSData *)b64Decode
{
    NSData *b64Data = [[NSData alloc] initWithBase64EncodedString:self options:0];
    return b64Data;
}
@end

@implementation RSACrypto

@synthesize publicKey = _publicKey;
@synthesize privateKey = _privateKey;

- (id)initWithPublicKey:(NSData *)pub
{
    return [self initWithPublicKey:pub privateKey:nil];
}

- (id)initWithPrivateKey:(NSData *)priv
{
    return [self initWithPublicKey:nil privateKey:priv];
}

- (id)initWithPublicKey:(NSData *)pub privateKey:(NSData *)priv
{
	self = [super init];
    if(self)
	{
		if(pub) {
			[self setPublicKey:pub];
        }

		if(priv) {
			[self setPrivateKey:priv];
        }
    }
    return self;
}

- (BOOL)setPublicKeyFromContentsOfFile:(NSString *)aPubKey
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:aPubKey]) {
        return NO;
    }

    NSData *keyData = [NSData dataWithContentsOfFile:aPubKey];
    if (!keyData) {
        return NO;
    }

    [self setPublicKey:keyData];

    return YES;
}

- (BOOL)setPrivateKeyFromContentsOfFile:(NSString *)aPriKey
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:aPriKey]) {
        return NO;
    }

    NSData *keyData = [NSData dataWithContentsOfFile:aPriKey];
    if (!keyData) {
        return NO;
    }

    [self setPrivateKey:keyData];

    return YES;
}

- (NSData *)encrypt:(NSString *)stringToEncrypt
{
    if (!self.publicKey) {
        return nil;
    }
    if (!stringToEncrypt) {
        return nil;
    }

    NSData *data2Enc = [stringToEncrypt dataUsingEncoding:NSUTF8StringEncoding];

    BIO *bio = BIO_new_mem_buf((void *)[self.publicKey bytes], (int)[self.publicKey length]);
    RSA *rsaPublickey = PEM_read_bio_RSA_PUBKEY(bio, NULL, 0, NULL);
    BIO_free(bio);

    if ( !rsaPublickey ) {
        printf("%s\n", ERR_error_string(ERR_get_error(), NULL));
        return nil;
    }

    // Allocate a buffer
    int maxSize = RSA_size(rsaPublickey);
    unsigned char *output = (unsigned char *) malloc(maxSize * sizeof(char));

    // Fill buffer with encrypted data
    int bytes = RSA_public_encrypt((int)[data2Enc length], [data2Enc bytes], output, rsaPublickey, RSA_PKCS1_PADDING);

    // If you want a NSData object back
    NSData *result = [NSData dataWithBytes:output length:bytes];
    return result;
}

- (NSString *)encryptAndReturnEncoded:(NSString *)stringToEncrypt
{
    if (!stringToEncrypt) {
        return nil;
    }
    NSData *result = [self encrypt:stringToEncrypt];
    return [result b64Encode];
}

- (NSString *)decryptData:(NSData *)dataToDecrypt
{
    if (!self.privateKey) {
        return nil;
    }
    if (!dataToDecrypt) {
        return nil;
    }

    RSA *rsaPrivatekey = RSA_new();
    BIO *bio = BIO_new_mem_buf((void*)[self.privateKey bytes], (int)[self.privateKey length]);
    rsaPrivatekey = PEM_read_bio_RSAPrivateKey(bio, &rsaPrivatekey, 0, NULL);
    BIO_free(bio);

    unsigned char *decryptedStr = (unsigned char *) malloc(10000);
    RSA_private_decrypt((int)[dataToDecrypt length], [dataToDecrypt bytes], decryptedStr, rsaPrivatekey, RSA_PKCS1_PADDING);

    NSString *result = [NSString stringWithCString:(const char *)decryptedStr encoding:NSUTF8StringEncoding];
    return result;
}

- (NSString *)decryptB64EncodedData:(NSString *)b64StringToDecrypt
{
    if (!self.privateKey) {
        return nil;
    }
    if (!b64StringToDecrypt) {
        return nil;
    }

    NSData *dataFrm64 = [b64StringToDecrypt b64Decode];
    return [self decryptData:dataFrm64];
}

@end
