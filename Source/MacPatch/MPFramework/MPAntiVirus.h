//
//  MPAntiVirus.h
//  MPLibrary
//
//  Created by Heizer, Charles on 5/19/16.
//
//

#import <Foundation/Foundation.h>

@interface MPAntiVirus : NSObject
{
    NSString		*avType;
    NSString		*avApp;
    NSDictionary	*avAppInfo;
    NSString		*avDefsDate;
    NSDictionary	*l_Defaults;
    
    NSFileManager   *fm;
    BOOL            isNewerSEPSW;
}

@property (nonatomic, strong) NSString *avType;
@property (nonatomic, strong) NSString *avApp;
@property (nonatomic, strong) NSDictionary *avAppInfo;
@property (nonatomic, strong) NSString *avDefsDate;
@property (nonatomic, strong) NSDictionary *l_Defaults;
@property (nonatomic, assign) BOOL isNewerSEPSW;

// Scan & Update
- (void)scanDefs;
- (void)scanAndUpdateDefs;
- (void)avScanAndUpdate:(BOOL)runUpdate;

// Collect
- (NSDictionary *)getAvAppInfo;
- (NSString *)getLocalDefsDate;
- (NSString *)parseNewDefsDateFormat:(NSString *)defsDate;

// Download & Update
- (NSString *)getLatestAVDefsDate;
- (NSString *)getAvUpdateURL;
- (int)downloadUnzipAndInstall:(NSString *)pkgURL;
- (int)runAVDefsUpdate;

@end
