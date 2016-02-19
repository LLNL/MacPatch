//  AHLaunchCtl.m
//  Copyright (c) 2014 Eldon Ahrold ( https://github.com/eahrold/AHLaunchCtl )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AHLaunchCtl.h"
#import "AHAuthorizer.h"
#import "AHServiceManagement.h"
#import "AHServiceManagement_Private.h"

#import "NSString+ah_versionCompare.h"

#import <SystemConfiguration/SystemConfiguration.h>

static NSString *const kAHAuthorizationLoadJobPrompt =
    @"Loading the job requires authorization.";
static NSString *const kAHAuthorizationUnloadJobPrompt =
    @"Unloading the job requires authorization.";
static NSString *const kAHAuthorizationReloadJobPrompt =
    @"Reloading the job requires authorization.";
static NSString *const kAHAuthorizationSessionPrompt =
    @"Performing administrative tasks requires authorization.";

static NSString *const kAHSessionAuthorizationKey =
    @"com.eeaapps.ahlaunchctl.controller.session.authorization";

static NSString *const kAHLaunchCtlDomain = @"com.eeaapps.ahlaunchctl";

static NSString *errorMsgFromCode(NSInteger code);

@interface AHLaunchJob ()
@property (nonatomic, readwrite) AHLaunchDomain domain;  //
@end

#pragma mark - Launch Controller
@implementation AHLaunchCtl {
    AuthorizationRef _authRef;
}

+ (AHLaunchCtl *)sharedController {
    static dispatch_once_t onceToken;
    static AHLaunchCtl *shared;
    dispatch_once(&onceToken, ^{
      shared = [AHLaunchCtl new];
    });
    return shared;
}

- (void)dealloc {
    [self deauthorize];
}

#pragma mark - Session authorization.
- (BOOL)authorizeWithPrompt:(NSString *)prompt {
    OSStatus status = errAuthorizationSuccess;
    if (_authRef == NULL) {
        if ([self isEqual:[[self class] sharedController]]) {
            status = errAuthorizationDenied;
            NSLog(@"You cannot create session authorization for the shared "
                  @"controller.");
        } else {
            status = [AHAuthorizer
                authorizeSystemDaemonWithLabel:kAHSessionAuthorizationKey
                                        prompt:kAHAuthorizationSessionPrompt
                                       authRef:&_authRef];
        }
    }

    return (status == errAuthorizationSuccess);
}
- (BOOL)authorize {
    return [self authorizeWithPrompt:kAHAuthorizationSessionPrompt];
}

- (void)deauthorize {
    [AHAuthorizer authorizationFree:_authRef];
    _authRef = NULL;
}

#pragma mark--- Add/Remove ---
- (BOOL)add:(AHLaunchJob *)job
   toDomain:(AHLaunchDomain)domain
      error:(NSError *__autoreleasing *)error {
    if (![self jobIsValid:job error:error]) {
        return NO;
    }

    BOOL success = NO;
    AuthorizationRef authRef = NULL;

    if (domain > kAHUserLaunchAgent) {
        // Get userID
        success = [self createAuthorization:&authRef
                                     domain:domain
                                      label:job.Label
                                     prompt:kAHAuthorizationLoadJobPrompt
                                      error:error];
        if (success) {
            success = AHCreatePrivilegedLaunchdPlist(domain, job.dictionary,
                                                     authRef, error);
        }
    } else {
        if ((success =
                 [job.dictionary writeToFile:launchdJobFile(job.Label, domain)
                                  atomically:YES]) == NO) {
            [[self class] errorWithCode:kAHErrorCouldNotWriteFile error:error];
        }
    }

    if (success) {
        success = [self load:job inDomain:domain authRef:authRef error:error];
    }

    if (_authRef == NULL) {
        [AHAuthorizer authorizationFree:authRef];
    }
    authRef = NULL;

    return success;
}

