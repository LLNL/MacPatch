//
//  XPCWorker.m
//  gov.llnl.mp.worker
//
/*
 Copyright (c) 2024, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.
 
 This file is part of MacPatch, a program for installing and patching
 software.
 
 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.
 
 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.
 
 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import "XPCWorker.h"
#import "MPHelperProtocol.h"
#import "AHCodesignVerifier.h"
#include <libproc.h>
#import "MPPatching.h"
#import "DBMigration.h"
#import "MPClientDB.h"

#undef  ql_component
#define ql_component lcl_cMPHelper

NSString *const MPXPCErrorDomain = @"gov.llnl.mp.helper";


@interface XPCWorker () <NSXPCListenerDelegate, MPHelperProtocol, MPHTTPRequestDelegate, MPPatchingDelegate>
{
    NSFileManager *fm;
}

@property (nonatomic, strong, readwrite) NSURL          *SW_DATA_DIR;

@property (atomic, assign, readwrite)   int             selfPID;
@property (atomic, strong, readwrite)   NSXPCListener   *listener;
@property (atomic, weak, readwrite)     NSXPCConnection *xpcConnection;

// PID
- (int)getPidNumber;
- (NSString *)pathForPid:(int)aPid;


// ASUS
- (NSString *)getSizeFromDescription:(NSString *)aDescription;
- (NSString *)getRecommendedFromDescription:(NSString *)aDescription;

// Patching
- (NSArray *)scanForAppleUpdates:(NSError **)error;

// Private
- (NSData *)encodeResult:(NSData *)dataToEncode error:(NSError **)error;
@end

@implementation XPCWorker

@synthesize SW_DATA_DIR;

- (id)init
{
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:kHelperServiceName];
        self->_listener.delegate = self;
        self->_selfPID = [self getPidNumber];
		self->SW_DATA_DIR = [self swDataDirURL];
        self->swTaskTimeoutValue = 1200; // 15min timeout to install an item
        [self configDataDir];
        fm = [NSFileManager defaultManager];
		
    }
    return self;
}

- (void)run
{
    qlinfo(@"XPC listener is ready for processing requests");
    // Tell the XPC listener to start processing requests.
    [self.listener resume];
    
    // Run the run loop forever.
    [[NSRunLoop currentRunLoop] run];
}

- (void)configDataDir
{
    // Set Data Directory

    // Create the base sw dir
    if ([fm fileExistsAtPath:[SW_DATA_DIR path]] == NO) {
        NSError *err = nil;
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
        [fm createDirectoryAtPath:[SW_DATA_DIR path] withIntermediateDirectories:YES attributes:attributes error:&err];
        if (err) {
            logit(lcl_vError,@"%@",[err description]);
        }
    }
    
    // Create the sw dir
    if ([fm fileExistsAtPath:[[SW_DATA_DIR URLByAppendingPathComponent:@"sw"] path]] == NO) {
        NSError *err = nil;
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
        [fm createDirectoryAtPath:[[SW_DATA_DIR URLByAppendingPathComponent:@"sw"] path] withIntermediateDirectories:YES attributes:attributes error:&err];
        if (err) {
            logit(lcl_vError,@"%@",[err description]);
        }
        [[SW_DATA_DIR URLByAppendingPathComponent:@"sw"] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsHiddenKey error:NULL];
    }
}

#pragma mark - XPC Setup & Connection

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
// Called by our XPC listener when a new connection comes in.  We configure the connection
// with our protocol and ourselves as the main object.
{
	BOOL valid = YES;
    if (valid)
	{
        assert(listener == self.listener);
        assert(newConnection != nil);
		
		newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MPHelperProtocol)];
		newConnection.exportedObject = self;
		
		
		self.xpcConnection = newConnection;
		newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MPHelperProgress)];
		
		[newConnection resume];
        return YES;
    }
    
    qlerror(@"Listener failed to trust new connection.");
    return NO;
}

- (BOOL)newConnectionIsTrusted:(NSXPCConnection *)newConnection
{
    BOOL success = NO;
    NSError *err = nil;
    
    int mePid = [self getPidNumber];
    NSString *mePidPath = [self pathForPid:mePid];
    logit(lcl_vDebug,@"self.pid %d, self.path %@",mePid,mePidPath);
    if (![AHCodesignVerifier codeSignOfItemAtPathIsValid:mePidPath error:&err])
    {
        logit(lcl_vError,@"The codesigning signature of one %@ is not valid.",mePidPath.lastPathComponent);
        logit(lcl_vError,@"%@",err.localizedDescription);
        return success;
    }
    
    pid_t rmtPid = newConnection.processIdentifier;
    NSString *remotePidPath = [self pathForPid:rmtPid];
    logit(lcl_vDebug,@"remote.pid %d, remote.path %@",rmtPid,remotePidPath);
    err = nil;
    if (![AHCodesignVerifier codeSignOfItemAtPathIsValid:remotePidPath error:&err])
    {
        logit(lcl_vError,@"The codesigning signature of one %@ is not valid.",mePidPath.lastPathComponent);
        return success;
    }
    
    err = nil;
    success = [AHCodesignVerifier codesignOfItemAtPath:mePidPath isSameAsItemAtPath:remotePidPath error:&err];
    if (err) {
        logit(lcl_vError,@"The codesigning signatures did not match.");
        logit(lcl_vError,@"%@",err.localizedDescription);
    }
    
    return success;
}

# pragma mark - PID methods

- (int)getPidNumber
{
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    int processID = [processInfo processIdentifier];
    return processID;
}

- (NSString *)pathForPid:(int)aPid
{
    int ret;
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
    
    pid_t pid = aPid;
    ret = proc_pidpath (pid, pathbuf, sizeof(pathbuf));
    if ( ret <= 0 ) {
        logit(lcl_vError,@"PID %d: proc_pidpath ()", pid);
        logit(lcl_vError,@"%s", strerror(errno));
    } else {
        logit(lcl_vDebug,@"proc %d: %s", pid, pathbuf);
    }
    
    return [NSString stringWithUTF8String:pathbuf];
}

#pragma mark - MPWorkerProtocol implementation

- (void)getVersionWithReply:(void(^)(NSString *verData))reply
{
	reply(@"1");
}

- (void)getTestWithReply:(void(^)(NSString *aString))reply
{
    // We specifically don't check for authorization here.  Everyone is always allowed to get
    // the version of the helper tool.
	
	
	MPConfigProfiles *p = [[MPConfigProfiles alloc] init];
	NSArray *cp = [p readProfileStoreReturnAsConfigProfile];
	NSString *str = [NSString stringWithFormat:@"Profiles Found %lu",(unsigned long)cp.count];
	
    qldebug(@"getTestWithReply");
    reply(str);
}

- (void)getProfilesWithReply:(void(^)(NSString *aString, NSData *aData))reply
{
	// We specifically don't check for authorization here.  Everyone is always allowed to get
	// the version of the helper tool.
	
	qlinfo(@"Scan For Installed Config Profiles");
	MPConfigProfiles *p = [[MPConfigProfiles alloc] init];
	NSArray *cp = [p readProfileStoreReturnAsConfigProfile];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cp];
	NSString *str = [NSString stringWithFormat:@"Profiles Found %lu",(unsigned long)cp.count];
	
	qldebug(@"getProfilesWithReply");
	reply(str,data);
}

#pragma mark • ASUS

// ASUS

// Delegate Method
- (void)appleScanProgress:(NSString *)data
{
	//qlinfo(@"appleScanProgress: %@",[data trim]);
	//[self postPatchStatus:[data trim]];
	[self postStatus:[data trim]];
}

#pragma mark • ASUS Helpers

- (NSString *)getSizeFromDescription:(NSString *)aDescription
{
    NSArray *tmpArr1 = [aDescription componentsSeparatedByString:@","];
    NSArray *tmpArr2 = [[[tmpArr1 objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "];
    return [[tmpArr2 objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)getRecommendedFromDescription:(NSString *)aDescription
{
    NSRange textRange;
    textRange =[aDescription rangeOfString:@"recommended"];
    
    if(textRange.location != NSNotFound) {
        return @"Y";
    } else {
        return @"N";
    }
    
    return @"N";
}

#pragma mark • Patching

- (void)scanForPatchesUsingFilter:(MPPatchContentType)patchType withReply:(void(^)(NSError *error, NSData *patches, NSData *patchGroupData))reply
{
	NSError			*error = nil;
	NSDictionary 	*patches;
	NSArray 		*requiredPatches = [NSArray array];
	
	// Get Patch Group Patches
	NSError *wsErr = nil;
	MPRESTfull *mprest = [[MPRESTfull alloc] init];
	NSDictionary *patchGroupPatches = [mprest getApprovedPatchesForClient:&wsErr];
	if (wsErr) {
		qlerror(@"Error: %@",wsErr.localizedDescription);
	}
	[self postStatus:@"Scan host for patches..."];
	
	MPPatching *mpPatching = [MPPatching new];
	mpPatching.delegate = self;
	if (patchType == kAllActivePatches) {
		requiredPatches = [mpPatching scanForPatchesUsingTypeFilterOrBundleIDWithPatchAll:kAllPatches bundleID:NULL forceRun:NO patchAllFound:YES];
	} else {
		requiredPatches = [mpPatching scanForPatchesUsingTypeFilter:patchType forceRun:NO];
	}
	
	// Create Patch Dict
	patches = @{@"apple":@[], @"custom": @[], @"required": requiredPatches};
	error = nil;
	NSData *_patchesData = [NSKeyedArchiver archivedDataWithRootObject:patches];
	NSData *_patchGroupPatches = [NSKeyedArchiver archivedDataWithRootObject:patchGroupPatches];
	
	[_patchesData writeToFile:@"/var/tmp/patches.plist" atomically:NO];
	[_patchGroupPatches writeToFile:@"/var/tmp/patchGroupPatches.plist" atomically:NO];
	
	reply(error, _patchesData, _patchGroupPatches);
}

- (void)installPatch:(NSDictionary *)patch withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode))reply
{
	NSInteger result = 0;
	qlinfo(@"Install Patch: %@",patch[@"patch"]);
	qldebug(@"Patch: %@",patch);
	
	MPPatching *patching = [MPPatching new];
	patching.delegate = self;
	NSDictionary *patchResult = [patching installPatchUsingTypeFilter:patch typeFilter:kAllPatches];
	
	if (patchResult[@"patchInstallErrors"]) {
		qldebug(@"patchResult[patchInstallErrors] = %d",[patchResult[@"patchInstallErrors"] intValue]);
		if ([patchResult[@"patchInstallErrors"] integerValue] >= 1)
		{
			qlerror(@"Error installing %@",patch[@"patch"]);
			result = 1;
		}
	} else {
		result = 9999;
	}
	
	qltrace(@"result = %ld",(long)result);
	[self postPatchStatus:@"%@ install complete", patch[@"patch"]];
	reply(nil,result);
}

- (void)installPatch:(NSDictionary *)patch userInstallRebootPatch:(int)installRebootPatch withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode))reply
{
	NSInteger result = 0;
	qlinfo(@"Install Patch: %@",patch[@"patch"]);
	qldebug(@"Patch: %@",patch);
	
	MPPatching *patching = [MPPatching new];
	patching.delegate = self;
	[self postPatchStatus:@"Begin %@ install", patch[@"patch"]];
	if (installRebootPatch == 1) {
		[patching setInstallRebootPatchesWhileLoggedIn:YES];
	}
	NSDictionary *patchResult = [patching installPatchUsingTypeFilter:patch typeFilter:kAllPatches];
	qltrace(@"patchResult: %@",patchResult);
	if (patchResult[@"patchInstallErrors"]) {
		if ([patchResult[@"patchInstallErrors"] integerValue] >= 1)
		{
			qlerror(@"Error installing %@",patch[@"patch"]);
			result = 1;
		} else {
			// No Errors detected
			if (patchResult[@"patchesRequireHalt"]) {
				// Patch Requires a halt/shutdown ... this is for Apple Patches with firmware
				if ([patchResult[@"patchInstallErrors"] intValue] >= 1) {
					result = 1000;
				}
			}
		}
	} else {
		result = 9999;
	}
	
	qltrace(@"result = %ld",(long)result);
	[self postPatchStatus:@"%@ install complete", patch[@"patch"]];
	reply(nil,result);
}

- (void)installPatches:(NSArray *)patches withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode))reply
{
	int patchCount = 0;
	double patchProgress = 0.0;
	NSInteger result = 0;
	MPPatching *patching = [MPPatching new];
    
    NSMutableArray *_patches = [NSMutableArray arrayWithArray:patches];
    for (NSDictionary *d in _patches) {
        if ([d[@"type"] isEqualToString:@"Apple"]) {
            if ([d[@"restart"] isEqualToString:@"Yes"]) {
                NSMutableDictionary *m = [d mutableCopy];
                [m setObject:@(999) forKey:@"order"];
                [_patches replaceObjectAtIndex:[_patches indexOfObject:d] withObject:m];
            }
        }
    }
    
    //Sort the patches and force Apple reboot to last...
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSMutableArray *_sortedPatches = [NSMutableArray arrayWithArray:[_patches sortedArrayUsingDescriptors:@[descriptor]]];
    
    // Take last item of the Array add force reboot key
    // Make sure its a Apple Patch and a reboot patch
    NSMutableDictionary *lastPatch = [[_sortedPatches lastObject] mutableCopy];
    if ([lastPatch[@"type"] isEqualToString:@"Apple"]) {
        if ([lastPatch[@"restart"] isEqualToString:@"Yes"]) {
            [lastPatch setObject:@"1" forKey:@"forceAppleReboot"];
        }
        [_sortedPatches replaceObjectAtIndex:[_sortedPatches indexOfObject:[_sortedPatches lastObject]] withObject:lastPatch];
    }
    
	[self postPatchStatus:@"Installing all patches ..."];
	for (NSDictionary *patch in _sortedPatches)
	{
		qlinfo(@"Install Patch: %@",patch[@"patch"]);
		qldebug(@"Patch: %@",patch);
        
        NSString *_patchID;
        if ([[patch[@"type"] uppercaseString] isEqualToString:@"APPLE"]) {
            _patchID = patch[@"patch"];
        } else {
            _patchID = patch[@"patch_id"];
        }
		
		[self postPatchAllStatus:@"Begin %@ install...", patch[@"patch"]];
		NSDictionary *patchResult = [patching installPatchUsingTypeFilter:patch typeFilter:kAllPatches];
		
		if (patchResult[@"patchInstallErrors"])
		{
			if ([patchResult[@"patchInstallErrors"] integerValue] >= 1)
			{
				qlerror(@"Error installing %@",patch[@"patch"]);
				result = result + 1;
				[self postPatchInstallError:_patchID];
			} else {
				[self postPatchInstallCompletion:_patchID];
			}
		} else {
			[self postPatchInstallCompletion:_patchID];
		}
		
		patchCount = patchCount + 1;
		patchProgress = patchCount / patches.count;
		[self postPatchAllProgress:patchCount];
	}

	qltrace(@"result = %ld",(long)result);
	[self postPatchStatus:@"%d install(s) completed.", patchCount];
	reply(nil,result);
}

- (void)installPatches:(NSArray *)patches userInstallRebootPatch:(int)installRebootPatch withReply:(nullable void(^)(NSError * _Nullable error, NSInteger resultCode))reply
{
	int patchCount = 0;
	double patchProgress = 0.0;
	NSInteger result = 0;
	MPPatching *patching = [MPPatching new];
    patching.delegate = self;
	if (installRebootPatch == 1) {
		[patching setInstallRebootPatchesWhileLoggedIn:YES];
	}
	
	[self postPatchStatus:@"Installing all patches ..."];
	for (NSDictionary *patch in patches)
	{
		qlinfo(@"Install Patch: %@",patch[@"patch"]);
		qldebug(@"Patch: %@",patch);
        
        NSString *_patchID;
        if ([[patch[@"type"] uppercaseString] isEqualToString:@"APPLE"]) {
            _patchID = patch[@"patch"];
        } else {
            _patchID = patch[@"patch_id"];
        }
		
		[self postPatchAllStatus:@"Begin %@ install...", patch[@"patch"]];
		NSDictionary *patchResult = [patching installPatchUsingTypeFilter:patch typeFilter:kAllPatches];
        qldebug(@"patchResult: %@",patchResult);
		if (patchResult[@"patchInstallErrors"])
		{
			if ([patchResult[@"patchInstallErrors"] integerValue] >= 1)
			{
				qlerror(@"Error installing %@",patch[@"patch"]);
				result = result + 1;
				[self postPatchInstallError:_patchID];
			} else {
				[self postPatchInstallCompletion:_patchID];
			}
		} else {
			[self postPatchInstallCompletion:_patchID];
		}
		
		patchCount = patchCount + 1;
		patchProgress = patchCount / patches.count;
		[self postPatchAllProgress:patchCount];
	}

	qltrace(@"result = %ld",(long)result);
	[self postPatchStatus:@"%d install(s) completed.", patchCount];
	reply(nil,result);
}


// Private
- (BOOL)postDataToWS:(NSString *)urlPath data:(NSDictionary *)data
{
	MPHTTPRequest *req;
	MPWSResult *result;
	
	req = [[MPHTTPRequest alloc] init];
	result = [req runSyncPOST:urlPath body:data];
	
	if (result.statusCode >= 200 && result.statusCode <= 299) {
		logit(lcl_vInfo,@"[MPAgentExecController][postDataToWS]: Data post to web service (%@), returned true.", urlPath);
		//logit(lcl_vDebug,@"Data post to web service (%@), returned true.", urlPath);
		logit(lcl_vDebug,@"Data Result: %@",result.result);
	} else {
		logit(lcl_vError,@"Data post to web service (%@), returned false.", urlPath);
		logit(lcl_vDebug,@"%@",result.toDictionary);
		return NO;
	}
	
	return YES;
}

- (NSArray *)scanForAppleUpdates:(NSError **)error
{
	/*
	 1. Get Scan List
	 2. Scan for patches
	 3. Post patches needed
	 */
	NSError *wsErr = nil;
	MPRESTfull *mprest = [[MPRESTfull alloc] init];
	NSDictionary *patchGroupPatches = [mprest getApprovedPatchesForClient:&wsErr];
	if (wsErr) {
		qlerror(@"Error: %@",wsErr.localizedDescription);
	}
	qltrace(@"patchGroupPatches: %@",patchGroupPatches);
	
	
	MPASUSCatalogs *m = [[MPASUSCatalogs alloc] init];
	[m checkAndSetCatalogURL];
	
	NSArray *patches = [NSArray array];
	MPAsus *asus = [[MPAsus alloc] init];
	asus.delegate = self;
	
	patches = [asus scanForAppleUpdates];
	return patches;
}

