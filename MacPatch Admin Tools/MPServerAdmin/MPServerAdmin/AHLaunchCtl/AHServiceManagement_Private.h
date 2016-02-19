//
//  AHServiceManagement_Private.h
//  AHLaunchCtl
//
//  Created by Eldon on 2/21/15.
//  Copyright (c) 2015 Eldon Ahrold. All rights reserved.
//

#ifndef AHLaunchCtl_AHServiceManagement_Private_h
#define AHLaunchCtl_AHServiceManagement_Private_h

/**
 *  Directory path for launchd.plist files based on the supplied domain.
 *
 *  @param domain AHLaunchDomain.
 *
 *  @return Directory path for domain.
 */
extern NSString *launchdJobFileDirectory(AHLaunchDomain domain);

/**
 *  Get the file path to the launchd.plist based on the supplied domain.
 *
 *  @param label  label of the launchd plist
 *  @param domain AHLaunchDomain
 *
 *  @return File path to the launchd.plist
 */
extern NSString *launchdJobFile(NSString *label, AHLaunchDomain domain);

/**
 *  Convert an AHLaunchDomain to an Service Management domain
 *
 *  @param domain AHLaunchDomain
 *
 *  @return the Service management domain to pass into SM functions.
 */
extern NSString *SMDomain(AHLaunchDomain domain);

BOOL AHCreatePrivilegedLaunchdPlist(AHLaunchDomain domain,
                                    NSDictionary *dictionary,
                                    AuthorizationRef authRef,
                                    NSError *__autoreleasing *error);

BOOL AHRemovePrivilegedFile(AHLaunchDomain domain,
                            NSString *filePath,
                            AuthorizationRef authRef,
                            NSError *__autoreleasing *error);

#endif