- (BOOL)remove:(NSString *)label
    fromDomain:(AHLaunchDomain)domain
         error:(NSError *__autoreleasing *)error {
    BOOL success = NO;
    AuthorizationRef authRef = NULL;

    if (domain > kAHUserLaunchAgent) {
        // Get userID
        success = [self createAuthorization:&authRef
                                     domain:domain
                                      label:label
                                     prompt:kAHAuthorizationUnloadJobPrompt
                                      error:error];
        if (success) {
            success = AHJobRemoveIncludingFile(domain, label, authRef, error);
        }
    } else {
        if ((success = AHJobRemove(domain, label, authRef, error))) {
            success = [[NSFileManager defaultManager]
                removeItemAtPath:launchdJobFile(label, domain)
                           error:error];
        }
    }

    if (_authRef == NULL) {
        [AHAuthorizer authorizationFree:authRef];
    }
    authRef = NULL;
    return success;
}

#pragma mark--- Load / Unload Jobs ---
- (BOOL)load:(AHLaunchJob *)job
    inDomain:(AHLaunchDomain)domain
     authRef:(AuthorizationRef)authRef
       error:(NSError *__autoreleasing *)error {
    BOOL success;
    NSString *consoleUser;

    if (domain <= kAHSystemLaunchAgent) {
        // If this is a launch agent and no user is logged in no reason to load;
        consoleUser =
            CFBridgingRelease(SCDynamicStoreCopyConsoleUser(NULL, NULL, NULL));
        if (!consoleUser || [consoleUser isEqualToString:@"loginwindow"]) {
#if DEBUG
            NSLog(@"No User Logged in");
#endif
            return YES;
        }
    }

    success = AHJobSubmit(domain, job.dictionary, authRef, error);

    if (success) {
        job.domain = domain;
    }

    return success;
}

- (BOOL)load:(AHLaunchJob *)job
    inDomain:(AHLaunchDomain)domain
       error:(NSError *__autoreleasing *)error {
    BOOL success = YES;
    AuthorizationRef authRef = NULL;

    success = [self createAuthorization:&authRef
                                 domain:domain
                                  label:job.Label
                                 prompt:kAHAuthorizationLoadJobPrompt
                                  error:error];

    if (success) {
        success = [self load:job inDomain:domain authRef:authRef error:error];
    }

    // Clean Up
    if (_authRef == NULL) {
        [AHAuthorizer authorizationFree:authRef];
    }
    authRef = NULL;

    return success;
}

- (BOOL)unload:(NSString *)label
      inDomain:(AHLaunchDomain)domain
       authRef:(AuthorizationRef)authRef
         error:(NSError *__autoreleasing *)error {
    BOOL success = YES;

    if (!jobIsRunning(label, domain)) {
        return [[self class] errorWithCode:kAHErrorJobNotLoaded error:error];
    }

    // If this is a launch agent and no user is logged in no reason to unload;
    if (domain <= kAHSystemLaunchAgent) {
        NSString *result =
            CFBridgingRelease(SCDynamicStoreCopyConsoleUser(NULL, NULL, NULL));
        if ([result isEqualToString:@"loginwindow"] || !result) {
            NSLog(@"No User Logged in");
            return YES;
        }
    }

    success = AHJobRemove(domain, label, authRef, error);
    return success;
}

- (BOOL)unload:(NSString *)label
      inDomain:(AHLaunchDomain)domain
         error:(NSError *__autoreleasing *)error {
    AuthorizationRef authRef = NULL;
    BOOL success = YES;

    success = [self createAuthorization:&authRef
                                 domain:domain
                                  label:label
                                 prompt:kAHAuthorizationUnloadJobPrompt
                                  error:error];

    if (success) {
        success =
            [self unload:label inDomain:domain authRef:authRef error:error];
    }

    // Clean Up
    if (_authRef == NULL) {
        [AHAuthorizer authorizationFree:authRef];
    }
    authRef = NULL;

    return success;
}

