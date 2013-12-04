//
//  MPApplePatch.h
//  MPPatchLoader
//
//  Created by Heizer, Charles on 11/27/13.
//
//

#import <Foundation/Foundation.h>

@interface MPApplePatch : NSObject
{
    NSString *__unsafe_unretained CFBundleShortVersionString;
    NSString *__unsafe_unretained Distribution;
    NSString *__unsafe_unretained IFPkgFlagRestartAction;
    NSString *__unsafe_unretained ServerMetadataURL;
    NSString *__unsafe_unretained akey;
    NSString *__unsafe_unretained description;
    NSString *__unsafe_unretained osver;
    NSString *__unsafe_unretained patchname;
    NSString *__unsafe_unretained postdate;
    NSString *__unsafe_unretained supatchname;
    NSString *__unsafe_unretained title;

}

@property (nonatomic, unsafe_unretained) NSString *CFBundleShortVersionString;
@property (nonatomic, unsafe_unretained) NSString *Distribution;
@property (nonatomic, unsafe_unretained) NSString *IFPkgFlagRestartAction;
@property (nonatomic, unsafe_unretained) NSString *ServerMetadataURL;
@property (nonatomic, unsafe_unretained) NSString *akey;
@property (nonatomic, unsafe_unretained) NSString *description;
@property (nonatomic, unsafe_unretained) NSString *osver;
@property (nonatomic, unsafe_unretained) NSString *patchname;
@property (nonatomic, unsafe_unretained) NSString *postdate;
@property (nonatomic, unsafe_unretained) NSString *supatchname;
@property (nonatomic, unsafe_unretained) NSString *title;

- (id)initWithDistAndSMDData:(NSString *)aDistData smd:(NSString *)aSMDData;
- (NSDictionary *)patchAsDictionary;

@end
