//
//  CKSoftwareProduct+ASProduct.h
//  MyAppStore
//
//  Created by Charles Heizer on 11/12/16.
//  Copyright © 2016 Lawrence Livermore Nat'l Lab. All rights reserved.
//

#import "CKSoftwareProduct.h"

@interface CKSoftwareProduct (CKSoftwareProduct)

- (NSDictionary *)productAsDictionary;
- (NSString *)productAsJSONString;

@end
