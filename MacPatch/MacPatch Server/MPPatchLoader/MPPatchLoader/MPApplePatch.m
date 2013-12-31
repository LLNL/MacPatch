//
//  MPApplePatch.m
//  MPPatchLoader
//
//  Created by Heizer, Charles on 11/27/13.
//
//

#import "MPApplePatch.h"

@interface MPApplePatch ()

- (NSDictionary *)readSMDFile:(NSString *)smd  error:(NSError **)err;
- (NSDictionary *)readDistFile:(NSString *)dist  error:(NSError **)err;

@end

@implementation MPApplePatch

@synthesize CFBundleShortVersionString;
@synthesize Distribution;
@synthesize IFPkgFlagRestartAction;
@synthesize ServerMetadataURL;
@synthesize akey;
@synthesize patchDescription;
@synthesize osver;
@synthesize patchname;
@synthesize postdate;
@synthesize supatchname;
@synthesize title;

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setCFBundleShortVersionString:@"0.1"];
        [self setDistribution:@""];
        [self setIFPkgFlagRestartAction:@"NoRestart"];
        [self setServerMetadataURL:@""];
        [self setAkey:@""];
        [self setPatchDescription:@""];
        [self setOsver:@""];
        [self setPatchname:@""];
        [self setPostdate:@"1984-01-24 00:00:00"];
        [self setSupatchname:@""];
        [self setTitle:@""];
    }
    return self;
}

- (id)initWithDistAndSMDData:(NSString *)aDistData smd:(NSString *)aSMDData
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (NSDictionary *)patchAsDictionary
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:self.CFBundleShortVersionString forKey:@"CFBundleShortVersionString"];
    [d setObject:self.patchDescription forKey:@"description"];
    [d setObject:self.IFPkgFlagRestartAction forKey:@"IFPkgFlagRestartAction"];
    // Dont include, patch loader does not include these cols
    //[d setObject:self.ServerMetadataURL forKey:@"ServerMetadataURL"];
    //[d setObject:self.Distribution forKey:@"Distribution"];
    [d setObject:self.akey forKey:@"akey"];
    [d setObject:self.osver forKey:@"osver"];
    [d setObject:self.patchname forKey:@"patchname"];
    [d setObject:self.postdate forKey:@"postdate"];
    [d setObject:self.supatchname forKey:@"supatchname"];
    [d setObject:self.title forKey:@"title"];
    NSDictionary *rd = [NSDictionary dictionaryWithDictionary:d];
    return rd;
}

- (NSDictionary *)readSMDFile:(NSString *)smd  error:(NSError **)err
{
    return nil;
}

- (NSDictionary *)readDistFile:(NSString *)dist  error:(NSError **)err
{
    return nil;
}

@end