- (NSArray *)scanForAppleUpdatesAlt:(NSError **)error
{
    NSError *err = nil;
    qlinfo(@"Scanning for Apple software updates.");
	[self postPatchStatus:@"Scanning for Apple software updates."];
    
    NSData *result;
    NSArray *appleUpdates = nil;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: ASUS_BIN_PATH];
    [task setArguments: [NSArray arrayWithObjects: @"-l", nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    qlinfo(@"Starting Apple software update scan.");
    [task waitUntilExit];
    
    int status = [task terminationStatus];
    if (status == 0) {
        qlinfo(@"Apple software update scan was completed.");
		[self postPatchStatus:@"Apple software update scan was completed."];
        
        NSData *data = [file readDataToEndOfFile];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        qlinfo(@"Apple software update full scan results\n%@",string);
        
        if (!([string rangeOfString:@"No new"].location == NSNotFound)) {
            qlinfo(@"No new updates.");
        } else {
            // We have updates so we need to parse the results
            NSArray *strArr = [NSArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
            
            NSMutableArray *tmpAppleUpdates = [NSMutableArray new];
            NSString *tmpStr;
            NSMutableDictionary *tmpDict;
            
            for (int i=0; i<[strArr count]; i++) {
                // Ignore empty lines
                if ([[strArr objectAtIndex:i] length] != 0) {
                    
                    //Clear the tmpDict object before populating it
                    if (!([[strArr objectAtIndex:i] rangeOfString:@"Software Update Tool"].location == NSNotFound)) {
                        continue;
                    }
                    if (!([[strArr objectAtIndex:i] rangeOfString:@"Copyright"].location == NSNotFound)) {
                        continue;
                    }
                    
                    // Strip the White Space and any New line data
                    tmpStr = [[strArr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    // If the object/string starts with *,!,- then allow it
                    if ([[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"*"] || [[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"!"] || [[tmpStr substringWithRange:NSMakeRange(0,1)] isEqual:@"-"]) {
                        tmpDict = [[NSMutableDictionary alloc] init];
                        qlinfo(@"Apple Update: %@",[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))]);
                        [tmpDict setObject:[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))] forKey:@"patch"];
                        [tmpDict setObject:@"Apple" forKey:@"type"];
                        [tmpDict setObject:[[[tmpStr substringWithRange:NSMakeRange(2,([tmpStr length]-2))] componentsSeparatedByString:@"-"] lastObject] forKey:@"version"];
                        [tmpDict setObject:[[strArr objectAtIndex:(i+1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"description"];
                        [tmpDict setObject:[self getSizeFromDescription:[tmpDict objectForKey:@"description"]] forKey:@"size"];
                        [tmpDict setObject:[self getRecommendedFromDescription:[tmpDict objectForKey:@"description"]] forKey:@"recommended"];
                        if ([[[strArr objectAtIndex:(i+1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] containsString:@"[restart]" ignoringCase:YES] == TRUE) {
                            [tmpDict setObject:@"Y" forKey:@"restart"];
                        } else {
                            [tmpDict setObject:@"N" forKey:@"restart"];
                        }
                        
                        [tmpAppleUpdates addObject:tmpDict];
                    } // if is an update
                } // if / empty lines
            } // for loop
            
            appleUpdates = [NSArray arrayWithArray:tmpAppleUpdates];
            logit(lcl_vDebug,@"Apple Updates Found, %@",appleUpdates);
            
            err = nil;
            result = [self encodeResult:[NSKeyedArchiver archivedDataWithRootObject:appleUpdates] error:&err];
            if (err) {
                logit(lcl_vDebug,@"%@",err.localizedDescription);
            }
        }
    } else {
        NSString *errStr = [NSString stringWithFormat:@"Error: softwareupdate exit code = %d",status];
        logit(lcl_vError,@"%@",errStr);
        NSDictionary *errDetail = @{NSLocalizedDescriptionKey:errStr};
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"gov.llnl.mp.worker" code:101 userInfo:errDetail];
        }
    }
	
    return nil;
}

- (void)scanAndPatchSoftwareItem:(NSDictionary *)aSWDict withReply:(void(^)(NSError *error, NSInteger result))reply
{
    NSError *err = nil;
    @try {
		/*
        MPScanAndPatch *ma = [[MPScanAndPatch alloc] initForBundleUpdate];
        [ma scanAndUpdateCustomWithPatchBundleID:[aSWDict valueForKeyPath:@"Software.patch_bundle_id"]];
        res = [ma errorCode];
        reply(err, res);
		 */
		reply(NULL,0);
    } @catch (NSException *exception) {
        
        NSMutableDictionary * info = [NSMutableDictionary dictionary];
        [info setValue:exception.name forKey:@"ExceptionName"];
        [info setValue:exception.reason forKey:@"ExceptionReason"];
        [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
        [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
        [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];
        
        err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:1 userInfo:info];
        reply(err,1);
    }

    reply(err,1);
}

- (void)setPatchOnLogoutWithReply:(void(^)(BOOL result))reply
{
	BOOL res = YES;
	NSError *err = nil;
	NSString *_atFile = @"/private/tmp/.MPAuthRun";
	NSString *_rbText = @"reboot";
	// Mac OS X 10.9 Support, now using /private/tmp/.MPAuthRun
	[_rbText writeToFile:_atFile atomically:YES encoding:NSUTF8StringEncoding error:&err];
	if (err)
	{
		qlerror(@"Error setting patch on logout file.");
		qlerror(@"%@",err.localizedDescription);
		res = NO;
	}
	else
	{
		NSDictionary *_fileAttr = @{@"NSFilePosixPermissions":[NSNumber numberWithUnsignedLong:0777]};
		[fm setAttributes:_fileAttr ofItemAtPath:_atFile error:NULL];
	}
	reply(res);
}

- (void)setStateOnPausePatching:(MPPatchingPausedState)state withReply:(void(^)(BOOL result))reply
{
	BOOL res = YES;
	NSString *_file = @"/private/var/db/.MPPatchState.plist";
	NSDictionary *data;

	if (state == kPatchingPausedOn) {
		data = @{@"pausePatching":[NSNumber numberWithBool:YES]};
	} else {
		data = @{@"pausePatching":[NSNumber numberWithBool:NO]};
	}

	if (![data writeToFile:_file atomically:NO])
	{
		qlerror(@"Error setting paused patching state to file.");
		res = NO;
	}
	else
	{
		NSDictionary *_fileAttr = @{@"NSFilePosixPermissions":[NSNumber numberWithUnsignedLong:0777]};
		[fm setAttributes:_fileAttr ofItemAtPath:_file error:NULL];
	}
	reply(res);
}

#pragma mark Patching Delegate methods
- (void)patchingProgress:(MPPatching *)mpPatching progress:(NSString *)progressStr
{
	[self postStatus:progressStr];
}


#pragma mark • Software
- (void)installSoftware:(NSDictionary *)swItem withReply:(void(^)(NSError *error, NSInteger resultCode, NSData *installData))reply
{
    //__block NSError *err;
    //__block NSInteger res;
    //__block NSData *resData;
    // Default timeout is 30min
    [self installSoftware:swItem timeOut:1800 withReply:^(NSError *error, NSInteger resultCode, NSData *installData) {
        //err = error;
        //res = resultCode;
        //resData = installData;
        reply(error, resultCode, installData);
    }];
}


// CEH - Needs to be updated to support MPSoftware
//- (void)installSoftware:(NSDictionary *)swItem withReply:(void(^)(NSError *error, NSInteger resultCode, NSData *installData))reply
- (void)installSoftware:(NSDictionary *)swItem timeOut:(NSInteger)timeout withReply:(void(^)(NSError *error, NSInteger resultCode, NSData *installData))reply
{
	qlinfo(@"Start install of %@",swItem[@"name"]);
	qldebug(@"swItem: %@",swItem);
    self->swTaskTimeoutValue = (int)timeout;
    
	NSError *err = nil;
	NSString *errStr;
	NSInteger result = 99; // Default result
	NSData *installResultData = [NSData data];
	
	NSString *pkgType = [swItem valueForKeyPath:@"Software.sw_type"];
	
	MPFileUtils *fu;
	NSString *fHash = nil;
	MPScript *mpScript;
	MPCrypto *mpCrypto = [[MPCrypto alloc] init];
	
	if (!SW_DATA_DIR) {
		SW_DATA_DIR = [self swDataDirURL];
	}
	NSString *dlSoftwareFileName = [[swItem valueForKeyPath:@"Software.sw_url"] lastPathComponent];
	NSString *dlSoftwareFile = [NSString pathWithComponents:@[[SW_DATA_DIR path],@"sw",swItem[@"id"],dlSoftwareFileName]];
	
	// -----------------------------------------
	// Download Software
	// -----------------------------------------
	[self downloadSoftware:[swItem copy] toDestination:[dlSoftwareFile stringByDeletingLastPathComponent]];
	
	if ([pkgType isEqualToString:@"SCRIPTZIP" ignoringCase:YES])
	{
		qlinfo(@"Software Task is of type %@.",pkgType);
		// ------------------------------------------------
		// Check File Hash
		// ------------------------------------------------
		[self postStatus:@"Checking file hash..."];
		fHash = [mpCrypto md5HashForFile:dlSoftwareFile];
		if (![fHash isEqualToString:[swItem valueForKeyPath:@"Software.sw_hash"] ignoringCase:YES])
		{
			errStr = [NSString stringWithFormat:@"Error unable to verify software hash for file %@.",dlSoftwareFileName];
			qlerror(@"%@", errStr);
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPFileHashCheckError userInfo:@{NSLocalizedDescriptionKey:errStr}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Unzip Software
		// ------------------------------------------------
		[self postStatus:[NSString stringWithFormat:@"Unzipping file %@.",dlSoftwareFileName]];
		qlinfo(@"Unzipping file %@.",dlSoftwareFile);
		fu = [MPFileUtils new];
		BOOL res = [fu unzipItemAtPath:dlSoftwareFile targetPath:[dlSoftwareFile stringByDeletingLastPathComponent] error:&err];
		if (!res || err) {
			if (err) {
				errStr = [NSString stringWithFormat:@"Error unzipping file %@. %@",dlSoftwareFile,[err description]];
				qlerror(@"%@", errStr);
			} else {
				errStr = [NSString stringWithFormat:@"Error unzipping file %@.",dlSoftwareFile];
				qlerror(@"%@", errStr);
			}
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPFileUnZipError userInfo:@{NSLocalizedDescriptionKey:errStr}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Run Pre Install Script
		// ------------------------------------------------
		[self postStatus:@"Running pre-install script..."];
		if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_pre_install"] type:0]) {
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPreInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running pre-insatll script."}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Run Download Script
		// ------------------------------------------------
		[self postStatus:@"Running script..."];
		err = nil;
		mpScript = [[MPScript alloc] init];
		if (![mpScript runScriptsFromDirectory:[dlSoftwareFile stringByDeletingLastPathComponent] error:&err]) {
			result = 1;
			if (err) {
				qlerror(@"%@", err.localizedDescription);
			}
			reply(err,1,installResultData);
			return;
		} else {
			result = 0;
		}
		
		// ------------------------------------------------
		// Run Post Install Script, if copy was good
		// ------------------------------------------------
		if (result == 0)
		{
			[self postStatus:@"Running post-install script..."];
			if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_post_install"] type:0]) {
				err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPostInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running post-insatll script."}];
			}
		}
	}
	else if ([pkgType isEqualToString:@"PACKAGEZIP" ignoringCase:YES])
	{
		qlinfo(@"Software Task is of type %@.",pkgType);
		// ------------------------------------------------
		// Check File Hash
		// ------------------------------------------------
		[self postStatus:@"Checking file hash..."];
		fHash = [mpCrypto md5HashForFile:dlSoftwareFile];
		if (![fHash isEqualToString:[swItem valueForKeyPath:@"Software.sw_hash"] ignoringCase:YES])
		{
			errStr = [NSString stringWithFormat:@"Error unable to verify software hash for file %@.",dlSoftwareFileName];
			qlerror(@"%@", errStr);
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPFileHashCheckError userInfo:@{NSLocalizedDescriptionKey:errStr}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Unzip Software
		// ------------------------------------------------
		[self postStatus:[NSString stringWithFormat:@"Unzipping file %@.",dlSoftwareFileName]];
		qlinfo(@"Unzipping file %@.",dlSoftwareFile);
		fu = [MPFileUtils new];
		BOOL res = [fu unzipItemAtPath:dlSoftwareFile targetPath:[dlSoftwareFile stringByDeletingLastPathComponent] error:&err];
		if (!res || err) {
			if (err) {
				errStr = [NSString stringWithFormat:@"Error unzipping file %@. %@",dlSoftwareFile,[err description]];
				qlerror(@"%@", errStr);
			} else {
				errStr = [NSString stringWithFormat:@"Error unzipping file %@.",dlSoftwareFile];
				qlerror(@"%@", errStr);
			}
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPFileUnZipError userInfo:@{NSLocalizedDescriptionKey:errStr}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Run Pre Install Script
		// ------------------------------------------------
		[self postStatus:@"Running pre-install script..."];
		if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_pre_install"] type:0]) {
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPreInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running pre-insatll script."}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Install PKG
		// ------------------------------------------------
		[self postStatus:@"Installing %@",dlSoftwareFile.lastPathComponent];
		result = [self installPkgFromZIP:[dlSoftwareFile stringByDeletingLastPathComponent] environment:swItem[@"pkgEnv"]];
		
		// ------------------------------------------------
		// Run Post Install Script, if copy was good
		// ------------------------------------------------
		if (result == 0)
		{
			[self postStatus:@"Running post-install script..."];
			if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_post_install"] type:0]) {
				err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPostInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running post-insatll script."}];
			}
		}
	}
	else if ([pkgType isEqualToString:@"APPZIP" ignoringCase:YES])
	{
		qlinfo(@"Software Task is of type %@.",pkgType);
		// ------------------------------------------------
		// Check File Hash
		// ------------------------------------------------
		[self postStatus:@"Checking file hash..."];
		fHash = [mpCrypto md5HashForFile:dlSoftwareFile];
		if (![fHash isEqualToString:[swItem valueForKeyPath:@"Software.sw_hash"] ignoringCase:YES])
		{
			errStr = [NSString stringWithFormat:@"Error unable to verify software hash for file %@.",dlSoftwareFileName];
			qlerror(@"%@", errStr);
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPFileHashCheckError userInfo:@{NSLocalizedDescriptionKey:errStr}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Unzip Software
		// ------------------------------------------------
		[self postStatus:[NSString stringWithFormat:@"Unzipping file %@.",dlSoftwareFileName]];
		qlinfo(@"Unzipping file %@.",dlSoftwareFile);
		fu = [MPFileUtils new];
		BOOL res = [fu unzipItemAtPath:dlSoftwareFile targetPath:[dlSoftwareFile stringByDeletingLastPathComponent] error:&err];
		if (!res || err) {
			if (err) {
				errStr = [NSString stringWithFormat:@"Error unzipping file %@. %@",dlSoftwareFile,[err description]];
				qlerror(@"%@", errStr);
			} else {
				errStr = [NSString stringWithFormat:@"Error unzipping file %@.",dlSoftwareFile];
				qlerror(@"%@", errStr);
			}
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPFileUnZipError userInfo:@{NSLocalizedDescriptionKey:errStr}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Run Pre Install Script
		// ------------------------------------------------
		[self postStatus:@"Running pre-install script..."];
		if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_pre_install"] type:0]) {
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPreInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running pre-insatll script."}];
			reply(err,1,installResultData);
			return;
		}
		
		// ------------------------------------------------
		// Copy App To Applications
		// ------------------------------------------------
		NSString *swUnzipDir = NULL;
		NSString *swUnzipDirBase = [[SW_DATA_DIR path] stringByAppendingPathComponent:@"sw"];
		swUnzipDir = [swUnzipDirBase stringByAppendingPathComponent:swItem[@"id"]];
		[self postStatus:[NSString stringWithFormat:@"Installing %@ to Applications.",[swUnzipDir lastPathComponent]]];
		result = [self copyAppFrom:swUnzipDir action:kMPMoveFile error:NULL];
		
		// ------------------------------------------------
		// Run Post Install Script, if copy was good
		// ------------------------------------------------
		if (result == 0)
		{
			[self postStatus:@"Running post-install script..."];
			if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_post_install"] type:0]) {
				err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPostInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running post-insatll script."}];
			}
		}
	}
	else if ([pkgType isEqualToString:@"PACKAGEDMG" ignoringCase:YES])
	{
		qlinfo(@"Software Task is of type %@.",pkgType);
		// ------------------------------------------------
		// Check File Hash
		// ------------------------------------------------
		[self postStatus:@"Checking file hash..."];
		fHash = [mpCrypto md5HashForFile:dlSoftwareFile];
		if (![fHash isEqualToString:[swItem valueForKeyPath:@"Software.sw_hash"] ignoringCase:YES])
		{
			errStr = [NSString stringWithFormat:@"Error unable to verify software hash for file %@.",dlSoftwareFileName];
			qlerror(@"%@", errStr);
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPFileHashCheckError userInfo:@{NSLocalizedDescriptionKey:errStr}];
			reply(err,1,installResultData);
		}

		// ------------------------------------------------
		// Mount DMG
		// ------------------------------------------------
		int m = -1;
		m = [self mountDMG:dlSoftwareFile packageID:swItem[@"id"]];
		if (m != 0) {
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPMountDMGError userInfo:@{NSLocalizedDescriptionKey:@"Error mounting dmg."}];
			reply(err,1,installResultData);
		}
		
		// ------------------------------------------------
		// Run Pre Install Script
		// ------------------------------------------------
		[self postStatus:@"Running pre-install script..."];
		if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_pre_install"] type:0]) {
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPreInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running pre-insatll script."}];
			reply(err,1,installResultData);
		}
		
		// ------------------------------------------------
		// Install PKG
		// ------------------------------------------------
		[self postStatus:@"Installing %@",dlSoftwareFileName];
		result = [self installPkgFromDMG:swItem[@"id"] environment:[swItem valueForKeyPath:@"Software.sw_env_var"]];

		// ------------------------------------------------
		// Run Post Install Script
		// ------------------------------------------------
		if (result == 0) {
			[self postStatus:@"Running post-install script..."];
			if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_post_install"] type:0]) {
				err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPostInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running post-insatll script."}];
			}
		}
	}
	else if ([pkgType isEqualToString:@"APPDMG" ignoringCase:YES])
	{
		qlinfo(@"Software Task is of type %@.",pkgType);
		// ------------------------------------------------
		// Check File Hash
		// ------------------------------------------------
		[self postStatus:@"Checking file hash..."];
		fHash = [mpCrypto md5HashForFile:dlSoftwareFile];
		if (![fHash isEqualToString:[swItem valueForKeyPath:@"Software.sw_hash"] ignoringCase:YES])
		{
			errStr = [NSString stringWithFormat:@"Error unable to verify software hash for file %@.",dlSoftwareFileName];
			qlerror(@"%@", errStr);
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPFileHashCheckError userInfo:@{NSLocalizedDescriptionKey:errStr}];
			reply(err,1,installResultData);
		}
		
		// ------------------------------------------------
		// Mount DMG
		// ------------------------------------------------
		int m = -1;
		m = [self mountDMG:dlSoftwareFile packageID:swItem[@"id"]];
		if (m != 0) {
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPMountDMGError userInfo:@{NSLocalizedDescriptionKey:@"Error mounting dmg."}];
			reply(err,1,installResultData);
		}
		
		// ------------------------------------------------
		// Run Pre Install Script
		// ------------------------------------------------
		[self postStatus:@"Running pre-install script..."];
		if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_pre_install"] type:0]) {
			err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPreInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running pre-insatll script."}];
			reply(err,1,installResultData);
		}
		
		// ------------------------------------------------
		// Copy App To Applications
		// ------------------------------------------------
		[self postStatus:@"Installing %@",dlSoftwareFileName];
		result = [self copyAppFromDMG:swItem[@"id"]];
		
		// ------------------------------------------------
		// Run Post Install Script
		// ------------------------------------------------
		if (result == 0) {
			[self postStatus:@"Running post-install script..."];
			if (![self runSWInstallScript:[swItem valueForKeyPath:@"Software.sw_post_install"] type:0]) {
				err = [NSError errorWithDomain:MPXPCErrorDomain code:MPPostInstallScriptError userInfo:@{NSLocalizedDescriptionKey:@"Error running post-insatll script."}];
			}
		}
	}
	else
	{
		qlerror(@"Install Type Not Supported for %@",swItem[@"name"]);
		// Install Type Not Supported
		result = 2;
	}
	
	
	if (result == 0)
	{
		if ([[swItem valueForKeyPath:@"Software.auto_patch"] intValue] == 1) {
			err = nil;
			// Install Pathes If Enabled
			[self postStatus:@"Patching %@",swItem[@"name"]];
			MPPatching *p = [MPPatching new];
			NSArray *foundPatches = [p scanForPatchUsingBundleID:[swItem valueForKeyPath:@"Software.patch_bundle_id"]];
			if (foundPatches)
			{
				if (foundPatches.count >= 1)
				{
					[p installPatchesUsingTypeFilter:foundPatches typeFilter:kCustomPatches];
				}
			}
		}
	}
    
    NSDictionary *wsRes = @{@"tuuid":swItem[@"id"],
                            @"suuid":[swItem valueForKeyPath:@"Software.sid"],
                            @"action":@"i",
                            @"result":[NSString stringWithFormat:@"%d",(int)result],
                            @"resultString":@""};
    MPRESTfull *mpr = [MPRESTfull new];
    err = nil;
    [mpr postSoftwareInstallResults:wsRes error:&err];
    if (err) {
        qlerror(@"Error posting software install results.");
        qlerror(@"%@",err.localizedDescription);
    }
	
	reply(err,result,installResultData);
}

- (BOOL)downloadSoftware:(NSDictionary *)swTask toDestination:(NSString *)toPath
{
    qlinfo(@"downloadSoftware for task %@",swTask[@"name"]);
	NSString *_url;
	NSInteger useS3 = [[swTask valueForKeyPath:@"Software.sw_useS3"] integerValue];
	if (useS3 == 1) {
		MPRESTfull *mpr = [MPRESTfull new];
		NSDictionary *res = [mpr getS3URLForType:@"sw" id:swTask[@"id"]];
		if (res) {
			_url = res[@"url"];
		} else {
			qlerror(@"Result from getting the S3 url was nil. No download can occure.");
			return FALSE;
		}
	} else {
		_url = [NSString stringWithFormat:@"/mp-content%@",[swTask valueForKeyPath:@"Software.sw_url"]];
	}
	
	NSError *dlErr = nil;
	MPHTTPRequest *req = [[MPHTTPRequest alloc] init];
	req.delegate = self;
	NSString *dlPath = [req runSyncFileDownload:_url downloadDirectory:toPath error:&dlErr];
	qldebug(@"Downloaded software to %@",dlPath);
	return YES;
}

// Run Software Scripts
- (void)runScriptFromString:(NSString *)script withReply:(void(^)(NSError * error, NSInteger result))reply
{
    NSError  *err = nil;
    MPScript *mps = nil;
    int res = 0;
    mps = [[MPScript alloc] init];
    if ([mps runScript:script]) {
        res = 0;
    } else {
        res = 1;
    }
    
    mps = nil;
    reply(err,res);
}

- (void)runScriptFromFile:(NSString *)script withReply:(void(^)(NSError * error, NSInteger result))reply
{
    NSError  *err = nil;
    NSString *scriptText = nil;
    MPScript *mps = nil;
    int res = 0;
    scriptText = [NSString stringWithContentsOfFile:script encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        logit(lcl_vError,@"Error reading script string: %@",[err description]);
        logit(lcl_vError,@"%@",[err description]);
        reply(err,3);
        return;
    }
    
    mps = [[MPScript alloc] init];
    if ([mps runScript:scriptText]) {
        res = 0;
    } else {
        res = 1;
    }
    
    mps = nil;
    reply(err,res);
}

- (void)runScriptFromDirectory:(NSString *)scriptDir withReply:(void(^)(NSError *error, NSInteger result))reply
{
    int result = 0;
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:scriptDir error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.sh') OR (SELF like [cd] '*.rb') OR (SELF like [cd] '*.py')"];
    NSArray *onlyScripts = [dirContents filteredArrayUsingPredicate:fltr];
    
    NSError *err = nil;
    NSString *scriptText = nil;
    MPScript *mps = nil;
    for (NSString *scpt in onlyScripts)
    {
        err = nil;
        scriptText = [NSString stringWithContentsOfFile:[scriptDir stringByAppendingPathComponent:scpt] encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            logit(lcl_vError,@"Error reading script string: %@",[err description]);
            logit(lcl_vError,@"%@",[err description]);
            result = 3;
            break;
        }
        mps = [[MPScript alloc] init];
        if ([mps runScript:scriptText]) {
            result = 0;
        } else {
            result = 1;
            break;
        }
        mps = nil;
    }
    
    reply(err,result);
}

// Run Software Package Install
- (void)installPackageFromZIP:(NSString *)pkgID environment:(NSString *)env withReply:(void(^)(NSError *error, NSInteger result))reply
{
    int result = 0;
    NSString *mountPoint = NULL;
    mountPoint = [NSString pathWithComponents:@[[SW_DATA_DIR path],@"sw",pkgID]];
    
    NSArray     *dirContents = [fm contentsOfDirectoryAtPath:mountPoint error:nil];
    NSPredicate *fltr        = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
    NSArray     *onlyPkgs    = [dirContents filteredArrayUsingPredicate:fltr];
    
    NSArray *installArgs;
    NSString *pkgPath;
    for (NSString *pkg in onlyPkgs)
    {
        pkgPath = [NSString pathWithComponents:@[[SW_DATA_DIR path],@"sw",pkgID, pkg]];
        installArgs = @[@"-verboseR", @"-pkg", pkgPath, @"-target", @"/"];
        
        if ([self runTask:INSTALLER_BIN_PATH binArgs:installArgs environment:env] != 0) {
            result++;
        }
        
        pkgPath = nil;
    }
    
    reply(nil,result);
}

// Copy Application To Applications Directory
- (void)copyAppFromDirToApplications:(NSString *)aDir action:(int)action withReply:(void(^)(NSError *error, NSInteger result))reply
{
    int result = 0;
    NSArray     *dirContents = [fm contentsOfDirectoryAtPath:aDir error:nil];
    NSPredicate *fltr        = [NSPredicate predicateWithFormat:@"self ENDSWITH '.app'"];
    NSArray     *onlyApps    = [dirContents filteredArrayUsingPredicate:fltr];
    NSError     *err         = nil;
    
    for (NSString *app in onlyApps)
    {
        if ([fm fileExistsAtPath:[@"/Applications"  stringByAppendingPathComponent:app]]) {
            qldebug(@"Found, %@. Now remove it.",[@"/Applications" stringByAppendingPathComponent:app]);
            [fm removeItemAtPath:[@"/Applications" stringByAppendingPathComponent:app] error:&err];
            if (err) {
                logit(lcl_vError,@"%@",[err description]);
                result = 3;
                break;
            }
        }
        
        err = nil;
        if (action == 0) {
            [fm copyItemAtPath:[aDir stringByAppendingPathComponent:app] toPath:[@"/Applications" stringByAppendingPathComponent:app] error:&err];
        } else if (action == 1) {
            [fm moveItemAtPath:[aDir stringByAppendingPathComponent:app] toPath:[@"/Applications" stringByAppendingPathComponent:app] error:&err];
        } else {
            [fm copyItemAtPath:[aDir stringByAppendingPathComponent:app] toPath:[@"/Applications" stringByAppendingPathComponent:app] error:&err];
        }
        
        if (err) {
            logit(lcl_vError,@"%@",[err description]);
            result = 2;
            break;
        }
        
        err = nil;
        [self changeOwnershipOfApp:[@"/Applications" stringByAppendingPathComponent:app] owner:@"root" group:@"admin" error:&err];
        if (err) {
            logit(lcl_vError,@"%@",[err description]);
            result = 3;
            break;
        }
    }
    
    reply(err, result);
}

// Install PKG from DMG
- (void)installPkgFromDMG:(NSString *)dmgPath packageID:(NSString *)packageID environment:(NSString *)aEnv withReply:(void(^)(NSError *error, NSInteger result))reply
{
    if ([self mountDMG:dmgPath packageID:packageID] != 0) {
        // Need a NSError reason
        reply(nil, 1);
        return;
    }
    
    int result = 0;
    NSString *mountPoint = [NSString pathWithComponents:@[[SW_DATA_DIR path], @"dmg", packageID]];
    
    NSArray     *dirContents = [fm contentsOfDirectoryAtPath:mountPoint error:nil];
    NSPredicate *fltr        = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
    NSArray     *onlyPkgs    = [dirContents filteredArrayUsingPredicate:fltr];
    
    int pkgInstallResult = -1;
    NSArray *installArgs;
    for (NSString *pkg in onlyPkgs)
    {
        //[self postDataToClient:[NSString stringWithFormat:@"Begin installing %@",pkg] type:kMPProcessStatus];
        installArgs = @[@"-verboseR", @"-pkg", [mountPoint stringByAppendingPathComponent:pkg], @"-target", @"/"];
        pkgInstallResult = [self runTask:INSTALLER_BIN_PATH binArgs:installArgs environment:aEnv];
        if (pkgInstallResult != 0) {
            result++;
        }
    }
    
    [self unmountDMG:dmgPath packageID:packageID];
    reply(nil, result);
}

// Uninstall Software Task using task ID
- (void)uninstallSoftware:(NSString *_Nonnull)swTaskID withReply:(nullable void(^)(NSInteger resultCode))reply
{
	qlinfo(@"uninstallSoftware[taskID]: %@",swTaskID);
	@try
	{
		MPClientDB *db = [MPClientDB new];
		InstalledSoftware *_swTask = [db getSoftwareTaskUsingID:swTaskID];
        qldebug(@"_swTask[%@]: %@",swTaskID,[_swTask.uninstall decodeBase64AsString]);
		if (!_swTask) {
			qlerror(@"Software task id (%@) could not be found. Uninstall will not occure.",swTaskID);
			reply(1);
			return;
		}
		
		// Check for uninstall script data
		if ([[_swTask.uninstall trim] length] <= 3) {
			qlinfo(@"Task has no uninstall script.");
			reply(0);
			return;
		}
		
		// Verify uninstall script is base 64 encoded.
		NSString *uninstallScript = nil;
		if ([_swTask.uninstall isBase64String]) {
			uninstallScript = [_swTask.uninstall decodeBase64AsString];
		} else {
			qlerror(@"Uninstall script was not encoded, or encoding could not be detected. No uninstall will occure.");
			reply(1);
			return;
		}
		
		// If has decoded script, run uninstall
		if (uninstallScript)
		{
			qlinfo(@"Running uninstall script.");
			MPScript *mps = [[MPScript alloc] init];
			BOOL result = [mps runScript:uninstallScript];
			qlinfo(@"Uninstall script was %@.", result ? @"Sucessful": @"Unsucessful");
			if (result) {
				reply(0);
			} else {
				reply(1);
			}
		} else {
			qlinfo(@"No uninstall script to run.");
			reply(0);
		}
		return;
	} @catch (NSException *exception) {
		qlerror(@"%@",exception);
		reply(1);
		return;
	}
}

- (InstalledSoftware *)getSWTaskUsingTaskID:(NSString *)swTaskID
{
	InstalledSoftware *_swTask = nil;
	MPClientDB *cdb = [MPClientDB new];
	_swTask = [cdb getSoftwareTaskUsingID:swTaskID];
	return _swTask;
}

#pragma mark • MacPatch Client Database

- (void)createAndUpdateDatabase:(void(^)(BOOL result))reply
{
	MPClientDB *cdb = [MPClientDB new];
	cdb = nil;
	reply(YES);
}

- (void)recordSoftwareInstallAdd:(NSDictionary*)swTask withReply:(void(^)(NSInteger result))reply
{
	MPClientDB *cdb = [MPClientDB new];
	BOOL result = [cdb recordSoftwareInstall:swTask];
	if (result)
	{
		reply(0);
	} else {
		reply(1);
	}
}

- (void)recordPatchInstall:(NSDictionary *)patch withReply:(void(^)(NSInteger result))reply
{
	MPClientDB *cdb = [MPClientDB new];
	BOOL result = [cdb recordPatchInstall:patch];
	if (result)
	{
		reply(0);
	} else {
		reply(1);
	}
}

- (void)retrieveInstalledSoftwareTasksWithReply:(void(^)(NSData *result))reply
{
	NSArray *tasks = [NSArray array];
	MPClientDB *cdb = [MPClientDB new];
	tasks = [cdb retrieveInstalledSoftwareTasks];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tasks];
	reply(data);
}

