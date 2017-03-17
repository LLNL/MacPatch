//
//  AppStoreOperation.m
//  MPAgent
//
//  Created by Charles Heizer on 11/14/16.
//  Copyright © 2016 LLNL. All rights reserved.
//

#import "AppStoreOperation.h"
#import "MPAppStore.h"
#import "MacPatch.h"


@interface AppStoreOperation (Private)

- (void)collectDataAndPostIt;
- (BOOL)processData:(NSArray *)dataArray table:(NSString *)tableName;
- (BOOL)sendResultsToWebService:(NSString *)aDataMgrData;

@end

@implementation AppStoreOperation

@synthesize isExecuting;
@synthesize isFinished;

- (id)init
{
    if ((self = [super init]))
    {
        isExecuting = NO;
        isFinished  = NO;
        si	= [MPAgent sharedInstance];
        fm	= [NSFileManager defaultManager];
    }
    
    return self;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (void)cancel
{
    [self finish];
}

- (void)finish
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start
{
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
    } else {
        [self willChangeValueForKey:@"isExecuting"];
        [self performSelectorInBackground:@selector(main) withObject:nil];
        isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)main
{
    @try {
        [self collectDataAndPostIt];
    }
    @catch (NSException * e) {
        logit(lcl_vError,@"[NSException]: %@",e);
    }
    [self finish];
}

- (void)collectDataAndPostIt
{
    @autoreleasepool
    {
        logit(lcl_vInfo,@"Running client check in.");
        @try {
            MPAppStore *mpas = [[MPAppStore alloc] init];
            NSArray *installedProducts = [mpas installedProducts];
            NSArray *outdatedProducts = [mpas availableUpdates];
            
            [self processData:installedProducts table:@"AppStoreInstalled"];
            [self processData:outdatedProducts table:@"AppStoreUpdates"];
            
        }
        @catch (NSException * e) {
            logit(lcl_vError,@"[NSException]: %@",e);
            logit(lcl_vError,@"No client checkin data will be posted.");
            return;
        }
    }
}

- (BOOL)processData:(NSArray *)dataArray table:(NSString *)tableName
{
    MPDataMgr   *dataMgr = [[MPDataMgr alloc] init];
    NSString    *dataMgrJSON;
    
    dataMgrJSON = [dataMgr GenJSONForDataMgr:dataArray
                                     dbTable:tableName
                               dbTablePrefix:@"mpi_"
                               dbFieldPrefix:@"mpa_"
                                updateFields:@"rid,cuuid"
                                   deleteCol:@"cuuid"
                              deleteColValue:[si g_cuuid]];
    
    if ([self sendResultsToWebService:dataMgrJSON]) {
        logit(lcl_vInfo,@"Results for %@ posted.",tableName);
    } else {
        logit(lcl_vError,@"Results for %@ not posted.",tableName);
    }

    return YES;
}

- (BOOL)sendResultsToWebService:(NSString *)aDataMgrData
{
    BOOL result = NO;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    mpws.clientKey = [si g_clientKey];
    NSError *wsErr = nil;
    result = [mpws postDataMgrData:aDataMgrData error:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"Results posted to webservice returned false.");
        logit(lcl_vError,@"%@",wsErr.localizedDescription);
    } else {
        logit(lcl_vInfo,@"Results posted to webservice.");
        result = YES;
    }
    
    return result;
}

@end