- (BOOL)reload:(AHLaunchJob *)job
      inDomain:(AHLaunchDomain)domain
         error:(NSError *__autoreleasing *)error {
    AuthorizationRef authRef = NULL;
    BOOL success = YES;

    // Get userID
    success = [self createAuthorization:&authRef
                                 domain:domain
                                  label:job.Label
                                 prompt:kAHAuthorizationReloadJobPrompt
                                  error:error];

    if (jobIsRunning2(job.Label, domain) && success) {
        if (![self unload:job.Label
                 inDomain:domain
                  authRef:authRef
                    error:error]) {
            success = [[self class] errorWithCode:kAHErrorJobCouldNotReload
                                            error:error];
        }
    }

    if (success) {
        success = [self load:job inDomain:domain authRef:authRef error:error];
    }

    // Clean Up
    if (_authRef == NULL) {
        [AHAuthorizer authorizationFree:authRef];
    }
    authRef = NULL;

    return success;
}

#pragma mark--- Start / Stop / Restart ---
- (BOOL)start:(NSString *)label
     inDomain:(AHLaunchDomain)domain
        error:(NSError *__autoreleasing *)error {
    if (jobIsRunning(label, domain)) {
        return
            [[self class] errorWithCode:kAHErrorJobAlreadyLoaded error:error];
    }

    AHLaunchJob *job = [[self class] jobFromFileNamed:label inDomain:domain];
    if (job) {
        return [self load:job inDomain:domain error:error];
    } else {
        return [[self class] errorWithCode:kAHErrorFileNotFound error:error];
    }
}

- (BOOL)stop:(NSString *)label
    inDomain:(AHLaunchDomain)domain
       error:(NSError *__autoreleasing *)error {
    return [self unload:label inDomain:domain error:error];
}

- (BOOL)restart:(NSString *)label
       inDomain:(AHLaunchDomain)domain
          error:(NSError *__autoreleasing *)error {
    AHLaunchJob *job = [[self class] runningJobWithLabel:label inDomain:domain];
    if (!job) {
        return [[self class] errorWithCode:kAHErrorJobNotLoaded error:error];
    }
    return [self reload:job inDomain:domain error:error];
}

#pragma mark - Helper Tool Installation / Removal
+ (BOOL)installHelper:(NSString *)label
               prompt:(NSString *)prompt
                error:(NSError *__autoreleasing *)error {
    NSString *currentVersion;
    NSString *availableVersion;

    AHLaunchJob *job =
        [[self class] runningJobWithLabel:label inDomain:kAHGlobalLaunchDaemon];

    if (job) {
        currentVersion = job.executableVersion;

        NSString *xpcToolPath = [@"Contents/Library/LaunchServices"
            stringByAppendingPathComponent:label];
        NSURL *appBundleURL = [[NSBundle mainBundle] bundleURL];

        NSURL *helperTool =
            [appBundleURL URLByAppendingPathComponent:xpcToolPath];
        NSDictionary *helperPlist = CFBridgingRelease(
            CFBundleCopyInfoDictionaryForURL((__bridge CFURLRef)(helperTool)));

        availableVersion = helperPlist[@"CFBundleVersion"];

        if ([availableVersion ah_version_isLessThanOrEqualTo:currentVersion]) {
            return YES;
        }
    }

    BOOL success = YES;

    AuthorizationRef authRef = NULL;
    OSStatus status =
        [AHAuthorizer authorizeSMJobBlessWithPrompt:prompt authRef:&authRef];

    if (status == errAuthorizationCanceled) {
        return [[self class] errorWithCode:kAHErrorUserCanceledAuthorization
                                     error:error];
    } else if (authRef == NULL) {
        return [[self class] errorWithCode:kAHErrorInsufficientPrivileges
                                     error:error];
    } else {
        // If the job is running un-bless it in order to re-bless it.
        // This addresses a condition where when replaced, the binary has an
        // inconsistent code signature and causes paging failures.
        if (jobIsRunning(label, kAHGlobalLaunchDaemon)) {
            AHJobUnbless(kAHGlobalLaunchDaemon, label, authRef, nil);
        }

        // Run the job bless.
        if (!AHJobBless(kAHGlobalLaunchDaemon, label, authRef, error)) {
            success = [[self class] errorWithCode:kAHErrorCouldNotLoadHelperTool
                                            error:error];
        }
    }

    [AHAuthorizer authorizationFree:authRef];
    return success;
}