- (void)recordSoftwareInstallRemove:(NSString *)swTaskName taskID:(NSString *)swTaskID withReply:(void(^)(BOOL result))reply
{
	MPClientDB *cdb = [MPClientDB new];
	BOOL result = [cdb recordSoftwareUninstall:swTaskName taskID:swTaskID];
	reply(result);
}

- (void)recordHistoryWithType:(DBHistoryType)hstType name:(NSString *)aName
						 uuid:(NSString *)aUUID
					   action:(DBHistoryAction)aAction
					   result:(NSInteger)code
					 errorMsg:(NSString * _Nullable)aErrMsg
					withReply:(void(^)(BOOL result))reply
{
	MPClientDB *cdb = [MPClientDB new];
	BOOL result = [cdb recordHistory:hstType name:aName uuid:aUUID action:aAction result:code errorMsg:aErrMsg];
	reply(result);
}

// Patching
// Add required patch to database table to manage state.
- (void)addRequiredPatch:(NSData *)patch withReply:(void(^)(BOOL result))reply
{
	NSDictionary *_patch = [NSKeyedUnarchiver unarchiveObjectWithData:patch];
	MPClientDB *cdb = [MPClientDB new];
	BOOL result = [cdb addRequiredPatch:_patch];
	reply(result);
}

