//
//  MPApplePatch.m
//  MPLibrary
//
//  Created by Heizer, Charles on 8/26/13.
//
//

#import "MPApplePatch.h"

@implementation MPApplePatch

@synthesize cuuid;
@synthesize patch;
@synthesize type;
@synthesize description;
@synthesize size;
@synthesize recommended;
@synthesize restart;
@synthesize version;


- (id)init
{
    self = [super init];
    if (self)
    {
        [self setCuuid:@""];
        [self setPatch:@""];
        [self setType:@"Apple"];
        [self setDescription:@""];
        [self setSize:@""];
        [self setRecommended:@""];
        [self setRestart:@""];
        [self setVersion:@""];
    }
    return self;
}

- (NSDictionary *)patchAsDictionary
{
    // cuuid, patch, type, description, size, recommended, restart, version
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setObject:self.cuuid forKey:@"cuuid"];
    [p setObject:self.patch forKey:@"patch"];
    [p setObject:self.type forKey:@"type"];
    [p setObject:self.description forKey:@"description"];
    [p setObject:self.size forKey:@"size"];
    [p setObject:self.recommended forKey:@"recommended"];
    [p setObject:self.restart forKey:@"restart"];
    [p setObject:self.version forKey:@"version"];
    return (NSDictionary *)p;
}

@end
