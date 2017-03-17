//
//  MPAppStore.m
//  MyAppStore
//
//  Created by Charles Heizer on 11/12/16.
//  Copyright © 2016 Lawrence Livermore Nat'l Lab. All rights reserved.
//

#import "MPAppStore.h"
#import "CKSoftwareProduct+ASProduct.h"

@implementation MPAppStore

- (NSArray *)installedProducts
{
    NSMutableArray *products = [NSMutableArray new];
    CKSoftwareMap *swm = [CKSoftwareMap sharedSoftwareMap];
    for (CKSoftwareProduct *p in [swm allProducts]) {
        [products addObject:[p productAsDictionary]];
    }
    return products;
}

- (NSString *)installedProductsAsJSON
{
    NSError *error = nil;
    NSString *jsonString = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self installedProducts]
                                                       options:0
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

- (NSArray *)availableUpdates
{
    NSMutableArray *products = [NSMutableArray new];
    CKUpdateController *updateController = [CKUpdateController sharedUpdateController];
    for (CKSoftwareProduct *p in [updateController availableUpdates]) {
        [products addObject:[p productAsDictionary]];
    }
    
    return products;
}

- (NSString *)availableUpdatesAsJSON
{
    NSError *error = nil;
    NSString *jsonString = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self availableUpdates]
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