+ (BOOL)uninstallHelper:(NSString *)label
                 prompt:(NSString *)prompt
                  error:(NSError *__autoreleasing *)error {
    BOOL success = YES;

    if (jobIsRunning(label, kAHGlobalLaunchDaemon)) {
        AuthorizationRef authRef = NULL;
        OSStatus status =
            [AHAuthorizer authorizeSystemDaemonWithLabel:label
                                                  prompt:prompt
                                                 authRef:&authRef];

        if (status == errAuthorizationCanceled) {
            success =
                [[self class] errorWithCode:kAHErrorUserCanceledAuthorization
                                      error:error];
        } else if (authRef == NULL) {
            return [[self class] errorWithCode:kAHErrorInsufficientPrivileges
                                         error:error];
        } else {
            if (!AHJobUnbless(kAHGlobalLaunchDaemon, label, authRef, error)) {
                success =
                    [[self class] errorWithCode:kAHErrorCouldNotUnloadHelperTool
                                          error:error];
            }
        }
        [AHAuthorizer authorizationFree:authRef];
    } else {
        success = [self errorWithCode:kAHErrorHelperToolNotLoaded error:error];
    }
    return success;
}

+ (BOOL)uninstallHelper:(NSString *)label
                  error:(NSError *__autoreleasing *)error {
    NSString *defaultPrompt = [NSString
        stringWithFormat:
            @"%@ is trying to uninstall a the helper tool and it's components.",
            [[NSProcessInfo processInfo] processName]];
    return [self uninstallHelper:label prompt:defaultPrompt error:error];
}

+ (BOOL)removeFilesForHelperWithLabel:(NSString *)label
                                error:(NSError *__autoreleasing *)error {
    // This is depreciated and now happens during AHJobUnbless()
    return YES;
}

#pragma mark - Convenience Accessors
+ (BOOL)launchAtLogin:(NSString *)app
               launch:(BOOL)launch
               global:(BOOL)global
            keepAlive:(BOOL)keepAlive
                error:(NSError *__autoreleasing *)error {
    NSBundle *appBundle = [NSBundle bundleWithPath:app];
    NSString *appIdentifier =
        [appBundle.bundleIdentifier stringByAppendingPathExtension:@"launcher"];

    AHLaunchDomain domain = global ? kAHGlobalLaunchAgent : kAHUserLaunchAgent;

    if (launch) {
        AHLaunchJob *job = [AHLaunchJob new];
        job.Label = appIdentifier;
        job.Program = appBundle.executablePath;
        job.RunAtLoad = YES;
        job.KeepAlive =
            @{ @"SuccessfulExit" : [NSNumber numberWithBool:keepAlive] };

        return [[AHLaunchCtl new] add:job toDomain:domain error:error];
    } else {
        return [[AHLaunchCtl new] remove:appIdentifier
                              fromDomain:domain
                                   error:error];
    }
}

+ (void)scheduleJob:(NSString *)label
            program:(NSString *)program
           interval:(int)seconds
             domain:(AHLaunchDomain)domain
              reply:(void (^)(NSError *error))reply {
    [self scheduleJob:label
                 program:program
        programArguments:nil
                interval:seconds
                  domain:domain
                   reply:^(NSError *error) {
                     reply(error);
                   }];
}

+ (void)scheduleJob:(NSString *)label
            program:(NSString *)program
   programArguments:(NSArray *)programArguments
           interval:(int)seconds
             domain:(AHLaunchDomain)domain
              reply:(void (^)(NSError *error))reply {
    AHLaunchCtl *controller = [AHLaunchCtl new];
    AHLaunchJob *job = [AHLaunchJob new];
    job.Label = label;
    job.Program = program;
    job.ProgramArguments = programArguments;
    job.RunAtLoad = YES;
    job.StartInterval = seconds;

    NSError *error;
    [controller add:job toDomain:domain error:&error];
    reply(error);
}

