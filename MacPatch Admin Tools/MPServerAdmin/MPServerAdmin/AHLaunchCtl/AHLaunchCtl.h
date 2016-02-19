//  AHLaunchCtl.h
//
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

#import <Foundation/Foundation.h>
#import "AHLaunchJob.h"

/**
 *  AHLaunchCtlErrorCodes
 */
typedef NS_ENUM(NSInteger, AHLaunchCtlErrorCodes) {
    /**
     *  No Error
     */
    kAHErrorSuccess,
    /**
     *  Error encountered when job label that is not in dot syntax or has spaces
     */
    kAHErrorJobLabelNotValid,
    /**
     *  job requires Label and Program Arguments
     */
    kAHErrorJobMissingRequiredKeys,
    /**
     *  Error encountered when job is not Loaded
     */
    kAHErrorJobNotLoaded,
    /**
     *  Error encountered when job already exists
     */
    kAHErrorJobAlreadyExists,
    /**
     *  Error Encountered when job already loaded
     */
    kAHErrorJobAlreadyLoaded,
    /**
     *  Error Encountered when trying to load a job
     */
    kAHErrorCouldNotLoadJob,
    /**
     *  Error Encountered when trying to load a helper tool
     */
    kAHErrorCouldNotLoadHelperTool,
    /**
     *   Error Encountered when trying a helper tool could not be removed
     */
    kAHErrorCouldNotUnloadHelperTool,
    /**
     *  Error Encountered when trying a helper tool could not be removed
     */
    kAHErrorHelperToolNotLoaded,
    /**
     *  Error Encountered when files associated with helper tool could not be
     * removed
     */
    kAHErrorCouldNotRemoveHelperToolFiles,
    /**
     *  Error Encountered when a job could not be unloaded
     */
    kAHErrorCouldNotUnloadJob,
    /**
     *  Error Encountered when a job could not be reloaded
     */
    kAHErrorJobCouldNotReload,
    /**
     *  Error Encountered when the launchd.plist file could not be located
     */
    kAHErrorFileNotFound,
    /**
     *  Error Encountered when the launchd.plist is actually a directory not a file
     */
    kAHErrorFileIsDirectory,
    /**
     *  Error Encountered when the launchd.plist file could not be written or
     * insufficient privileges
     */
    kAHErrorCouldNotWriteFile,
    /**
     *  Error Encountered when more than one job with the same label exist
     */
    kAHErrorMultipleJobsMatching,
    /**
     *  Error Encountered when user is not privileged to install into domain
     */
    kAHErrorInsufficientPrivileges,
    /**
     *  Error Encountered when a user is trying to unload another's launch job
     */
    kAHErrorExecutingAsIncorrectUser,
    /**
     *  Error Encountered when the program to be loaded is not executable
     */
    kAHErrorProgramNotExecutable,
    /**
     *  User Canceled authorization.
     */
    kAHErrorUserCanceledAuthorization = errAuthorizationCanceled,
};

/**
 *  Objective-C Framework For LaunchAgents and LaunchDaemons
 */
@interface AHLaunchCtl : NSObject

/**
 *  Singleton Object to handle AHLaunchJobs
 *
 *  @return Shared Controller
 */
+ (AHLaunchCtl *)sharedController;
#pragma mark - Public Methods
/**
 *  Create session wide authorization linked to the controller.
 *
 *  @param string to display for the Authorization creation dialog.
 *
 *  @return
 */
- (BOOL) authorizeWithPrompt:(NSString *)prompt;
- (BOOL) authorize;

/**
 *  Deauthorize the session.
 *  @note This is called when the controller is deallocated.
 */
- (void)deauthorize;

/**
 *  Write the launchd.plist and load the job into context
 *
 *  @param job AHLaunchJob with desired keys.
 *  @param domain Corresponding AHLaunchDomain.
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)add:(AHLaunchJob *)job
    toDomain:(AHLaunchDomain)domain
       error:(NSError **)error;

/**
 *  Remove launchd.plist and unload the job
 *
 *  @param label Name of the running launchctl job.
 *  @param domain Corresponding AHLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)remove:(NSString *)label
    fromDomain:(AHLaunchDomain)domain
         error:(NSError **)error;

/**
 *  Loads launchd job (will not write file)
 *  @param job AHLaunchJob Object, Label and Program keys required.
 *  @param domain Corresponding AHLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)load:(AHLaunchJob *)job
    inDomain:(AHLaunchDomain)domain
       error:(NSError **)error;

/**
 *  Unloads a launchd job (will not remove file)
 *  @param label Name of the running launchctl job.
 *  @param domain Corresponding AHLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)unload:(NSString *)label
      inDomain:(AHLaunchDomain)domain
         error:(NSError **)error;

/**
 *  Loads and existing launchd.plist
 *  @param label Name of the launchctl file.
 *  @param domain Corresponding AHLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)start:(NSString *)label
     inDomain:(AHLaunchDomain)domain
        error:(NSError **)error;

/**
 *  Stops a running launchd job, synonomus with unload
 *  @param label Name of the running launchctl job.
 *  @param error Populated should an error occur.
 *  @param domain Corresponding AHLaunchDomain
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)stop:(NSString *)label
    inDomain:(AHLaunchDomain)domain
       error:(NSError **)error;

/**
 *  Restarts a launchd job with an existsing launchd.plist file.
 *  @param label Name of the running launchctl job.
 *  @param domain Corresponding AHLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)restart:(NSString *)label
       inDomain:(AHLaunchDomain)domain
          error:(NSError **)error;

#pragma mark - Class Methods
/**
 *  Launch an application at login.
 *  @param app Path to the Application
 *  @param launch YES to launch, NO to stop launching
 *  @param global YES to launch for all users, NO to launch for current user.
 *  @param keepAlive YES to relaunch in the event of a crash or an attempt to
 *quit
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
+ (BOOL)launchAtLogin:(NSString *)app
               launch:(BOOL)launch
               global:(BOOL)global
            keepAlive:(BOOL)keepAlive
                error:(NSError **)error;

/**
 *  Schedule a LaunchD Job to run at an interval.
 *  @param label uniquely identifier for launchd.  This should be in the form a
 *a reverse domain
 *  @param program Path to the executable to run
 *  @param interval How often (in seconds) to run.
 *  @param domain Corresponding AHLaunchDomain
 *  @param reply Reply block executed on completion that has no return value and
 *takes on argument NSError.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
+ (void)scheduleJob:(NSString *)label
            program:(NSString *)program
           interval:(int)interval
             domain:(AHLaunchDomain)domain
              reply:(void (^)(NSError *error))reply;
/**
 *  Schedule a LaunchD Job to run at an interval.
 *  @param label uniquely identifier for launchd.  This should be in the form a
 *a reverse domain
 *  @param program Path to the executable to run
 *  @param programArguments Array of arguments to pass to the executable.
 *  @param interval How often (in seconds) to run.
 *  @param domain Corresponding AHLaunchDomain
 *  @param reply Reply block executed on completion that has no return value and
 *takes on argument NSError.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
+ (void)scheduleJob:(NSString *)label
             program:(NSString *)program
    programArguments:(NSArray *)programArguments
            interval:(int)interval
              domain:(AHLaunchDomain)domain
               reply:(void (^)(NSError *error))reply;

/**
 *  Create a job object based on a launchd.plist file
 *  @param label uniquely identifier for launchd.  This should be in the form a
 *a reverse domain
 *  @param domain Corresponding AHLaunchDomain
 *
 *  @return an allocated AHLaunchJob with the corresponding keys
 */
