//
//  MPKeychain.m
//  MPLibrary
//
//  Created by Heizer, Charles on 8/14/14.
//
//

#import "MPKeychain.h"
#include <stdlib.h>

#define ACCESS_LABEL @"MPClientKeychain"
#define DEFAULT_KEYCHAIN @"/Library/Keychains/.MP.keychain"

@interface MPKeychain ()

- (NSString *)clientUUID;
- (SecAccessRef)createDefaultAccessRef;
- (OSStatus)openKeychainRefFromFile:(NSString *)aKeychainFilePath;

@end

@implementation MPKeychain

@synthesize accessLabel = _accessLabel;
@synthesize error = _error;

- (id)init
{
    return [self initWithKeychainFile:DEFAULT_KEYCHAIN accessLabel:ACCESS_LABEL];
}

- (id)initWithKeychainFile:(NSString *)aKeychain
{
    return [self initWithKeychainFile:aKeychain accessLabel:ACCESS_LABEL];
}

- (id)initWithKeychainFile:(NSString *)aKeychain accessLabel:(NSString *)aAccessLabel
{
    self = [super init];
    if (self)
    {
        self.error = nil;
        OSStatus res = noErr;
        res = [self openKeychainRefFromFile:aKeychain];
        if (noErr != res) {
            CFStringRef errMsg = SecCopyErrorMessageString(res, NULL);
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:(__bridge NSString *)errMsg forKey:NSLocalizedDescriptionKey];
            self.error = [NSError errorWithDomain:@"gov.llnl.mp.keychain" code:-1001 userInfo:userInfo];
            CFRelease(errMsg);
        }
        self.accessLabel = aAccessLabel;
    }
    return self;
}

#pragma mark - Private

- (NSString *)clientUUID
{
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformUUIDKey),kCFAllocatorDefault, 0);
    IOObjectRelease(platformExpert);
    NSString __strong *serialNumber = (__bridge NSString *)(serialNumberAsCFString);
    CFRelease(serialNumberAsCFString);
	return serialNumber;
}

- (SecAccessRef)createDefaultAccessRef
{
    OSStatus err;
    SecAccessRef access=nil;
    NSArray *trustedApplications=nil;

    //Make an exception list of trusted applications; that is,
    // applications that are allowed to access the item without
    // requiring user confirmation:
    SecTrustedApplicationRef myself, MPWorker, MPAgent, MPAgentExec, MPCatalog, MPClientStatus, MPAuthPlugin, SelfPatch;

    //Create trusted application references; see SecTrustedApplications.h:
    err = SecTrustedApplicationCreateFromPath(NULL, &myself);
    err = err ?: SecTrustedApplicationCreateFromPath("/Library/MacPatch/Client/MPWorker", &MPWorker);
    err = err ?: SecTrustedApplicationCreateFromPath("/Library/MacPatch/Client/MPAgent", &MPAgent);
    err = err ?: SecTrustedApplicationCreateFromPath("/Library/MacPatch/Client/MPAgentExec", &MPAgentExec);
    err = err ?: SecTrustedApplicationCreateFromPath("/Library/MacPatch/Client/MPCatalog.app", &MPCatalog);
    err = err ?: SecTrustedApplicationCreateFromPath("/Library/MacPatch/Client/MPClientStatus.app", &MPClientStatus);
    err = err ?: SecTrustedApplicationCreateFromPath("/Library/MacPatch/Client/Self Patch.app", &SelfPatch);
    err = err ?: SecTrustedApplicationCreateFromPath("/System/Library/CoreServices/SecurityAgentPlugins/MPAuthPlugin.bundle", &MPAuthPlugin);
    //err = err ?: SecTrustedApplicationCreateFromPath(DAEMON_PATH, &MPAuthPlugin);
    //err = err ?: SecTrustedApplicationCreateFromPath(CLIENT_PATH, &MPAuthPlugin);

    if (err == noErr) {
        trustedApplications = [NSArray arrayWithObjects:(__bridge_transfer id)myself,
                               (__bridge_transfer id)MPWorker,(__bridge_transfer id)MPAgent,
                               (__bridge_transfer id)MPAgentExec,(__bridge_transfer id)MPCatalog,
                               (__bridge_transfer id)MPClientStatus,(__bridge_transfer id)SelfPatch,
                               (__bridge_transfer id)MPAuthPlugin,nil];
    }

    //Create an access object:
#if DEBUG
    // NO Access needed in Debug
    access = NULL;
#else
    err = err ?: SecAccessCreate((__bridge CFStringRef)accessLabel,(__bridge CFArrayRef)trustedApplications, &access);
    if (err) return nil;
#endif

    return access;
}

