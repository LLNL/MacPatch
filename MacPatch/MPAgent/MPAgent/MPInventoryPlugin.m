//
//  MPInventoryPlugin.m
//  MPAgent
//
//  Created by Heizer, Charles on 8/31/15.
//  Copyright (c) 2015 LLNL. All rights reserved.
//

#import "MPInventoryPlugin.h"
#import "InventoryPlugin.h"
#include <CommonCrypto/CommonCrypto.h>

#define kMPInvPluginsDir    @"/Library/MacPatch/Client/lib/PlugIns"

@implementation MPInventoryPlugin

- (NSArray *)loadPlugins
{
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kMPInvPluginsDir error:nil];
    if ([fileNames count] <= 0) {
        return nil;
    }
    NSString *fullFilePath = nil;
    NSMutableArray *availablePlugins = [NSMutableArray array];
    
    id plugin = nil;
    NSBundle *pluginBundle = nil;
    
    for (NSString *fileName in fileNames)
    {
        if (![fileName hasSuffix:@"bundle"]) continue;
        
        plugin = nil;
        pluginBundle = nil;
        fullFilePath = [kMPInvPluginsDir stringByAppendingPathComponent:fileName];
        pluginBundle = [NSBundle bundleWithPath:fullFilePath];
        [pluginBundle load];
        
        Class principalClass = [pluginBundle principalClass];
        
        // Do a little sanity checking
        if (![principalClass conformsToProtocol: @protocol(InventoryPluginProtocol)]) {
            NSLog (@"plug-in principal class must conform to the BundlePrinterProtocol");
            continue;
        }
        
        plugin = [[principalClass alloc] init];
        
        [availablePlugins addObject:@{ @"plugin":plugin,
                                       @"pluginName":[[pluginBundle infoDictionary] valueForKey:@"CFBundleName"],
                                       @"pluginVersion":[[pluginBundle infoDictionary] valueForKey:@"CFBundleShortVersionString"]}];
        
        plugin = nil;
        pluginBundle = nil;
    }
    
    return availablePlugins;
}

- (NSString *)readAndVerifyKey:(NSString *)aFullPath key:(NSString *)aPluginKey
{
    MPCrypto *mpc = [[MPCrypto alloc] init];
    NSBundle *pluginBundle = [NSBundle bundleWithPath:aFullPath];
    NSString *pluginBinary = [[aFullPath stringByAppendingString:@"/Contents/MacOS"] stringByAppendingPathComponent:[[pluginBundle infoDictionary] valueForKey:@"CFBundleName"]];
    NSString *pluginHash = [mpc getHashForFileForType:pluginBinary type:@"SHA1"];
    NSData *dataIn = [[NSString stringWithFormat:@"%@%@%@",
                       [[pluginBundle infoDictionary] valueForKey:@"CFBundleIdentifier"],
                       [[pluginBundle infoDictionary] valueForKey:@"CFBundleShortVersionString"],pluginHash] dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *macOut = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(dataIn.bytes, dataIn.length,  macOut.mutableBytes);
    
    NSString *hexHash = [self hexforData:macOut];
    return hexHash;
}

- (NSString *)hexforData:(NSData*)theData
{
    NSUInteger dataLength = [theData length];
    NSMutableString *string = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [theData bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx) {
        [string appendFormat:@"%02x", dataBytes[idx]];
    }
    
    return string;
}

@end
