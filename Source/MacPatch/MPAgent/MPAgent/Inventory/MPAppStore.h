//
//  MPAppStore.h
//  MyAppStore
//
//  Created by Charles Heizer on 11/12/16.
//  Copyright © 2016 Lawrence Livermore Nat'l Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPAppStore : NSObject

- (NSArray *)installedProducts;
- (NSString *)installedProductsAsJSON;

- (NSArray *)availableUpdates;
- (NSString *)availableUpdatesAsJSON;

@end
