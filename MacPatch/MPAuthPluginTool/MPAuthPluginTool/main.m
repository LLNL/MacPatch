//
//  main.m
//  MPAuthPluginTool
//
/*
 Copyright (c) 2013, Lawrence Livermore National Security, LLC.
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

#import <Foundation/Foundation.h>
#include <Security/AuthorizationDB.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <unistd.h>


#define		LOGIN_RIGHT		@"system.login.console"
#define		AUTH_SERVICE	@"MPAuthPlugin"
#define		AUTH_MECH		@"window"
#define		AUTH_MECH_INDEX	0

#define     APPVERSION      @"1.0.1"
#define     APPNAME         @"MPAuthPluginTool"

void usage(void);

int main(int argc, char * argv[])
{

    @autoreleasepool {

        int _action             = 0; // 0 = add, 1 = delete, 2 = read
        int _mechanismIndex     = AUTH_MECH_INDEX;
        NSString *_right        = LOGIN_RIGHT;
        NSString *_service      = AUTH_SERVICE;
        NSString *_mechanism    = AUTH_MECH;

        // Setup argument processing
        int c;
        while (1)
        {
            static struct option long_options[] =
            {
                {"right"			,required_argument	    ,0, 'r'},
                {"service"			,required_argument	    ,0, 's'},
                {"mechanism"		,required_argument	    ,0, 'm'},
                {"index"			,required_argument	    ,0, 'i'},
                {"add"              ,no_argument	    ,0, 'a'},
                {"delete"			,no_argument	    ,0, 'd'},
                {"read"             ,no_argument	    ,0, 'R'},
                {"version"			,no_argument		,0, 'v'},
                {"help"				,no_argument		,0, 'h'},
                {0, 0, 0, 0}
            };
            // getopt_long stores the option index here.
            int option_index = 0;
            c = getopt_long (argc, argv, "r:s:m:i:adRvh", long_options, &option_index);

            // Detect the end of the options.
            if (c == -1)
                break;

            switch (c)
            {
                case 'r':
                    _right = [NSString stringWithUTF8String:optarg];
                    break;
                case 's':
                    _service = [NSString stringWithUTF8String:optarg];
                    break;
                case 'm':
                    _mechanism = [NSString stringWithUTF8String:optarg];
                    break;
                case 'i':
                    _mechanismIndex = [[NSString stringWithUTF8String:optarg] intValue];
                    break;
                case 'a':
                    _action = 0;
                    break;
                case 'd':
                    _action = 1;
                    break;
                case 'R':
                    _action = 2;
                    break;
                case 'v':
                    printf("%s\n",[APPVERSION UTF8String]);
                    return 0;
                case 'h':
                case '?':
                default:
                    usage();
            }
        }
        
        if (optind < argc) {
            while (optind < argc) {
                printf ("Invalid argument %s ", argv[optind++]);
            }
            usage();
            exit(0);
        }
        
        // Make sure the user is root or is using sudo
        if (getuid()) {
            printf("You must be root to run this app. Try using sudo.\n");
#if DEBUG
            printf("Running as debug...\n");
#else
            exit(0);
#endif
        }
        
        CFDictionaryRef login_dict;
        OSStatus status;
        AuthorizationRef authRef;
        CFArrayRef arrayRef;
        CFMutableArrayRef newMechanisms;
        CFMutableDictionaryRef new_login_dict;
        CFStringRef mechansimString;
        CFStringRef existingMechanismString;

        status = AuthorizationCreate(NULL, NULL, 0, &authRef);
        if (status) {
            exit(1);
        }

        status = AuthorizationRightGet([_right UTF8String], &login_dict);
        if (status) {
            exit(0);
        }

        if (!CFDictionaryGetValueIfPresent(login_dict, CFSTR("mechanisms"), (const void **)&arrayRef)) {
            exit(1);
        }

        newMechanisms = CFArrayCreateMutableCopy(NULL, 0, arrayRef);
        if (!newMechanisms) {
            exit(1);
        }

        // Generate the mechanism string
        mechansimString = CFStringCreateWithFormat( kCFAllocatorDefault, NULL, CFSTR( "%s:%s" ), [_service UTF8String], [_mechanism UTF8String] );

        if (_action == 0)
        {
            // Write ...
            existingMechanismString = (CFStringRef) CFArrayGetValueAtIndex( newMechanisms, _mechanismIndex );
            if ( CFStringHasPrefix( existingMechanismString, (__bridge CFStringRef)(_service) ) )
            {
                // if the mechanism is already in place, then replace it
                CFArraySetValueAtIndex( newMechanisms, _mechanismIndex, mechansimString );
            } else {
                // Mechanism is not there, so insert the new mechanism
                CFArrayInsertValueAtIndex( newMechanisms, _mechanismIndex, mechansimString );
            }
        }
        if (_action == 1)
        {
            // Remove ...
            int arrCount = (int)[(__bridge NSArray *)newMechanisms count];
            int i = 0;
            while (i != arrCount)
            {
                CFStringRef val = (CFStringRef) CFArrayGetValueAtIndex(newMechanisms, i);
                if (CFStringCompare(val, mechansimString, 0) == kCFCompareEqualTo)
                {
                    CFArrayRemoveValueAtIndex(newMechanisms, i);
                    break;
                }
                i++;
            }
        }
        if (_action == 2)
        {
            // Read ...
            NSDictionary *d = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)((CFDictionaryRef)login_dict)];
            NSLog(@"%@",[d objectForKey:@"mechanisms"]);
            if (mechansimString)
                CFRelease(mechansimString);
            if (newMechanisms)
                CFRelease(newMechanisms);

            return 0;
        }

        // Write out new value
        new_login_dict = CFDictionaryCreateMutableCopy(NULL, 0, login_dict);
        CFDictionarySetValue(new_login_dict, CFSTR("mechanisms"), newMechanisms);
        status = AuthorizationRightSet(authRef, [_right UTF8String], new_login_dict, NULL, NULL, NULL);

        if (mechansimString)
            CFRelease(mechansimString);
        if (newMechanisms)
            CFRelease(newMechanisms);
        if (new_login_dict)
            CFRelease(new_login_dict);
        return status;
    }
    return 0;
}

void usage(void) {

	printf("%s:\n",[APPNAME UTF8String]);
	printf("Version %s\n\n",[APPVERSION UTF8String]);
	printf("Usage: %s [ACTION] [OPTIONS]\n",[APPNAME UTF8String]);
    printf("\n");
    printf("Actions:\n");
    printf(" -a | --add \t\t Add Service Mechanism.\n");
    printf(" -d | --delete \t\t Delete Service Mechanism.\n");
    printf(" -R | --read \t\t Read list of mechanisms.\n");
    printf("\n");
    printf("Options:\n");
	printf(" -r | --right \t\t Authorization right name (default %s).\n",[LOGIN_RIGHT UTF8String]);
    printf(" -s | --service \t Authorization service name (default %s).\n",[AUTH_SERVICE UTF8String]);
	printf(" -m | --mechanism \t Authorization mechanism name (default %s).\n",[AUTH_MECH UTF8String]);
	printf(" -i | --index \t\t Authorization mechanism index (default 0).\n");
	printf("\n -v \t\t Display version info. \n");
	printf("\n");
    exit(0);
}

