//
//  MPCustomPatch.h
//  MPLibrary
//
//  Created by Heizer, Charles on 8/26/13.
//
//

#import <Foundation/Foundation.h>

@interface MPCustomPatch : NSObject
{
    NSString *cuuid;
    NSString * patch;
    NSString * type;
    NSString * description;
    NSString * size;
    NSString * recommended;
    NSString * restart;
    NSString * version;
    NSString * patch_id;
    NSString * bundleID;
}

@property (nonatomic, retain) NSString *cuuid;
@property (nonatomic, retain) NSString *patch;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *size;
@property (nonatomic, retain) NSString *recommended;
@property (nonatomic, retain) NSString *restart;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *patch_id;
@property (nonatomic, retain) NSString *bundleID;

- (NSDictionary *)patchAsDictionary;

@end