- (void)clearRequiredPatchesWithReply:(void(^)(BOOL result))reply
{
	MPClientDB *cdb = [MPClientDB new];
	BOOL result = [cdb clearRequiredPatches];
	[cdb clearRequiredPatches];
	reply(result);
}

// Patching
// After patch has been installed the record is removed from database table of required patches.
- (void)removeRequiredPatch:(NSString *)type patchID:(NSString *)patchID patch:(NSString *)patch withReply:(void(^)(BOOL result))reply
{
	MPClientDB *cdb = [MPClientDB new];
	BOOL result = [cdb removeRequiredPatch:type patchID:patchID patch:patch];
	reply(result);
}

#pragma mark • Agent Protocol

// Software
// Post Status Text
- (void)postStatus:(NSString *)status,...
{
	@try {
		va_list args;
		va_start(args, status);
		NSString *statusStr = [[NSString alloc] initWithFormat:status arguments:args];
		va_end(args);
		
		qltrace(@"postStatus[XPCWorker]: %@",statusStr);
		[[self.xpcConnection remoteObjectProxy] postStatus:statusStr type:kMPProcessStatus];
	}
	@catch (NSException *exception) {
		qlerror(@"%@",exception);
	}
}

// Post Progress for a progress bar
- (void)postProgress:(double)data
{
	@try
	{
		if ((int)data % 5 == 0)
		{
			qlinfo(@"Progress: %3d",(int)data);
		}
		
		[[self.xpcConnection remoteObjectProxy] postStatus:[NSString stringWithFormat:@"%lf", data] type:kMPProcessProgress];
	}
	@catch (NSException *exception) {
		qlerror(@"%@",exception);
	}
}

