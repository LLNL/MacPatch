//  AHServiceManagement.h
//  AHLaunchCtl
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

/** ~/Library/LaunchAgents/
 * @warning Make sure to expand the tilde if necissary for checking!
 */
extern NSString *const kAHUserLaunchAgentTildeDirectory;

/** /Library/LaunchDaemons/ */
extern NSString *const kAHGlobalLaunchDaemonDirectory;

/** /Library/LaunchAgents/ */
extern NSString *const kAHGlobalLaunchAgentDirectory;

/** /System/Library/LaunchDaemons/ */
extern NSString *const kAHSystemLaunchDaemonDirectory;

/** /System/Library/LaunchAgents/ */
extern NSString *const kAHSystemLaunchAgentDirectory;



/**
 *  Function to test whether the job is currently running
 *
 *  @param label  Label of the LaunchD job
 *  @param domain AHLaunchDomain
 *
 *  @return YES if Loaded, NO otherwise
 */
extern BOOL jobIsRunning(NSString *label, AHLaunchDomain domain);

/**
 *  More expensive version of jobIsRunning(), but will not cause "launchadd: FAILURE:" messages to appear in the system.log when the job is not loaded.
 *
 *  @param label  Label of the LaunchD job
 *  @param domain AHLaunchDomain
 *
 *  @return YES if Loaded, NO otherwise
 */
extern BOOL jobIsRunning2(NSString *label, AHLaunchDomain domain);

#pragma mark - Bridged ServiceManagement

/**
 *  Dictionary representation of the LaunchD job
 *
 *  @param domain Domain of the job
 *  @param label  Label of the job
 *
 *  @return Populated dictionary if job exists
 */
extern NSDictionary *AHJobCopyDictionary(AHLaunchDomain domain,
                                         NSString *label);

/**
 *  Array of Jobs
 *
 *  @param domain Domain to get jobs from
 *
 *  @return Array of Jobs
 */
extern NSArray *AHCopyAllJobDictionaries(AHLaunchDomain domain);

/**
 *  Submit a job to load
 *
 *  @param domain     Domain for the job
 *  @param dictionary Job object and keys
 *  @param authRef    Authorization data for job
 *  @param error      Pointer to error to populate should one occur
 *
 *  @return YES if job was successfully loaded, NO otherwise
 */
extern BOOL AHJobSubmit(AHLaunchDomain domain,
                        NSDictionary *dictionary,
                        AuthorizationRef authRef,
                        NSError **error);

/**
 *  Submit a job to load and create requisite files for persistence.
 *
 *  @param domain     Domain for the job
 *  @param dictionary Job object and keys
 *  @param authRef    Authorization data for job
 *  @param error      Pointer to error to populate should one occur
 *
 *  @return YES if job was successfully loaded, NO otherwise
 */
BOOL AHJobSubmitCreatingFile(AHLaunchDomain domain,
                             NSDictionary *dictionary,
                             AuthorizationRef authRef,
                             NSError *__autoreleasing *error);

/**
 *  Remove a loaded job
 *
 *  @param domain     Domain for the job
 *  @param label      Label of the job
 *  @param authRef    Authorization data for job
 *  @param error      Pointer to error to populate should one occur
 *
 *  @return YES if job was successfully loaded, NO otherwise
 */
extern BOOL AHJobRemove(AHLaunchDomain domain,
                        NSString *label,
                        AuthorizationRef authRef,
                        NSError **error);

/**
 *  Remove a loaded job from the registry and delete the file.
 *
 *  @param domain     Domain for the job
 *  @param label      Label of the job
 *  @param authRef    Authorization data for job
 *  @param error      Pointer to error to populate should one occur
 *
 *  @return YES if job was successfully loaded, NO otherwise
 */
extern BOOL AHJobRemoveIncludingFile(AHLaunchDomain domain,
                                     NSString *label,
                                     AuthorizationRef authRef,
                                     NSError **error);

/**
 *  Submits the executable for the given label as a launchd job.
 *  @param domain     Domain for the job
 *  @param label      Label of the executable
 *  @param authRef    Authorization data for job
 *  @param error      Pointer to error to populate should one occur
 *
 *  @return YES if job was successfully loaded, NO otherwise
 */
extern BOOL AHJobBless(AHLaunchDomain domain,
                       NSString *label,
                       AuthorizationRef authRef,
                       NSError **error);

/**
 *  Removes the executable, and unloads the job.
 *  @param domain     Domain for the job
 *  @param label      Label of the executable
 *  @param authRef    Authorization data for job
 *  @param error      Pointer to error to populate should one occur
 *
 *  @return YES if job was successfully loaded, NO otherwise
 */
extern BOOL AHJobUnbless(AHLaunchDomain domain,
                         NSString *label,
                         AuthorizationRef authRef,
                         NSError **error);