- (OSStatus)openKeychainRefFromFile:(NSString *)aKeychainFilePath
{
    OSStatus result;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    const char *uuid = [[self clientUUID] UTF8String];
    // If KeyChain Exists
    if ([fm fileExistsAtPath:aKeychainFilePath])
    {
        result = SecKeychainOpen([aKeychainFilePath fileSystemRepresentation], &keychainItem);
        result = SecKeychainUnlock(keychainItem, (UInt32)strlen(uuid), uuid, TRUE);
    }
    else
    {
        SecAccessRef access=nil;
        access = [self createDefaultAccessRef];

        // Create New one

        result = SecKeychainCreate([aKeychainFilePath fileSystemRepresentation],
                                   (UInt32)strlen(uuid), uuid, FALSE,
                                   NULL, //specify custom access controls here
                                   &keychainItem);
    }

    return result;
}

#pragma mark - Public

//
// Uses SecKeychainItemCreateFromContent()
// This method is an experiment, normally use addPasswordItemToKeychain
//
- (OSStatus)addPassword:(NSString *)aPassword username:(NSString *)aUserName serviceName:(NSString *)aServiceName
{
    OSStatus err;
    SecKeychainItemRef item = nil;
    const char *aUserNameUTF8 = [aUserName UTF8String];
    const char *aPasswordUTF8 = [aPassword UTF8String];
    const char *aServiceNameUTF8 = [aServiceName UTF8String];

    //Create initial access control settings for the item:
    SecAccessRef access = [self createDefaultAccessRef];

    //Following is the lower-level equivalent to the
    // SecKeychainAddInternetPassword function:

    //Set up the attribute vector (each attribute consists
    // of {tag, length, pointer}):
    SecKeychainAttribute attrs[] = {
        { kSecServiceItemAttr, (UInt32)strlen(aServiceNameUTF8), (char *)aServiceNameUTF8 },
        { kSecAccountItemAttr, (UInt32)strlen(aUserNameUTF8), (char *)aUserNameUTF8 }
    };

    SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };


    err = SecKeychainItemCreateFromContent(
                                           kSecGenericPasswordItemClass,
                                           &attributes,
                                           (UInt32)strlen(aPasswordUTF8),
                                           aPasswordUTF8,
                                           keychainItem,
                                           access,
                                           &item);
    return err;
}

- (OSStatus)addPasswordItemToKeychain:(NSString *)aPassword username:(NSString *)aUserName serviceName:(NSString *)aServiceName
{
    OSStatus result = noErr;
    result = SecKeychainAddGenericPassword(keychainItem, //the custom keychain
                                           (UInt32)strlen([aServiceName UTF8String]),[aServiceName UTF8String],
                                           (UInt32)strlen([aUserName UTF8String]),[aUserName UTF8String],
                                           (UInt32)strlen([aPassword UTF8String]),[aPassword UTF8String],
                                           NULL);
    if (noErr != result) {
        CFStringRef errMsg = SecCopyErrorMessageString(result, NULL);
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:(__bridge NSString *)errMsg forKey:NSLocalizedDescriptionKey];
        self.error = nil;
        self.error = [NSError errorWithDomain:@"gov.llnl.mp.keychain" code:-1002 userInfo:userInfo];
        CFRelease(errMsg);
    }

    return result;
}

