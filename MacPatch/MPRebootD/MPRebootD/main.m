//
//  main.m
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
#import "MacPatch.h"
#import "MPRebootController.h"
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

#define APPVERSION "2.1.4"

void usage(void);

int main (int argc, char * argv[]) {
    @autoreleasepool {
    
        BOOL verboseLogging = NO;
	BOOL echoToConsole = NO;
	
	// Setup argument processing
	int c;
	while (1)
	{
		static struct option long_options[] =
		{
			{"Echo"				,no_argument		,0, 'e'},
			{"Verbose"			,no_argument		,0, 'V'},
			{"version"			,no_argument		,0, 'v'},
			{"help"				,no_argument		,0, 'h'},
			{0, 0, 0, 0}
		};
		// getopt_long stores the option index here.
		int option_index = 0;
		c = getopt_long (argc, argv, "eVvh", long_options, &option_index);
		
		// Detect the end of the options.
		if (c == -1)
			break;
		
		switch (c)
		{
			case 'V':
				verboseLogging = YES;
				break;
			case 'v':
				printf("%s\n",APPVERSION);
				return 0;
			case 'h':
			case '?':
			default:
				printf("Silly Rabbit, Trix are for Kids!\n");
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
	NSString *homePath = [@"~/Library/Logs/MPRebootD.log" stringByExpandingTildeInPath];
	[MPLog setupLogging:homePath level:lcl_vDebug];
	
	if (verboseLogging) {
		// enable logging for all components up to level Debug
		lcl_configure_by_name("*", lcl_vDebug);
		[LCLLogFile setMirrorsToStdErr:1];
		logit(lcl_vInfo,@"***** MPRebootD v%s started -- Debug Enabled *****",APPVERSION);
	} else {
		// enable logging for all components up to level Info
		lcl_configure_by_name("*", lcl_vInfo);
		if (echoToConsole) {
			[LCLLogFile setMirrorsToStdErr:1];
            }
		logit(lcl_vInfo,@"***** MPRebootD v%s started *****",APPVERSION);
	}
	
	MPRebootController *ac = [[MPRebootController alloc] init];
        logit(lcl_vDebug,@"Watching files in %@",[ac watchFiles]);
        [[NSRunLoop currentRunLoop] run];
	
    }
    return 0;
}

void usage(void)
{
    printf("MPRebootD: MacPatch Reboot Launch tool.\n");
    printf("Version %s\n\n",APPVERSION);
    printf("Usage: MPInventory [-V] [-v] [-h] \n\n");
	printf(" -V \t\tVerbose logging.\n");
	printf("\n -v \t\tDisplay version info. \n");
	printf("\n");
    exit(0);
}