// Patching
// Post Status Text
- (void)postPatchStatus:(NSString *)status,...
{
	@try {
		va_list args;
		va_start(args, status);
		NSString *statusStr = [[NSString alloc] initWithFormat:status arguments:args];
		va_end(args);
		
		[[self.xpcConnection remoteObjectProxy] postStatus:statusStr type:kMPPatchProcessStatus];
	}
	@catch (NSException *exception) {
		qlerror(@"%@",exception);
	}
}

// Post Status Text
- (void)postPatchAllStatus:(NSString *)status,...
{
	@try {
		va_list args;
		va_start(args, status);
		NSString *statusStr = [[NSString alloc] initWithFormat:status arguments:args];
		va_end(args);
		
		[[self.xpcConnection remoteObjectProxy] postStatus:statusStr type:kMPPatchAllProcessStatus];
	}
	@catch (NSException *exception) {
		qlerror(@"%@",exception);
	}
}

// Post Progress for a progress bar
- (void)postPatchProgress:(double)data
{
	@try {
		if ((int)data % 5 == 0)
		{
			qlinfo(@"Progress: %3d",(int)data);
		}
		[[self.xpcConnection remoteObjectProxy] postStatus:[NSString stringWithFormat:@"%lf", data] type:kMPPatchProcessProgress];
	}
	@catch (NSException *exception) {
		qlerror(@"%@",exception);
	}
}

// Post Progress for a progress bar, for patch all
- (void)postPatchAllProgress:(double)data
{
	@try {
		qlinfo(@"Patch All Progress: %3d",(int)data);
		[[self.xpcConnection remoteObjectProxy] postStatus:[NSString stringWithFormat:@"%lf", data] type:kMPPatchAllProcessProgress];
	}
	@catch (NSException *exception) {
		qlerror(@"%@",exception);
	}
}

- (void)postPatchInstallError:(NSString *)patchID
{
	qlinfo(@"Post Patch Install Error for %@",patchID);
	@try {
		[[self.xpcConnection remoteObjectProxy] postPatchInstallStatus:patchID type:kMPPatchAllInstallError];
	}
	@catch (NSException *exception) {
		qlerror(@"%@",exception);
	}
}

- (void)postPatchInstallCompletion:(NSString *)patchID
{
	qlinfo(@"Post Patch Install Completion for %@",patchID);
	@try {
		[[self.xpcConnection remoteObjectProxy] postPatchInstallStatus:patchID type:kMPPatchAllInstallComplete];
	}
	@catch (NSException *exception) {
		qlerror(@"%@",exception);
	}
}
#pragma mark • Misc

- (void)unzip:(NSString *)aFile withReply:(void(^)(NSError *error, NSInteger result))reply
{
    int res = 0;
	MPFileUtils *fu = [MPFileUtils new];
    NSError *err = nil;
    res = [fu unzip:aFile error:&err];
    reply(err,res);
}

- (void)removeFile:(NSString *)aFile withReply:(void(^)(NSInteger result))reply
{
    int res = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL result = [fm removeFileIfExistsAtPath:aFile];
    if (!result) res = 1;
    reply(res);
}


#pragma mark • Client Checkin

- (void)runCheckInWithReply:(void(^)(NSError *error, NSDictionary *result))reply
{
	// Collect Agent Checkin Data
	MPClientInfo *ci = [[MPClientInfo alloc] init];
	NSDictionary *agentData = [ci agentData];
	if (!agentData)
	{
		logit(lcl_vError,@"Agent data is nil, can not post client checkin data.");
		return;
	}
	
	// Post Client Checkin Data to WS
	NSError *error = nil;
	NSDictionary *revsDict;
	MPRESTfull *rest = [[MPRESTfull alloc] init];
	revsDict = [rest postClientCheckinData:agentData error:&error];
	if (error) {
		logit(lcl_vError,@"Running client check in had an error.");
		logit(lcl_vError,@"%@", error.localizedDescription);
	}
	else
	{
		[self updateGroupSettings:revsDict];
	}
	
	logit(lcl_vInfo,@"Running client check in completed.");
	reply(error,revsDict);
}