#pragma mark--- Get Job ---
+ (AHLaunchJob *)jobFromFileNamed:(NSString *)label
                         inDomain:(AHLaunchDomain)domain {
    NSArray *jobs = [self allJobsFromFilesInDomain:domain];
    if ([label.pathExtension isEqualToString:@"plist"])
        label = [label stringByDeletingPathExtension];

    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"%@ == SELF.Label ", label];

    for (AHLaunchJob *job in jobs) {
        if ([predicate evaluateWithObject:job]) {
            return job;
        }
    }
    return nil;
}

+ (AHLaunchJob *)runningJobWithLabel:(NSString *)label
                            inDomain:(AHLaunchDomain)domain {
    AHLaunchJob *job = nil;
    NSDictionary *dict = AHJobCopyDictionary(domain, label);
    // for some system processes the dict can return nil, so we have a more
    // expensive back-up in that case;
    if (dict.count) {
        job = [AHLaunchJob jobFromDictionary:dict inDomain:domain];
    } else {
        job = [[[self class] runningJobsMatching:label
                                        inDomain:domain] lastObject];
    }

    return job;
}

#pragma mark--- Get Array Of Jobs ---
+ (NSArray *)allRunningJobsInDomain:(AHLaunchDomain)domain {
    return [self jobMatch:nil domain:domain];
}

+ (NSArray *)runningJobsMatching:(NSString *)match
                        inDomain:(AHLaunchDomain)domain {
    NSPredicate *predicate = [NSPredicate
        predicateWithFormat:
            @"SELF.Label CONTAINS[c] %@ OR SELF.Program CONTAINS[c] %@", match,
            match];
    return [self jobMatch:predicate domain:domain];
}

