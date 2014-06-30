//
//  MPFailedRequests.m
//  MPLibrary
//
//  Created by Heizer, Charles on 5/13/14.
//
//

#import "MPFailedRequests.h"
#import "MPWebServices.h"

@implementation MPFailedRequests

- (id)init
{
    self = [super init];
    if (self) {
        fm = [NSFileManager defaultManager];
    }
    return self;
}

- (NSDictionary *)readFailedRequestsPlist
{
    if ([fm fileExistsAtPath:WS_FAILED_REQ_PLIST])
    {
        NSDictionary *reqFile = [NSDictionary dictionaryWithContentsOfFile:WS_FAILED_REQ_PLIST];
        return reqFile;
    }
    return nil;
}

- (BOOL)writeFailedRequestsPlist:(NSDictionary *)aRequests
{
    NSError *fmErr = nil;
    NSDictionary *attr775 = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0775] forKey:NSFilePosixPermissions];
    NSDictionary *attr777 = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];

    // Create the Parent Dir if Missing
    if (![fm fileExistsAtPath:WS_FAILED_REQ_PLIST])
    {
        BOOL isDir = NO;
        if (![fm fileExistsAtPath:[WS_FAILED_REQ_PLIST stringByDeletingLastPathComponent] isDirectory:&isDir]) {
            fmErr = nil;
            [fm createDirectoryAtPath:[WS_FAILED_REQ_PLIST stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:attr777 error:&fmErr];
            if (fmErr) {
                qlerror(@"%@",fmErr.localizedDescription);
                return NO;
            }
        }
    }

    // Write file
    fmErr = nil;
    [aRequests writeToFile:WS_FAILED_REQ_PLIST atomically:NO];
    [fm setAttributes:attr775 ofItemAtPath:WS_FAILED_REQ_PLIST error:&fmErr];
    if (fmErr) {
        qlerror(@"%@",fmErr.localizedDescription);
        return NO;
    }

    return YES;
}

- (BOOL)addFailedRequest:(NSString *)methodName params:(NSDictionary *)aParams errorNo:(NSInteger)errorNo errorMsg:(NSString *)errorMsg
{
    NSMutableDictionary *reqFile = [NSMutableDictionary dictionaryWithDictionary:[self readFailedRequestsPlist]];
    NSMutableArray *reqs;
    if ([reqFile objectForKey:@"failedAttempts"]) {
        reqs = [[NSMutableArray alloc] initWithArray:[reqFile objectForKey:@"failedAttempts"]];
    } else {
        reqs = [[NSMutableArray alloc] init];
    }
    NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
    [req setObject:[NSDate date] forKey:@"failDate"];
    [req setObject:[NSNumber numberWithInteger:errorNo] forKey:@"errorno"];
    [req setObject:errorMsg forKey:@"errormsg"];
    [req setObject:methodName forKey:@"wsMethod"];
    [req setObject:[NSNumber numberWithInt:1] forKey:@"postAttempts"];
    if (aParams)
        [req setObject:aParams forKey:@"params"];

    [reqs addObject:(NSDictionary *)req];
    [reqFile setObject:reqs forKey:@"failedAttempts"];

    return [self writeFailedRequestsPlist:(NSDictionary *)reqFile];
}

- (BOOL)postFailedRequests
{
    NSMutableDictionary *reqFile = [NSMutableDictionary dictionaryWithDictionary:[self readFailedRequestsPlist]];
    if (!reqFile) {
        qlinfo(@"No failed requests to post. Failed requests file not found.");
        return YES;
    }

    NSMutableArray *reqs;
    NSMutableArray *reqsFailed = [[NSMutableArray alloc] init];
    if ([reqFile objectForKey:@"failedAttempts"]) {
        reqs = [[NSMutableArray alloc] initWithArray:[reqFile objectForKey:@"failedAttempts"]];
        if ([reqs count] == 0) {
            qlinfo(@"No failed requests to post");
            return YES;
        }
    } else {
        qlinfo(@"No failed requests to post");
        return YES;
    }

    NSError *err = nil;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    for (NSMutableDictionary *req in reqs)
    {
        NSDictionary *params = [req objectForKey:@"params"];
        err = nil;
        qlinfo(@"Attempting to re-post data for %@",[req objectForKey:@"wsMethod"]);
        if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postPatchScanResultsForType"]) {
            [mpws postPatchScanResultsForType:(NSInteger)[params objectForKey:@"aPatchScanType"] results:[params objectForKey:@"resultsDictionary"] error:&err];

        } else if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postPatchInstallResultsToWebService"]) {
            [mpws postPatchInstallResultsToWebService:[params objectForKey:@"aPatch"] patchType:[params objectForKey:@"aPatchType"] error:&err];

        } else if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postClientAVData"]) {
            [mpws postClientAVData:[params objectForKey:@"aDict"] error:&err];

        } else if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postDataMgrXML"]) {
            [mpws postDataMgrXML:[params objectForKey:@"aDataMgrXML"] error:&err];

        } else if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postDataMgrJSON"]) {
            [mpws postDataMgrJSON:[params objectForKey:@"aDataMgrJSON"] error:&err];

        } else if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postSAVDefsDataXML"]) {
            [mpws postSAVDefsDataXML:[params objectForKey:@"aAVXML"] encoded:(BOOL)[params objectForKey:@"aEncoded"] error:&err];

        } else if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postJSONDataForMethod"]) {
            [mpws postJSONDataForMethod:[params objectForKey:@"aMethod"] data:[params objectForKey:@"aData"] error:&err];

        } else if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postSWInstallResults"]) {
            [mpws postSWInstallResults:[params objectForKey:@"aParams"] error:&err];

        } else if ([[req objectForKey:@"wsMethod"] isEqualToString:@"postClientHasInvData"]) {
            [mpws postClientHasInvData:&err];

        } else {
            continue;
        }

        if (err) {
            qlerror(@"Error re-posting data for %@",[req objectForKey:@"wsMethod"]);
            if ([[req objectForKey:@"postAttempts"] intValue] <= 15) {
                int p = [[req objectForKey:@"postAttempts"] intValue];
                [req setObject:[NSNumber numberWithInt:p++] forKey:@"postAttempts"];
                [reqsFailed addObject:req];
            } else {
                qlerror(@"%@ is being removed due to to many re-post attempts.",[req objectForKey:@"wsMethod"]);
            }
        }
    }

    [reqFile setObject:reqsFailed forKey:@"failedAttempts"];
    if ([self writeFailedRequestsPlist:reqFile]) {
        return YES;
    } else {
        return NO;
    }
}

@end
