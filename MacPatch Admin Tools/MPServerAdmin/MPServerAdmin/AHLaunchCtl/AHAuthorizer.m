//  AHAuthorizer.m
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

#import "AHAuthorizer.h"

static NSString *kNSAuthorizationJobBless =
    @"com.apple.ServiceManagement.blesshelper";
static NSString *kNSAuthorizationSystemDaemon =
    @"com.apple.ServiceManagement.daemons.modify";

@implementation AHAuthorizer

+ (AuthorizationFlags)defaultFlags {
    static dispatch_once_t onceToken;
    static AuthorizationFlags authFlags;
    dispatch_once(&onceToken, ^{
        authFlags =
            kAuthorizationFlagInteractionAllowed |
            kAuthorizationFlagPreAuthorize |
            kAuthorizationFlagExtendRights;
    });
    return authFlags;
}

+ (OSStatus)authorizeSystemDaemonWithLabel:(NSString *)label
                                    prompt:(NSString *)prompt
                                   authRef:(AuthorizationRef *)authRef {
    AuthorizationItem authItem = {
        kNSAuthorizationSystemDaemon.UTF8String, 0, NULL, 0};

    if (!prompt || !prompt.length) {
        prompt = [NSString
            stringWithFormat:@"%@ is trying to perform a privileged operation.",
                             [[NSProcessInfo processInfo] processName]];
    }

    //Get userID
    uid_t uid = getuid();
    if (uid != 0) {
        // Only setup custom auth name if not running as root.
        authItem.name = label.UTF8String;
    }

    return [self authorizePrompt:prompt authItems:authItem authRef:authRef];
}

+ (OSStatus)authorizeSMJobBlessWithPrompt:(NSString *)prompt
                                  authRef:(AuthorizationRef *)authRef {
    AuthorizationItem authItem = {
        kNSAuthorizationJobBless.UTF8String, 0, NULL, 0};
    return [self authorizePrompt:prompt authItems:authItem authRef:authRef];
};

+ (OSStatus)authorizePrompt:(NSString *)prompt
                  authItems:(AuthorizationItem)authItem
                    authRef:(AuthorizationRef *)authRef {
    AuthorizationRights authRights = {1, &authItem};
    AuthorizationEnvironment environment = {0, NULL};

    if (prompt) {
        AuthorizationItem envItem = {kAuthorizationEnvironmentPrompt,
                                     prompt.length,
                                     (void *)prompt.UTF8String,
                                     0};
        environment.count = 1;
        environment.items = &envItem;
    }

    return AuthorizationCreate(
        &authRights, &environment, [[self class] defaultFlags], authRef);
}

+ (void)authorizationFree:(AuthorizationRef)authRef {
    if (authRef != NULL) {
        OSStatus junk =
            AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
        assert(junk == errAuthorizationSuccess);
    }
}

@end
