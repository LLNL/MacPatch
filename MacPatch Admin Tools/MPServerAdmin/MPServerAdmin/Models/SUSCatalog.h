//
//  SUSCatalog.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/12/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SUSCatalog : NSObject

@property (nonatomic) NSString *catalogurl;
@property (nonatomic) NSString *osver;

- (NSDictionary *)returnAsDictionary;

@end
