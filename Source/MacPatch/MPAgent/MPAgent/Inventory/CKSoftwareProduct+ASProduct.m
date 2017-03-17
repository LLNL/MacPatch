//
//  CKSoftwareProduct+ASProduct.m
//  MyAppStore
//
//  Created by Charles Heizer on 11/12/16.
//  Copyright © 2016 Lawrence Livermore Nat'l Lab. All rights reserved.
//

#import "CKSoftwareProduct+ASProduct.h"
#import "NSDate+Helper.h"

@implementation CKSoftwareProduct (CKSoftwareProduct)

static id ObjectOrNA(id object)
{
    return object ?: @"NA";
}

- (NSDictionary *)productAsDictionary
{
    NSDictionary *_product = @{
                               @"expectedStoreVersion":ObjectOrNA([self.expectedStoreVersion stringValue]),
                               @"expectedBundleVersion":ObjectOrNA(self.expectedBundleVersion),
                               @"isLegacyApp":self.isLegacyApp ? @"YES":@"NO",
                               @"isMachineLicensed":self.expectedStoreVersion ? @"YES":@"NO",
                               @"vppLicenseCancellationReason":ObjectOrNA(self.vppLicenseCancellationReason),
                               @"vppLicenseRenewalDate":ObjectOrNA([NSDate stringFromDate:self.vppLicenseRenewalDate withFormat:@"yyyy-MM-dd"]),
                               @"vppLicenseExpirationDate":ObjectOrNA([NSDate stringFromDate:self.vppLicenseExpirationDate withFormat:@"yyyy-MM-dd"]),
                               @"vppLicenseOrganizationName":ObjectOrNA(self.vppLicenseOrganizationName),
                               @"vppLicenseRevoked":self.vppLicenseRevoked ? @"YES":@"NO",
                               @"isVPPLicensed":self.isVPPLicensed ? @"YES":@"NO",
                               @"installed":self.installed ? @"YES":@"NO",
                               @"versionIdentifier":ObjectOrNA([self.versionIdentifier stringValue]),
                               @"itemIdentifier":ObjectOrNA([self.itemIdentifier stringValue]),
                               @"receiptType":ObjectOrNA(self.receiptType),
                               @"bundlePath":ObjectOrNA(self.bundlePath),
                               @"bundleVersion":ObjectOrNA(self.bundleVersion),
                               @"bundleIdentifier":ObjectOrNA(self.bundleIdentifier),
                               @"accountIdentifier":ObjectOrNA(self.accountIdentifier),
                               @"accountOpaqueDSID":ObjectOrNA(self.accountOpaqueDSID)
                               };
    return _product;
}
- (NSString *)productAsJSONString
{
    NSError *error = nil;
    NSString *jsonString = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self productAsDictionary]
                                                       options:0
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}


@end