- (void)updateGroupSettings:(NSDictionary *)settingRevisions
{
	// Query for Revisions
	// Call MPSettings to update if nessasary
	logit(lcl_vInfo,@"Check and Update Agent Settings.");
	logit(lcl_vDebug,@"Setting Revisions from server: %@", settingRevisions);
	MPSettings *set = [MPSettings sharedInstance];
	[set compareAndUpdateSettings:settingRevisions];
	return;
}


// Helpers
- (int)runTask:(NSString *)aBinPath binArgs:(NSArray *)aBinArgs environment:(NSString *)env
{
    MPNSTask *task = [MPNSTask new];
    task.taskTimeoutValue = swTaskTimeoutValue;
    int taskResult = -1;
    
    // Parse the Environment variables for the install
    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [environment setObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
    
    if ([env isEqualToString:@"NA"] == NO && [[env trim] length] > 0)
    {
        NSArray *l_envArray;
        NSArray *l_envItems;
        l_envArray = [env componentsSeparatedByString:@","];
        for (id item in l_envArray) {
            l_envItems = nil;
            l_envItems = [item componentsSeparatedByString:@"="];
            if ([l_envItems count] == 2) {
                logit(lcl_vDebug,@"Setting env variable(%@=%@).",[l_envItems objectAtIndex:0],[l_envItems objectAtIndex:1]);
                [environment setObject:[l_envItems objectAtIndex:1] forKey:[l_envItems objectAtIndex:0]];
            } else {
                logit(lcl_vError,@"Unable to set env variable. Variable not well formed %@",item);
            }
        }
    }
    
    logit(lcl_vDebug,@"[task][environment]: %@",environment);
    logit(lcl_vDebug,@"[task][setLaunchPath]: %@",aBinPath);
    logit(lcl_vDebug,@"[task][setArguments]: %@",aBinArgs);
    qlinfo(@"[task][setTimeout]: %d",swTaskTimeoutValue);
    
    NSString *result;
    NSError *error = nil;
    result = [task runTaskWithBinPath:aBinPath args:aBinArgs environment:environment error:&error];
    if (error) {
        qlerror(@"%@",error.localizedDescription);
    } else {
        taskResult = task.taskTerminationStatus;
    }

    return taskResult;
}

/*
- (int)runTaskOld:(NSString *)aBinPath binArgs:(NSArray *)aBinArgs environment:(NSString *)env
{
    NSString		*tmpStr;
    NSMutableData	*data;
    NSData			*dataChunk = nil;
    NSException		*error = nil;
	NSCharacterSet  *newlineSet;
    
    //[self setTaskIsRunning:YES];
    //[self setTaskTimedOut:NO];
    
    int taskResult = -1;
    
    nsTask = [[NSTask alloc] init];
    NSPipe *aPipe = [NSPipe pipe];
    
    [nsTask setStandardOutput:aPipe];
    [nsTask setStandardError:aPipe];
    
    // Parse the Environment variables for the install
    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [environment setObject:@"1" forKey:@"COMMAND_LINE_INSTALL"];
    
    if ([env isEqualToString:@"NA"] == NO && [[env trim] length] > 0)
    {
        NSArray *l_envArray;
        NSArray *l_envItems;
        l_envArray = [env componentsSeparatedByString:@","];
        for (id item in l_envArray) {
            l_envItems = nil;
            l_envItems = [item componentsSeparatedByString:@"="];
            if ([l_envItems count] == 2) {
                logit(lcl_vDebug,@"Setting env variable(%@=%@).",[l_envItems objectAtIndex:0],[l_envItems objectAtIndex:1]);
                [environment setObject:[l_envItems objectAtIndex:1] forKey:[l_envItems objectAtIndex:0]];
            } else {
                logit(lcl_vError,@"Unable to set env variable. Variable not well formed %@",item);
            }
        }
    }
    
    [nsTask setEnvironment:environment];
    logit(lcl_vDebug,@"[task][environment]: %@",environment);
    [nsTask setLaunchPath:aBinPath];
    logit(lcl_vDebug,@"[task][setLaunchPath]: %@",aBinPath);
    [nsTask setArguments:aBinArgs];
    logit(lcl_vDebug,@"[task][setArguments]: %@",aBinArgs);
    
    qlinfo(@"[task][setTimeout]: %d",swTaskTimeoutValue);
    // Launch The NSTask
    @try {
        [nsTask launch];
        // If timeout is set start it ...
        if (swTaskTimeoutValue != 0) {
            [NSThread detachNewThreadSelector:@selector(taskTimeoutThread) toTarget:self withObject:nil];
        }
    }
    @catch (NSException *e)
    {
        logit(lcl_vError,@"Install returned error. %@\n%@",[e reason],[e userInfo]);
        taskResult = 1;
        goto done;
    }
    
	newlineSet = [NSCharacterSet newlineCharacterSet];
    data = [[NSMutableData alloc] init];
    dataChunk = nil;
    error = nil;
    
    while(swTaskTimedOut == NO && ((dataChunk = [[aPipe fileHandleForReading] availableDataOrError:&error]) && [dataChunk length] && error == nil))
    {
        // If the data is not null, then post the data back to the client and log it locally
        tmpStr = [[NSString alloc] initWithData:dataChunk encoding:NSUTF8StringEncoding];
        if ([[tmpStr trim] length] != 0)
        {
			NSArray *lines = [tmpStr componentsSeparatedByCharactersInSet:newlineSet];
			for (NSString *l in lines)
			{
				if ([[l trim] length] != 0)
				{
					if ([tmpStr containsString:@"PackageKit: Missing bundle path"] == NO) {
						qldebug(@"%@",l.trim);
						//[self postDataToClient:l.trim type:kMPInstallStatus];
					} else {
						qldebug(@"%@",l.trim);
					}
				}
			}
            
        }
        
        [data appendData:dataChunk];
        tmpStr = nil;
    }
    
    [[aPipe fileHandleForReading] closeFile];
    
    if (swTaskTimedOut == YES) {
        qlerror(@"Task was terminated due to timeout.");
        [NSThread sleepForTimeInterval:5.0];
        [nsTask terminate];
        taskResult = 1;
        goto done;
    }
    
    if([data length] && error == nil)
    {
        if ([nsTask isRunning])
        {
            for (int i = 0; i < 30; i++)
            {
                if ([nsTask isRunning]) {
                    [NSThread sleepForTimeInterval:1.0];
                } else {
                    break;
                }
            }
            // Task should be complete
            qlinfo(@"Terminate Software Task.");
            [nsTask terminate];
        }
        
        int status = [nsTask terminationStatus];
        qlinfo(@"swTask terminationStatus: %d",status);
        if (status == 0) {
            taskResult = 0;
        } else {
            taskResult = 1;
        }
    } else {
        logit(lcl_vError,@"Install returned error. Code:[%d]",[nsTask terminationStatus]);
        taskResult = 1;
    }
    
done:
    
    if(swTaskTimer) {
        [swTaskTimer invalidate];
    }

    self->swTaskIsRunning = NO;
    return taskResult;
}

- (void)taskTimeoutThread
{
    @autoreleasepool {
        
        [swTaskTimer invalidate];
        
        qlinfo(@"Timeout is set to %d",swTaskTimeoutValue);
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:swTaskTimeoutValue
                                                          target:self
                                                        selector:@selector(taskTimeout:)
                                                        userInfo:nil
                                                         repeats:NO];
        
        self->swTaskTimer = timer;
        while (swTaskTimedOut == NO && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
        
    }
    
}

- (void)taskTimeout:(NSNotification *)aNotification
{
    qlinfo(@"Task timedout, killing task.");
    [swTaskTimer invalidate];
    swTaskTimedOut = YES;
    [nsTask terminate];
}
 */

- (void)changeOwnershipOfApp:(NSString *)aApp owner:(NSString *)aOwner group:(NSString *)aGroup error:(NSError **)err
{
    NSDictionary *permDict = @{NSFileOwnerAccountName:aOwner,NSFileGroupOwnerAccountName:aGroup};
    NSError *error = nil;
    [fm setAttributes:permDict ofItemAtPath:aApp error:&error];
    if (error) {
        if (err != NULL) *err = error;
        qlerror(@"Error settings permission %@",[error description]);
        return;
    }
    
    error = nil;
    NSArray *aContents = [fm subpathsOfDirectoryAtPath:aApp error:&error];
    if (error) {
        if (err != NULL) *err = error;
        qlerror(@"Error subpaths of Directory %@.\n%@",aApp,[error description]);
        return;
    }
    if (!aContents) {
        qlerror(@"No contents found for %@",aApp);
        return;
    }
    
    for (NSString *i in aContents)
    {
        error = nil;
        [[NSFileManager defaultManager] setAttributes:permDict ofItemAtPath:[aApp stringByAppendingPathComponent:i] error:&error];
        if (error) {
            if (err != NULL) *err = error;
            qlerror(@"Error settings permission %@",[error description]);
        }
    }
}

- (int)installPkgFromZIP:(NSString *)pkgPathDir environment:(NSString *)aEnv
{
	int result = 0;

	NSArray *dirContents = [fm contentsOfDirectoryAtPath:pkgPathDir error:nil];
	NSPredicate *fltr = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
	NSArray *onlyPkgs = [dirContents filteredArrayUsingPredicate:fltr];
	
	int pkgInstallResult = -1;
	NSArray *installArgs;
	for (NSString *pkg in onlyPkgs)
	{
		qlinfo(@"Installing %@",pkg);
		NSString *pkgPath = [pkgPathDir stringByAppendingPathComponent:pkg];
		installArgs = @[@"-verboseR", @"-pkg", pkgPath, @"-target", @"/"];
		pkgInstallResult = [self runTask:INSTALLER_BIN_PATH binArgs:installArgs environment:aEnv];
		if (pkgInstallResult != 0) {
			result++;
		}
	}
	
	return result;
}

- (int)mountDMG:(NSString *)dmgPath packageID:(NSString *)pkgID
{
    qlinfo(@"Mounting DMG %@",dmgPath);
    NSString *mountPoint = [NSString pathWithComponents:@[[SW_DATA_DIR path], @"dmg", pkgID]];
    logit(lcl_vDebug,@"[mountDMG] mountPoint: %@",mountPoint);
    
    NSError *err = nil;
    if ([fm fileExistsAtPath:mountPoint]) {
        [self unmountDMG:dmgPath packageID:pkgID]; // Unmount incase it's already mounted
    }
    [fm createDirectoryAtPath:mountPoint withIntermediateDirectories:YES attributes:nil error:&err];
    if (err) {
        logit(lcl_vError,@"%@",err.localizedDescription);
        return 1;
    }
    
    // Check if DMG exists
    if ([fm fileExistsAtPath:dmgPath] == NO) {
        logit(lcl_vError,@"File \"%@\" does not exist.",dmgPath);
        return 1;
    }
    
    NSArray *args = @[@"attach", @"-mountpoint", mountPoint, dmgPath, @"-nobrowse"];
    NSTask  *aTask = [[NSTask alloc] init];
    NSPipe  *pipe = [NSPipe pipe];
    
    [aTask setLaunchPath:@"/usr/bin/hdiutil"];
    [aTask setArguments:args];
    [aTask setStandardInput:pipe];
    [aTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [aTask setStandardError:[NSFileHandle fileHandleWithStandardError]];
    [aTask launch];
    [aTask waitUntilExit];
    
    int result = [aTask terminationStatus];
    if (result == 0) {
        qlinfo(@"DMG Mounted %@", mountPoint);
    }
    
    return result;
}

- (int)unmountDMG:(NSString *)dmgPath packageID:(NSString *)pkgID
{
    NSString *mountPoint = [NSString pathWithComponents:@[[SW_DATA_DIR path], @"dmg", pkgID]];
    qlinfo(@"Un-Mounting DMG %@",mountPoint);
    
    NSArray       *args  = @[@"detach", mountPoint, @"-force"];
    NSTask        *aTask = [[NSTask alloc] init];
    NSPipe        *pipe  = [NSPipe pipe];
    
    [aTask setLaunchPath:@"/usr/bin/hdiutil"];
    [aTask setArguments:args];
    [aTask setStandardInput:pipe];
    [aTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [aTask setStandardError:[NSFileHandle fileHandleWithStandardError]];
    [aTask launch];
    [aTask waitUntilExit];
    
    int result = [aTask terminationStatus];
    if (result == 0) {
        qlinfo(@"DMG Un-Mounted %@",dmgPath);
    }
    
    return result;
}

- (int)installPkgFromDMG:(NSString *)pkgID environment:(NSString *)aEnv
{
	int result = 0;
	NSString *mountPoint = NULL;
	NSString *mountPointBase = [[SW_DATA_DIR path] stringByAppendingPathComponent:@"dmg"];
	mountPoint = [mountPointBase stringByAppendingPathComponent:pkgID];
	
	NSArray *dirContents = [fm contentsOfDirectoryAtPath:mountPoint error:nil];
	NSPredicate *fltr = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
	NSArray *onlyPkgs = [dirContents filteredArrayUsingPredicate:fltr];
	
	int pkgInstallResult = -1;
	NSArray *installArgs;
	for (NSString *pkg in onlyPkgs)
	{
		qlinfo(@"Begin installing %@",pkg);
		installArgs = [NSArray arrayWithObjects:@"-verboseR", @"-pkg", [mountPoint stringByAppendingPathComponent:pkg], @"-target", @"/", nil];
		pkgInstallResult = [self runTask:INSTALLER_BIN_PATH binArgs:installArgs environment:aEnv];
		if (pkgInstallResult != 0) {
			result++;
		}
	}
	
	[self unmountDMG:mountPoint packageID:pkgID];
	return result;
}

- (int)copyAppFromDMG:(NSString *)pkgID
{
	int result = 0;
	NSString *mountPoint = NULL;
	NSString *mountPointBase = [[SW_DATA_DIR path] stringByAppendingPathComponent:@"dmg"];
	mountPoint = [mountPointBase stringByAppendingPathComponent:pkgID];
	
	result = [self copyAppFrom:mountPoint action:kMPCopyFile error:NULL];
	
	[self unmountDMG:mountPoint packageID:pkgID];
	return result;
}
#pragma mark • OS Profiles
- (void)scanForInstalledConfigProfiles:(void(^)(NSArray *profiles))reply
{
	qlinfo(@"scanForInstalledConfigProfiles");
	MPConfigProfiles *p = [[MPConfigProfiles alloc] init];
	NSArray *cp = [p readProfileStoreReturnAsConfigProfile];
	qlinfo(@"Profiles Found %lu",(unsigned long)cp.count);
	reply(cp);
}

- (void)getInstalledConfigProfilesWithReply:(void(^)(NSString *aString, NSData *aProfilesData))reply
{
	qldebug(@"getInstalledConfigProfilesWithReply");
	MPConfigProfiles *p = [[MPConfigProfiles alloc] init];
	NSArray *cp = [p readProfileStoreReturnAsConfigProfile];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cp];
	qlinfo(@"Profiles Found %lu",(unsigned long)cp.count);
	reply(@"Hello",data);
}


#pragma mark • FileVault
- (void)getFileVaultUsers:(void(^)(NSArray *users))reply
{
	MPFileVaultInfo *fvi = [MPFileVaultInfo new];
	[fvi runFDESetupCommand:@"list"];
	NSArray *fvUsers = [fvi userArray];
	qldebug(@"FileVault Users found %lu",(unsigned long)fvUsers.count);
	reply(fvUsers);
}

- (void)setAuthrestartDataForUser:(NSString *)userName userPass:(NSString *)userPass useRecoveryKey:(BOOL)useKey withReply:(void(^)(NSError *error, NSInteger result))reply
{
	NSInteger result = 1;
	NSError *err = nil;
	MPSimpleKeychain *kc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_AUTHSTATUS_KEYCHAIN];
	[kc createKeyChain:MP_AUTHSTATUS_KEYCHAIN];
	
	MPPassItem *pi = [MPPassItem new];
	[pi setUserName:userName];
	[pi setUserPass:userPass];

	[kc savePassItemWithService:pi service:@"mpauthrestart" error:&err];
	if (err) {
		qlerror(@"Save Error: %@",err.localizedDescription);
		result = 1;
	} else {
		qlinfo(@"Data has been saved. Write plist.");
		[self writeAuthStatusToPlist:userName enabled:YES useRecoveryKey:useKey];
		result = 0;
	}
    
    kc = nil;
	reply(err, result);
}

- (void)enableAuthRestartWithReply:(void(^)(NSError *error, NSInteger result))reply
{
    NSInteger result = 1;
    NSDictionary *authData = nil;
    NSError *err = nil;
    MPSimpleKeychain *kc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_AUTHSTATUS_KEYCHAIN];
    MPPassItem *pi = [kc retrievePassItemForService:@"mpauthrestart" error:&err];
    if (!err) {
        authData = [pi toDictionary];
    } else {
        qlerror(@"Error getting saved FileVault auth data.");
        reply(err,result);
    }
    
    NSString *script = [NSString stringWithFormat:@"#!/bin/bash \n"
    "/usr/bin/fdesetup authrestart -delayminutes -1 -verbose -inputplist <<EOF \n"
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n"
    "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \n"
    "<plist version=\"1.0\"> \n"
    "<dict> \n"
    "    <key>Username</key> \n"
    "    <string>%@</string> \n"
    "    <key>Password</key> \n"
    "    <string>%@</string> \n"
    "</dict></plist>\n"
    "EOF",authData[@"userName"],authData[@"userPass"]];
    
    [script writeToFile:@"/private/var/tmp/authScript" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    
    MPScript *mps = [MPScript new];
    BOOL res = [mps runScript:script];
    if (!res) {
        qlerror(@"bypassFileVaultForRestart script failed to run.");
    } else {
        result = 0;
    }
    // Keep for debugging
    BOOL keepScript = NO;
    if (!keepScript)
    {
        if ([fm fileExistsAtPath:@"/private/var/tmp/authScript"]) {
            err = nil;
            [fm removeItemAtPath:@"/private/var/tmp/authScript" error:&err];
            if (err) {
                qlerror(@"Error removing authScript");
            }
        }
    }

    // Quick Sleep before the reboot
    [NSThread sleepForTimeInterval:1.0];
    reply(err,result);
}

- (void)runAuthRestartWithReply:(void(^)(NSError *error, NSInteger result))reply
{
    NSInteger result = 1;
    NSDictionary *authData = nil;
    NSError *err = nil;
    MPSimpleKeychain *kc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_AUTHSTATUS_KEYCHAIN];
    MPPassItem *pi = [kc retrievePassItemForService:@"mpauthrestart" error:&err];
    if (!err) {
        authData = [pi toDictionary];
    } else {
        qlerror(@"Error getting saved FileVault auth data.");
        reply(err,result);
    }
    
    NSString *script = [NSString stringWithFormat:@"#!/bin/bash \n"
    "/usr/bin/fdesetup authrestart -delayminutes 0 -verbose -inputplist <<EOF \n"
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n"
    "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \n"
    "<plist version=\"1.0\"> \n"
    "<dict> \n"
    "    <key>Username</key> \n"
    "    <string>%@</string> \n"
    "    <key>Password</key> \n"
    "    <string>%@</string> \n"
    "</dict></plist>\n"
    "EOF",authData[@"userName"],authData[@"userPass"]];
    
    [script writeToFile:@"/private/var/tmp/authScript" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    
    MPScript *mps = [MPScript new];
    BOOL res = [mps runScript:script];
    if (!res) {
        qlerror(@"bypassFileVaultForRestart script failed to run.");
    } else {
        result = 0;
    }
    // Keep for debugging
    BOOL keepScript = NO;
    if (!keepScript)
    {
        if ([fm fileExistsAtPath:@"/private/var/tmp/authScript"]) {
            err = nil;
            [fm removeItemAtPath:@"/private/var/tmp/authScript" error:&err];
            if (err) {
                qlerror(@"Error removing authScript");
            }
        }
    }

    // Quick Sleep before the reboot
    [NSThread sleepForTimeInterval:1.0];
    reply(err,result);
}

- (void)getAuthRestartDataWithReply:(void(^)(NSError *error, NSDictionary *result))reply
{
	NSDictionary *result = nil;
	NSError *err = nil;
	MPSimpleKeychain *kc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_AUTHSTATUS_KEYCHAIN];
	MPPassItem *pi = [kc retrievePassItemForService:@"mpauthrestart" error:&err];
	if (!err) {
		result = [pi toDictionary];
	}
	reply(err,result);
}

