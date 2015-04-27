//
//  SUSCatalog.m
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/12/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import "SUSCatalog.h"

@implementation SUSCatalog

@synthesize catalogurl;
@synthesize osver;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.catalogurl = @"content/catalogs/others/index-lion-snowleopard-leopard.merged-1.sucatalog";
        self.osver = @"10.7";
    }
    return self;
}

- (NSDictionary *)returnAsDictionary
{
    NSDictionary *d = @{ @"catalogurl":self.catalogurl, @"osver": self.osver };
    return d;
}

@end
