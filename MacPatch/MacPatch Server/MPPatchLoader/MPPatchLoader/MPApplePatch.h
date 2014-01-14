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
    NSString * CFBundleShortVersionString;
    NSString * Distribution;
    NSString * IFPkgFlagRestartAction;
    NSString * ServerMetadataURL;
    NSString * akey;
    NSString * patchDescription;
    NSString * osver;
    NSString * patchname;
    NSString * postdate;
    NSString * supatchname;
    NSString * title;
}

@property (nonatomic, strong) NSString *CFBundleShortVersionString;
@property (nonatomic, strong) NSString *Distribution;
@property (nonatomic, strong) NSString *IFPkgFlagRestartAction;
@property (nonatomic, strong) NSString *ServerMetadataURL;
@property (nonatomic, strong) NSString *akey;
@property (nonatomic, strong) NSString *patchDescription;
@property (nonatomic, strong) NSString *osver;
@property (nonatomic, strong) NSString *patchname;
@property (nonatomic, strong) NSString *postdate;
@property (nonatomic, strong) NSString *supatchname;
@property (nonatomic, strong) NSString *title;

- (id)initWithDistAndSMDData:(NSString *)aDistData smd:(NSString *)aSMDData;
- (NSDictionary *)patchAsDictionary;

@end