- (void)clearAuthrestartData:(void(^)(NSError *error, BOOL result))reply
{
	BOOL result = YES;
	NSError *err = nil;
	NSFileManager *fs = [NSFileManager defaultManager];
    
    MPSimpleKeychain *kc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_AUTHSTATUS_KEYCHAIN];
    OSStatus delRes = [kc deleteKeyChain];
    if (delRes != noErr) {
        qlerror(@"Error deleteing keychain.");
        err = [NSError errorWithDomain:@"gov.llnl.MPSimpleKeychain" code:20001 userInfo:NULL];
        result = NO;
    }
    
	if ([fs fileExistsAtPath:MP_AUTHSTATUS_FILE]) {
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:MP_AUTHSTATUS_FILE];
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"enabled"];
		[d setObject:@"" forKey:@"user"];
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"outOfSync"];
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"keyOutOfSync"];
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"useRecovery"];
		[d writeToFile:MP_AUTHSTATUS_FILE atomically:NO];
	}
	if (err) {
		qlerror(@"Error clearing authrestart from keychain.");
		qlerror(@"%@",err.localizedDescription);
		result = NO;
	}
	
	reply(err,result);
}

- (void)fvAuthrestartAccountIsValid:(void(^)(NSError *error, BOOL result))reply
{
	NSError *err = nil;
	BOOL isValid = NO;
	MPFileCheck *fu = [MPFileCheck new];
	if ([fu fExists:MP_AUTHSTATUS_FILE])
	{
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:MP_AUTHSTATUS_FILE];
		if ([d[@"enabled"] boolValue])
		{
			if ([d[@"useRecovery"] boolValue])
			{
				MPSimpleKeychain *kc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_AUTHSTATUS_KEYCHAIN];
				MPPassItem *pi = [kc retrievePassItemForService:@"mpauthrestart" error:&err];
				if (!err)
				{
					isValid = [self recoveryKeyIsValid:pi.userPass];
					qldebug(@"Is FV Recovery Key Valid: %@",isValid ? @"Yes":@"No");
					
					if (!isValid) {
						[d setObject:[NSNumber numberWithBool:YES] forKey:@"keyOutOfSync"];
						[d writeToFile:MP_AUTHSTATUS_FILE atomically:NO];
					}
				} else {
					qlerror(@"Could not retrievePassItemForService");
					qlerror(@"%@",err.localizedDescription);
				}
			} else {
				DHCachedPasswordUtil *dh = [DHCachedPasswordUtil new];
				MPSimpleKeychain *kc = [[MPSimpleKeychain alloc] initWithKeychainFile:MP_AUTHSTATUS_KEYCHAIN];
				MPPassItem *pi = [kc retrievePassItemForService:@"mpauthrestart" error:&err];
				if (!err)
				{
					isValid = [dh checkPassword:pi.userPass forUserWithName:pi.userName];
					qldebug(@"Is FV UserName and Password Valid: %@",isValid ? @"Yes":@"No");
					
					if (!isValid) {
						[d setObject:[NSNumber numberWithBool:YES] forKey:@"outOfSync"];
						[d writeToFile:MP_AUTHSTATUS_FILE atomically:NO];
					}
				} else {
					qlerror(@"Could not retrievePassItemForService");
					qlerror(@"%@",err.localizedDescription);
				}
			}
		} else {
			qlerror(@"Authrestart is not enabled.");
		}
	}
	
	reply(err,isValid);
}