- (OSStatus)addP12CertificateToKeychain:(NSString *)aCertPath certPassword:(NSString *)aPassword
{
    OSStatus result = noErr;
    CFArrayRef outItems = NULL;

    SecAccessRef access=nil;
    access = [self createDefaultAccessRef];

    NSData *certData = [NSData dataWithContentsOfFile:aCertPath];
    SecKeyImportExportFlags importFlags = kSecKeyImportOnlyOne;
    SecKeyImportExportParameters importParameters;
	importParameters.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	importParameters.flags = importFlags;
	importParameters.passphrase = (__bridge CFStringRef)aPassword;
	importParameters.accessRef = access;
	importParameters.keyUsage = CSSM_KEYUSE_ANY;
	importParameters.keyAttributes = CSSM_KEYATTR_SENSITIVE | CSSM_KEYATTR_EXTRACTABLE;

    SecExternalFormat inputFormat = kSecFormatPKCS12;
	SecExternalItemType itemType = kSecItemTypeUnknown;

	//SecKeychainCopyDefault(&newKeychain);
	result = SecKeychainItemImport((__bridge CFDataRef)certData,  // CFDataRef importedData
                                   NULL,                          // CFStringRef fileNameOrExtension
                                   &inputFormat,                  // SecExternalFormat *inputFormat
                                   &itemType,                     // SecExternalItemType *itemType
                                   0,                             // SecItemImportExportFlags flags (Unused)
                                   &importParameters,             // const SecKeyImportExportParameters *keyParams
                                   keychainItem,                  // SecKeychainRef importKeychain
                                   &outItems);                    // CFArrayRef *outItems

    if (noErr != result) {
        CFStringRef errMsg = SecCopyErrorMessageString(result, NULL);
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:(__bridge NSString *)errMsg forKey:NSLocalizedDescriptionKey];
        self.error = nil;
        self.error = [NSError errorWithDomain:@"gov.llnl.mp.keychain" code:-1002 userInfo:userInfo];
        CFRelease(errMsg);
    }

    return result;
}

//
// I cheated, this was way quicker ;-)
//
- (int)addCAToSystemKeychain:(NSData *)aCACert
{
    NSString *caFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mpCA.crt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:caFile]) {
        [[NSFileManager defaultManager] removeItemAtPath:caFile error:NULL];
    }
    [aCACert writeToFile:caFile atomically:NO];
    NSString *cmd = [NSString stringWithFormat:@"/usr/bin/security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain %@", caFile];
    int result = -1;
    result = system([cmd UTF8String]);
    return result;
}

- (NSString *)passwordForGenericService:(NSString*)service forAccount:(NSString*)account
{
    int err, errFind;
    char *passData;
    UInt32 passLength;
    SecKeychainItemRef itemRef = nil;
    SecKeychainStatus keychainStatus;
    err = SecKeychainGetStatus(keychainItem,&keychainStatus);
    /*
    NSLog(@"unlocked: %@", (keychainStatus & kSecUnlockStateStatus) ? @"YES" : @"NO");
    NSLog(@"    read: %@", (keychainStatus & kSecReadPermStatus) ? @"YES" : @"NO");
    NSLog(@"   write: %@", (keychainStatus & kSecWritePermStatus) ? @"YES" : @"NO");
     */

    SecKeychainSetUserInteractionAllowed(FALSE);

    errFind = SecKeychainFindGenericPassword(keychainItem,
                                            (UInt32)strlen([service UTF8String]),[service UTF8String],
                                            (UInt32)strlen([account UTF8String]), [account UTF8String],
                                            &passLength, (void**)&passData, &itemRef);
    if (errFind == CSSM_OK) {
        NSString __strong *pass = [[NSString alloc] initWithCStringNoCopy:passData length:passLength freeWhenDone:YES];
        SecKeychainItemFreeContent(NULL, passData);
        return pass;
    } else {
        CFStringRef errMsg = SecCopyErrorMessageString(errFind, NULL);
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:(__bridge NSString *)errMsg forKey:NSLocalizedDescriptionKey];
        self.error = nil;
        self.error = [NSError errorWithDomain:@"gov.llnl.mp.keychain" code:-1005 userInfo:userInfo];
        CFRelease(errMsg);
        return nil;
    }
}

- (OSStatus)lockKeychain
{
    return SecKeychainLock(keychainItem);
}

@end