+ (NSArray *)allJobsFromFilesInDomain:(AHLaunchDomain)domain {
    AHLaunchJob *job;
    NSMutableArray *jobs;
    NSString *launchDirectory = launchdJobFileDirectory(domain);
    NSArray *launchFiles = [[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:launchDirectory
                            error:nil];

    if (launchFiles.count) {
        jobs = [[NSMutableArray alloc] initWithCapacity:launchFiles.count];
    }

    for (NSString *file in launchFiles) {
        NSString *filePath =
            [NSString stringWithFormat:@"%@/%@", launchDirectory, file];
        NSDictionary *dict =
            [NSDictionary dictionaryWithContentsOfFile:filePath];
        if (dict) {
            @try {
                job = [AHLaunchJob jobFromDictionary:dict inDomain:domain];
                if (job) job.domain = domain;
                [jobs addObject:job];
            } @catch (NSException *exception) {
                NSLog(@"error %@", exception);
            }
        }
    }
    return jobs;
}

+ (NSArray *)jobMatch:(NSPredicate *)predicate domain:(AHLaunchDomain)domain {
    NSArray *array = AHCopyAllJobDictionaries(domain);
    if (!array.count) return nil;

    NSMutableArray *jobs =
        [[NSMutableArray alloc] initWithCapacity:array.count];
    for (NSDictionary *dict in array) {
        AHLaunchJob *job;
        if (predicate) {
            if ([predicate evaluateWithObject:dict]) {
                job = [AHLaunchJob jobFromDictionary:dict inDomain:domain];
            }
        } else {
            job = [AHLaunchJob jobFromDictionary:dict inDomain:domain];
        }
        if (job) {
            job.domain = domain;
            [jobs addObject:job];
        }
    }
    return [NSArray arrayWithArray:jobs];
}

#pragma mark - Private
- (BOOL)createAuthorization:(AuthorizationRef *)authRef
                     domain:(AHLaunchDomain)domain
                      label:(NSString *)label
                     prompt:(NSString *)prompt
                      error:(NSError *__autoreleasing *)error {
    OSStatus status = errSecSuccess;

    // If domain is greater than the user domain,
    if ((domain > kAHUserLaunchAgent)) {
        if (_authRef != NULL) {
            *authRef = _authRef;
            status = errSecSuccess;
        } else {
            status = [AHAuthorizer authorizeSystemDaemonWithLabel:label
                                                           prompt:prompt
                                                          authRef:authRef];
        }

        if (status != errSecSuccess) {
            if (status == errAuthorizationCanceled) {
                [[self class] errorWithCode:kAHErrorUserCanceledAuthorization
                                      error:error];
            } else {
                [[self class] errorWithCode:kAHErrorInsufficientPrivileges
                                      error:error];
            }
        }
    }
    return (status == errSecSuccess);
}

- (BOOL)jobIsValid:(AHLaunchJob *)job error:(NSError *__autoreleasing *)error {
    NSFileManager *fm = [NSFileManager defaultManager];

    // The first argument needs to be executable
    if (![fm isExecutableFileAtPath:[job.ProgramArguments firstObject]]) {
        return [[self class] errorWithCode:kAHErrorProgramNotExecutable
                                     error:error];
    }

    // LaunchD's need a label
    if (!job.Label || !job.Label.length) {
        return [[self class] errorWithCode:kAHErrorJobMissingRequiredKeys
                                     error:error];
    }

    return YES;
}

- (BOOL)removeJobFileWithLabel:(NSString *)label
                        domain:(AHLaunchDomain)domain
                       authRef:(AuthorizationRef)authRef
                         error:(NSError *__autoreleasing *)error {
    NSFileManager *fm = [NSFileManager new];
    NSString *file = launchdJobFile(label, domain);
    BOOL isDir;
    if ([fm fileExistsAtPath:file isDirectory:&isDir] && !isDir) {
        return [fm removeItemAtPath:file error:error];
    } else if (isDir) {
        return [[self class] errorWithCode:kAHErrorFileIsDirectory error:error];
    } else {
        return YES;
    }
}

#pragma mark - Error Codes
+ (BOOL)errorWithCode:(NSInteger)code error:(NSError *__autoreleasing *)error {
    BOOL rc = code != 0 ? NO : YES;
    NSString *msg = errorMsgFromCode(code);
    NSError *err =
        [NSError errorWithDomain:kAHLaunchCtlDomain
                            code:code
                        userInfo:@{NSLocalizedDescriptionKey : msg}];
    if (error) {
        *error = err;
    } else {
        NSLog(@"Error: %@", msg);
    }

    return rc;
}

+ (BOOL)errorWithMessage:(NSString *)message
                 andCode:(NSInteger)code
                   error:(NSError *__autoreleasing *)error {
    BOOL rc = code != 0 ? NO : YES;
    NSError *err =
        [NSError errorWithDomain:kAHLaunchCtlDomain
                            code:code
                        userInfo:@{NSLocalizedDescriptionKey : message}];

    if (error) {
        *error = err;
    } else {
        NSLog(@"Error: %@", message);
    }
    return rc;
}

+ (BOOL)errorWithCFError:(CFErrorRef)cfError
                    code:(int)code
                   error:(NSError *__autoreleasing *)error {
    BOOL rc = code != 0 ? NO : YES;

    NSError *err = CFBridgingRelease(cfError);
    if (error) {
        *error = err;
    } else {
        NSLog(@"Error: %@", err.localizedDescription);
    }

    return rc;
}

@end

#pragma mark - Utility Functions

static NSString *errorMsgFromCode(NSInteger code) {
    NSString *msg;
    switch (code) {
        case kAHErrorJobNotLoaded:
            msg =
                NSLocalizedStringFromTable(@"Job not loaded", @"AHLaunchCtl",
                                           @"Error when the job is not loaded");
            break;
        case kAHErrorFileNotFound:
            msg = NSLocalizedStringFromTable(
                @"Could not find the specified launchd.plist to load the job",
                @"AHLaunchCtl", @"Error when the job file is not found.");
            break;
        case kAHErrorFileIsDirectory:
            msg = NSLocalizedStringFromTable(
                @"The suggested file to remove is a directory.", @"AHLaunchCtl",
                @"Error when the FILE that is suppose to be removed is a "
                @"directory");
            break;
        case kAHErrorCouldNotLoadJob:
            msg = NSLocalizedStringFromTable(
                @"Could not load job", @"AHLaunchCtl",
                @"Error when the job is not loaded");
            break;
        case kAHErrorCouldNotLoadHelperTool:
            msg = NSLocalizedStringFromTable(
                @"Unable to install the privileged helper tool", @"AHLaunchCtl",
                @"Error when the helper tool cannot be loaded.");
            break;
        case kAHErrorCouldNotUnloadHelperTool:
            msg = NSLocalizedStringFromTable(
                @"Unable to remove the privileged helper tool", @"AHLaunchCtl",
                @"Error when cannot unload helper tool");
            break;
        case kAHErrorHelperToolNotLoaded:
            msg = NSLocalizedStringFromTable(
                @"Cannot unload The helper tool, it is not currently loaded.",
                @"AHLaunchCtl", @"Error when the helper tool is not loaded");
            break;
        case kAHErrorCouldNotRemoveHelperToolFiles:
            msg = NSLocalizedStringFromTable(
                @"Unable to remove some files associated with the privileged "
                @"helper tool",
                @"AHLaunchCtl", @"Error when a removing privileged helper.");
            break;
        case kAHErrorJobAlreadyExists:
            msg = NSLocalizedStringFromTable(
                @"The specified job already exists", @"AHLaunchCtl",
                @"Error when the job is alreay exists");
            break;
        case kAHErrorJobAlreadyLoaded:
            msg = NSLocalizedStringFromTable(
                @"The specified job is already loaded", @"AHLaunchCtl",
                @"Error when the job is already loaded");
            break;
        case kAHErrorJobCouldNotReload:
            msg = NSLocalizedStringFromTable(
                @"There were problems reloading the job", @"AHLaunchCtl",
                @"Error when the could not be reloaded");
            break;
        case kAHErrorJobLabelNotValid:
            msg = NSLocalizedStringFromTable(
                @"The job label is not valid.", @"AHLaunchCtl",
                @"Error when the job label is not valid");
            break;
        case kAHErrorCouldNotUnloadJob:
            msg = NSLocalizedStringFromTable(
                @"Could not unload job", @"AHLaunchCtl",
                @"Error when the job could not be unloaded");
            break;
        case kAHErrorMultipleJobsMatching:
            msg = NSLocalizedStringFromTable(
                @"More than one job matched that description", @"AHLaunchCtl",
                @"Error when the job matching returned more than one result");
            break;
        case kAHErrorCouldNotWriteFile:
            msg = NSLocalizedStringFromTable(
                @"There were problem writing to the file", @"AHLaunchCtl",
                @"Error when the the launchd.plist file could not be written");
            break;
        case kAHErrorInsufficientPrivileges:
            msg = NSLocalizedStringFromTable(
                @"You are not authorized to to perform this action",
                @"AHLaunchCtl", @"Error when user is not authorized.");
            break;
        case kAHErrorJobMissingRequiredKeys:
            msg = NSLocalizedStringFromTable(
                @"The Submitted Job was missing some required keys",
                @"AHLaunchCtl", @"Error when the job is missing required keys");
            break;
        case kAHErrorExecutingAsIncorrectUser:
            msg = NSLocalizedStringFromTable(
                @"Could not set the Job to run in the proper context",
                @"AHLaunchCtl", @"Error when job context could not be set.");
            break;
        case kAHErrorProgramNotExecutable:
            msg = NSLocalizedStringFromTable(
                @"The path specified doesn’t appear to be executable.",
                @"AHLaunchCtl",
                @"Error when the submitted job's executable could not be set.");
            break;
        case kAHErrorUserCanceledAuthorization:
            msg = NSLocalizedStringFromTable(
                @"Authorizaton canceled by user.", @"AHLaunchCtl",
                @"Error when authorization is canceled by user");
        default:
            msg = (__bridge_transfer NSString *)SecCopyErrorMessageString(
                      (int)code, NULL)
                      ?: NSLocalizedStringFromTable(
                             @"An unknown problem occurred", @"AHLaunchCtl",
                             @"Generic error");
            break;
    }
    return msg;
}