+ (AHLaunchJob *)jobFromFileNamed:(NSString *)label
                         inDomain:(AHLaunchDomain)domain;

/**
 *  Create a job object based on currently running Launchd Job
 *  @param label uniquely identifier for launchd.  This should be in the form a
 *a reverse domain
 *  @param domain Corresponding AHLaunchDomain
 *
 *  @return an allocated AHLaunchJob with the corresponding keys
 */
+ (AHLaunchJob *)runningJobWithLabel:(NSString *)label
                            inDomain:(AHLaunchDomain)domain;

/**
 *  List with all Jobs available based of files in the specified domain
 *  @param domain Corresponding AHLaunchDomain
 *
 *  @return Array of allocated AHLaunchJob with the corresponding keys
 */
+ (NSArray *)allJobsFromFilesInDomain:(AHLaunchDomain)domain;

/**
 *  List with all currently running jobs in the specified domain
 *  @param domain Corresponding AHLaunchDomain
 *
 *  @return Array of allocated AHLaunchJob with the corresponding keys
 */
+ (NSArray *)allRunningJobsInDomain:(AHLaunchDomain)domain;

/**
 *  List of running Jobs based on criteria
 *
 *  @param match  string to match.
 *  @param domain AHLaunchDomain
 *
 *  @return Array of allocated AHLaunchJob with the corresponding keys
 */
+ (NSArray *)runningJobsMatching:(NSString *)match
                        inDomain:(AHLaunchDomain)domain;

/**
 *  installs a privileged helper tool with the specified label.
 *
 *  @param label  label of the Helper Tool
 *  @param prompt message to prefix the authorization prompt
 *  @param error  populated should error occur
 *
 *  @return YES for success NO on failure;
 *  @warning Must be code singed properly, and have an embedded Info.plist and
 *Launchd.plist, and located in the applications
 *MainBundle/Library/LaunchServices
 */
+ (BOOL)installHelper:(NSString *)label
               prompt:(NSString *)prompt
                error:(NSError **)error;

/**
 *  Uninstalls HelperTool with specified label.
 *
 *  @param label Label of the Helper Tool.
 *  @param prompt Message to prefix the authorization prompt.
 *  @param error Error object populated if an error occurs.
 *  @return YES for success NO on failure;
 */
+ (BOOL)uninstallHelper:(NSString *)label
                 prompt:(NSString *)prompt
                  error:(NSError *__autoreleasing *)error;
/**
 *  uninstalls HelperTool with specified label.
 *
 *  @param label label of the Helper Tool
 *  @param error error object populated if an error occurs.
 *
 *  @return YES for success NO on failure;
 */
+ (BOOL)uninstallHelper:(NSString *)label
                  error:(NSError *__autoreleasing *)error
    __attribute__((deprecated));

/**
 *  Cleans up files associated with the helper tool that SMJobBless leaves
 *behind
 *
 *  @param label label of the Helper Tool
 *  @param error error object populated if an error occurs.
 *
 *  @return YES for success NO on failure;
 */
+ (BOOL)removeFilesForHelperWithLabel:(NSString *)label
                                error:(NSError *__autoreleasing *)error;

#pragma mark - Domain Error
/**
 *  Convenience Method for populating an NSError using message and code.  It
 *also can be used to provide a return value for escaping another method. e.g.
 *on failure of a previous condition you could do "return [AHLaunchCtl
 *errorWithMessage:@"your message" andCode:1 error:error]" and you'll get
 *escaped out, if method return you're using on has BOOL return and error is
 *already an __autoreleasing error pointer
 *
 *  @param message Human readable error message
 *  @param code    error Code
 *  @param error   error pointer
 *
 *  @return YES if error code passed is 0, NO on all other error codes passed
 *into;
 */
+ (BOOL)errorWithMessage:(NSString *)message
                 andCode:(NSInteger)code
                   error:(NSError **)error;

@end