- (void)fvRecoveryKeyIsValid:(NSString *)rKey withReply:(void(^)(NSError *error, BOOL result))reply
{
	NSError *err = nil;
	BOOL isValid = NO;
	MPFileCheck *fu = [MPFileCheck new];
	if ([fu fExists:MP_AUTHSTATUS_FILE])
	{
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:MP_AUTHSTATUS_FILE];
		if ([d[@"enabled"] boolValue])
		{
			if ([d[@"useRecoveryKey"] boolValue])
			{
				isValid = [self recoveryKeyIsValid:rKey];
			}
		} else {
			qlerror(@"Authrestart is not enabled.");
		}
	}
	
	reply(err,isValid);
}

- (BOOL)recoveryKeyIsValid:(NSString *)rKey
{
	BOOL isValid = NO;

	NSString *script = [NSString stringWithFormat:@"#!/bin/bash \n"
	"/usr/bin/expect -f- << EOT \n"
	"spawn /usr/bin/fdesetup validaterecovery; \n"
	"expect \"Enter the current recovery key:*\" \n"
	"send -- %@ \n"
	"send -- \"\\r\" \n"
	"expect \"true\" \n"
	"expect eof; \n"
	"EOT",rKey];
	MPScript *mps = [MPScript new];
	NSString *res = [mps runScriptReturningResult:script];
	// Now Look for our result ...
	NSArray *arr = [res componentsSeparatedByString:@"\n"];
	for (NSString *l in arr) {
		if ([l containsString:@"fdesetup"]) {
			continue;
		}
		if ([l containsString:@"Enter the "]) {
			continue;
		}
		if ([[l trim] isEqualToString:@"false"]) {
			isValid = NO;
			break;
		}
		if ([[l trim] isEqualToString:@"true"]) {
			isValid = YES;
			break;
		}
	}

	return isValid;
}

// Private
- (void)writeAuthStatusToPlist:(NSString *)authUser enabled:(BOOL)aEnabled useRecoveryKey:(BOOL)useKey
{
	NSDictionary *authStatus = @{@"user":authUser,
								 @"enabled":[NSNumber numberWithBool:aEnabled],
								 @"useRecovery":[NSNumber numberWithBool:useKey],
								 @"keyOutOfSync":[NSNumber numberWithBool:NO],
								 @"outOfSync":[NSNumber numberWithBool:NO]};
	[authStatus writeToFile:MP_AUTHSTATUS_FILE atomically:NO];
}

#pragma mark - Private

- (NSData *)encodeResult:(NSData *)dataToEncode error:(NSError **)error
{
	/*
    NSError *_error = nil;
	
    MPHost *mh = [MPHost defaultManager];
    NSString *mhID = [mh genHostID];
    NSData *result = [RNEncryptor encryptData:dataToEncode
                                 withSettings:kRNCryptorAES256Settings
                                     password:mhID
                                        error:&_error];
    if (error != NULL) *error =_error;
    return result;
	 */
	return nil;
}

- (NSURL *)swDataDirURL
{
	NSURL *appSupportDir = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSSystemDomainMask] objectAtIndex:0];
	NSURL *appSupportMPDir = [appSupportDir URLByAppendingPathComponent:@"MacPatch/SW_Data"];
	[self configDataDir];
	return appSupportMPDir;
}

/**
 Method will run a script using MPScript.
 
 aScript (NSString) is a Base64 encoded string.
 
 aScriptType (int) is for the logging it's
 	values: 0 = pre and 1 = post
 */
-(BOOL)runSWInstallScript:(NSString *)aScript type:(int)aScriptType
{
	NSString *_script;
	MPScript *mps = [[MPScript alloc] init];
	if (!aScript) return YES;
	if ([aScript isEqualToString:@""]) return YES;
	
	NSString *_scriptType = (aScriptType == 0) ? @"pre" : @"post";
	
	@try
	{
		_script = [aScript decodeBase64AsString];
		if (![mps runScript:_script]) {
			logit(lcl_vError,@"Error running %@ install script. No install will occure.", _scriptType);
			return NO;
		} else {
			return YES;
		}
	}
	@catch (NSException *exception) {
		logit(lcl_vError,@"Exception Error running %@ install script. No install will occure.", _scriptType);
		logit(lcl_vError,@"%@",exception);
		return NO;
	}
	
	qlerror(@"Reached end of runSWInstallScript, should not happen.");
	return NO;
}

/**
 Copy application from a directory to the Applications directory
 
 action is MPFileMoveAction kMPFileCopy or kMPFileMove
 
 Method also calls changeOwnershipOfItem
 */
- (int)copyAppFrom:(NSString *)aDir action:(MPFileMoveAction)action error:(NSError **)error
{
	int result = 0;
	NSArray *dirContents = [fm contentsOfDirectoryAtPath:aDir error:nil];
	NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.app'"];
	NSArray *onlyApps = [dirContents filteredArrayUsingPredicate:fltr];
	
	NSError *err = nil;
	for (NSString *app in onlyApps)
	{
		if ([fm fileExistsAtPath:[@"/Applications"  stringByAppendingPathComponent:app]])
		{
			qldebug(@"Found, %@. Now remove it.",[@"/Applications" stringByAppendingPathComponent:app]);
			[fm removeItemAtPath:[@"/Applications" stringByAppendingPathComponent:app] error:&err];
			if (err) {
				if (error != NULL) *error = err;
				result = 3;
				break;
			}
		}
		err = nil;
		if (action == kMPCopyFile) {
			[fm copyItemAtPath:[aDir stringByAppendingPathComponent:app] toPath:[@"/Applications" stringByAppendingPathComponent:app] error:&err];
		} else if (action == kMPMoveFile) {
			[fm moveItemAtPath:[aDir stringByAppendingPathComponent:app] toPath:[@"/Applications" stringByAppendingPathComponent:app] error:&err];
		} else {
			[fm copyItemAtPath:[aDir stringByAppendingPathComponent:app] toPath:[@"/Applications" stringByAppendingPathComponent:app] error:&err];
		}
		
		if (err)
		{
			if (error != NULL) *error = err;
			result = 2;
			break;
		}
		
		[self changeOwnershipOfItem:[@"/Applications" stringByAppendingPathComponent:app] owner:@"root" group:@"admin"];
	}
	
	return result;
}

/**
 Method will change the ownership of a item at a given path, owner and group are strings
 */
- (void)changeOwnershipOfItem:(NSString *)aApp owner:(NSString *)aOwner group:(NSString *)aGroup
{
	NSDictionary *permDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  aOwner,NSFileOwnerAccountName,
							  aGroup,NSFileGroupOwnerAccountName,nil];
	
	NSError *error = nil;
	[fm setAttributes:permDict ofItemAtPath:aApp error:&error];
	if(error)
	{
		qlerror(@"Error settings permission %@",[error description]);
		return;
	}
	
	error = nil;
	NSArray *aContents = [fm subpathsOfDirectoryAtPath:aApp error:&error];
	if(error)
	{
		qlerror(@"Error subpaths of Directory %@.\n%@",aApp,[error description]);
		return;
	}
	if (!aContents)
	{
		qlerror(@"No contents found for %@",aApp);
		return;
	}
	
	for (NSString *i in aContents)
	{
		error = nil;
		[[NSFileManager defaultManager] setAttributes:permDict ofItemAtPath:[aApp stringByAppendingPathComponent:i] error:&error];
		if(error){
			qlerror(@"Error settings permission %@",[error description]);
		}
	}
}

#pragma mark - Delegate Methods

- (void)downloadProgress:(NSString *)progressStr
{
	[self postStatus:progressStr];
	[self postPatchStatus:progressStr];
}

- (void)patchProgress:(NSString *)progressStr
{
	//[self postPatchStatus:progressStr];
	[self postStatus:progressStr];
}

#pragma mark - Provisioning

- (void)createDirectory:(NSString *)path withReply:(void(^)(NSError *error))reply
{
    NSError *err = nil;
    NSFileManager *dfm = [NSFileManager defaultManager];
    [dfm createDirectoryRecursivelyAtPath:path];
    if (![dfm isDirectoryAtPath:path]) {
        NSDictionary *errDetail = @{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ is not a directory.",path]};
        err = [NSError errorWithDomain:@"gov.llnl.mp.helper" code:101 userInfo:errDetail];
    }
    reply(err);
}

- (void)postProvisioningData:(NSString *)key dataForKey:(NSData *)data dataType:(NSString *)dataType withReply:(void(^)(NSError *error))reply
{
    // qlinfo(@"CEHD [postProvisioningData]: key:%@ dataType:%@",key,dataType);
    NSError *err = nil;
    id _data = nil;
    
    if ([[dataType lowercaseString] isEqualToString:@"string"]) {
        _data = (NSString*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else if ([[dataType lowercaseString] isEqualToString:@"dict"]) {
        _data = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else if ([[dataType lowercaseString] isEqualToString:@"array"]) {
        _data = (NSArray*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else if ([[dataType lowercaseString] isEqualToString:@"bool"]) {
        // Bools are wrapped in NSDict key = key
        NSDictionary *x = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        _data = x[key];
    } else {
        NSDictionary *errDetail = @{NSLocalizedDescriptionKey:@"Error writing provisioning data to file. Type not supported."};
        err = [NSError errorWithDomain:@"gov.llnl.mp.helper" code:101 userInfo:errDetail];
        reply(err);
    }

    MPFileCheck *fc = [MPFileCheck new];
    
    NSMutableDictionary *_pFile;
    if ([fc fExists:MP_PROVISION_FILE]) {
        _pFile = [NSMutableDictionary dictionaryWithContentsOfFile:MP_PROVISION_FILE];
    } else {
        _pFile = [NSMutableDictionary new];
    }
    
    if ([key isEqualToString:@"status"])
    {
        NSMutableArray *_status = [NSMutableArray new];
        if (_pFile[@"status"]) {
            _status = [_pFile[@"status"] mutableCopy];
        }
        [_status addObject:_data];
        [_pFile setObject:_status forKey:key];
        // _pFile[key] = _status;
    } else {
        [_pFile setObject:_data forKey:key];
        // _pFile[key] = _data;
    }
    
    if (![_pFile writeToFile:MP_PROVISION_FILE atomically:NO]) {
        NSDictionary *errDetail = @{NSLocalizedDescriptionKey:@"Error writing provisioning data to file."};
        err = [NSError errorWithDomain:@"gov.llnl.mp.helper" code:101 userInfo:errDetail];
    }
    
    //qlinfo(@"CEHD: Verify postProvisioningData");
    //qlinfo(@"CEHD: Data: %@",[NSDictionary dictionaryWithContentsOfFile:MP_PROVISION_FILE]);
    reply(err);
}

- (void)touchFile:(NSString *)filePath withReply:(void(^)(NSError *error))reply
{
    NSError *err = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filePath]) {
        [@"NA" writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:&err];
    }
    
    reply(err);
}

- (void)rebootHost:(void(^)(NSError *error))reply
{
    NSError *err = nil;
    qlinfo(@"Provisioning issued a cli reboot.");
    [NSTask launchedTaskWithLaunchPath:@"/sbin/reboot" arguments:@[]];
    reply(err);
}

#pragma mark - Test Code

@end
