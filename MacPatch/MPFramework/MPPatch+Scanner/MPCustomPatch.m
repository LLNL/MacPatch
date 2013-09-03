//
//  MPCustomPatch.m
//  MPLibrary
//
//  Created by Heizer, Charles on 8/26/13.
//
//

#import "MPCustomPatch.h"

@implementation MPCustomPatch

@synthesize cuuid;
@synthesize patch;
@synthesize type;
@synthesize description;
@synthesize size;
@synthesize recommended;
@synthesize restart;
@synthesize version;
@synthesize patch_id;
@synthesize bundleID;

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setCuuid:@""];
        [self setPatch:@""];
        [self setType:@"Third"];
        [self setDescription:@""];
        [self setSize:@"0"];
        [self setRecommended:@"Y"];
        [self setRestart:@""];
        [self setVersion:@""];
        [self setPatch_id:@""];
        [self setBundleID:@""];
    }
    return self;
}

- (NSDictionary *)patchAsDictionary
{
    // cuuid, patch, type, description, size, recommended, restart, patch_id, version, bundleID
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setObject:self.cuuid forKey:@"cuuid"];
    [p setObject:self.patch forKey:@"patch"];
    [p setObject:self.type forKey:@"type"];
    [p setObject:self.description forKey:@"description"];
    [p setObject:self.size forKey:@"size"];
    [p setObject:self.recommended forKey:@"recommended"];
    [p setObject:self.restart forKey:@"restart"];
    [p setObject:self.version forKey:@"version"];
    [p setObject:self.patch_id forKey:@"patch_id"];
    [p setObject:self.bundleID forKey:@"bundleID"];
    return (NSDictionary *)p;
}


@end
