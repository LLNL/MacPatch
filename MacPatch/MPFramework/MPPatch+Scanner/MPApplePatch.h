//
//  MPApplePatch.h
//  MPLibrary
//
//  Created by Heizer, Charles on 8/26/13.
//
//

#import <Foundation/Foundation.h>

@interface MPApplePatch : NSObject
{
    NSString *cuuid;
    NSString * patch;
    NSString * type;
    NSString * description;
    NSString * size;
    NSString * recommended;
    NSString * restart;
    NSString * version;
}

@property (nonatomic, strong) NSString *cuuid;
@property (nonatomic, strong) NSString *patch;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *size;
@property (nonatomic, strong) NSString *recommended;
@property (nonatomic, strong) NSString *restart;
@property (nonatomic, strong) NSString *version;

- (NSDictionary *)patchAsDictionary;

@end
