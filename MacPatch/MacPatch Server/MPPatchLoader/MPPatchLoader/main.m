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
#import "SUCatalog.h"
#import "MPJson.h"
#import "NSFileManager+DirectoryLocations.h"
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#import "MPManager.h"

#define APPVERSION			"1.1.1"
#define APPNAME				@"MPPatchLoader"

void usage(void);

int main (int argc, char * argv[])
{

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	MPManager *sm = [MPManager sharedManager]; 
	NSFileManager *fm = [NSFileManager defaultManager];
    
	NSString *confFile;
	confFile = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutablePath"] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"gov.llnl.mp.patchloader.plist"];
	if ([fm fileExistsAtPath:confFile])
    {
        [sm setG_Defaults:[NSDictionary dictionaryWithContentsOfFile:confFile]];
	} 
	NSMutableDictionary *confDictTemp = [NSMutableDictionary dictionary];
	NSDictionary *confDict;
    BOOL useConfigFile = NO;
	BOOL verboseLogging = NO;
	BOOL enableDebug = NO;
	BOOL forceRepost = NO;
	BOOL keepPatchFiles = NO;
	NSString *postFilePath = NULL;
	BOOL postUsingFile = NO;
	
	// Setup argument processing
	int c;
	while (1)
	{
		static struct option long_options[] =
		{
			{"Force"			,no_argument		,0, 'f'},
			{"ForceUsingFiles"	,no_argument		,0, 'F'},
			{"KeepFiles"		,no_argument		,0, 'k'},
			{"Config"			,required_argument	,0, 'c'},
			{"PostFile"			,required_argument	,0, 'P'},
            
            {"MPServerAddress"	,required_argument	,0, 's'},
            {"MPServerPort"		,required_argument	,0, 'p'},
            {"ASUSServer"		,required_argument	,0, 'a'},
            {"Catalog"			,required_argument	,0, 'C'},
            {"CatalogOS"		,required_argument	,0, 'o'},
            
			{"Verbose"			,no_argument		,0, 'V'},
			{"Debug"			,no_argument		,0, 'd'},
			{"version"			,no_argument		,0, 'v'},
			{"help"				,no_argument		,0, 'h'},
			{0, 0, 0, 0}
		};
		// getopt_long stores the option index here.
		int option_index = 0;
		c = getopt_long (argc, argv, "fkc:P:s:p:a:C:o:Vdvh", long_options, &option_index);
		
		// Detect the end of the options.
		if (c == -1)
			break;
		
		switch (c)
		{
			case 'f':
				forceRepost = YES;
				break;
			case 'k':
				keepPatchFiles = YES;
				break;
			case 'c':
                useConfigFile = YES;
				confFile = [NSString stringWithUTF8String:optarg];
				break;	
			case 'P':
				postFilePath = [NSString stringWithUTF8String:optarg];
				postUsingFile = YES;
				break;
            case 's':
                [confDictTemp setObject:[NSString stringWithUTF8String:optarg] forKey:@"MPServerAddress"];
				break;
            case 'p':
				[confDictTemp setObject:[NSString stringWithUTF8String:optarg] forKey:@"MPServerPort"];
				break;
            case 'a':
                [confDictTemp setObject:[NSString stringWithUTF8String:optarg] forKey:@"ASUSServer"];
				break;
            case 'C':
                [confDictTemp setObject:[NSString stringWithUTF8String:optarg] forKey:@"Catalog"];
				break;
            case 'o':
                [confDictTemp setObject:[NSString stringWithUTF8String:optarg] forKey:@"CatalogOS"];
				break;
			case 'V':
				verboseLogging = YES;
				break;
			case 'd':
				enableDebug = YES;
				break;	
			case 'v':
				printf("%s: %s\n",[APPNAME UTF8String], APPVERSION);
				return 0;
			case 'h':
			case '?':
			default:
				//printf("Silly Rabbit, Trix are for Kids!\n");
				usage();
		}
	}
	if (optind < argc) {
		while (optind < argc)
			argv[optind++];
		
		usage();
		exit(0);
	}
	
	// Set up logging
	if (enableDebug) {
		lcl_configure_by_name("*", lcl_vDebug);
		if (verboseLogging) {
			[LCLLogFile setMirrorsToStdErr:1];
		}	
		logit(lcl_vInfo,@"***** %s v.%s started -- Debug Enabled *****", [APPNAME UTF8String], APPVERSION);
	} else {
		lcl_configure_by_name("*", lcl_vInfo);
		if (verboseLogging) {
			[LCLLogFile setMirrorsToStdErr:1];
		}	
		logit(lcl_vInfo,@"***** %s v.%s started *****", [APPNAME UTF8String], APPVERSION);
	}
	
    if (useConfigFile == YES) {
        if ([fm fileExistsAtPath:confFile] == NO) {
            printf("Error, config file not found.");
            logit(lcl_vError,@"Error, config file %@ not found.", confFile);
            exit(1);
        }
        [sm setG_Defaults:[NSDictionary dictionaryWithContentsOfFile:confFile]];
        confDict = [NSDictionary dictionaryWithDictionary:[sm g_Defaults]];
    } else {
        // Validate settings
        if (![confDictTemp objectForKey:@"Catalog"] && ![confDictTemp objectForKey:@"CatalogOS"]) {
            NSDictionary *catmp = [NSDictionary dictionaryWithObjectsAndKeys:[confDict objectForKey:@"Catalog"],@"catalogurl",
                                   [confDict objectForKey:@"CatalogOS"],@"osver",nil];
            [confDictTemp setObject:[NSArray arrayWithObject:catmp] forKey:@"Catalogs"];
        } else {
            printf("Error, missing Catalog or Catalog OS.");
            exit(1);
        }
        confDict = [NSDictionary dictionaryWithDictionary:confDictTemp];
    }
    
	if (![confDict objectForKey:@"MPServerAddress"]) {
		logit(lcl_vError,@"Config file is invalid."); 
		exit(1);
	}	
	if (![confDict objectForKey:@"MPServerPort"]) {
		logit(lcl_vError,@"Config file is invalid."); 
		exit(1);
	}	
	if (![confDict objectForKey:@"ASUSServer"]) {
		logit(lcl_vError,@"Config file is invalid."); 
		exit(1);
	}	
	if (![confDict objectForKey:@"Catalogs"]) {
		logit(lcl_vError,@"Config file is invalid."); 
		exit(1);	
	} else {
		if ([[confDict objectForKey:@"Catalogs"] count] <= 0) {
			logit(lcl_vError,@"Config file is invalid."); 
			exit(1);
		}
		if ((![[[confDict objectForKey:@"Catalogs"] objectAtIndex:0] objectForKey:@"osver"]) || (![[[confDict objectForKey:@"Catalogs"] objectAtIndex:0] objectForKey:@"catalogurl"])) {
			logit(lcl_vError,@"Config file is invalid."); 
			exit(1);
		}
	}
	
	if (postUsingFile) {
		MPJson *mpJson_x = [[MPJson alloc] init];
		NSError *xErr_x = nil;
		NSArray *xData_x = nil;
		NSString *xOSRev_x = nil;
		BOOL postResult_x = NO;

			
		xErr_x = nil;
		xData_x = [NSArray arrayWithContentsOfFile:postFilePath];
		xOSRev_x = [NSString stringWithFormat:@"10.%@",[[[postFilePath lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:1]];
		// suPatches_10.5.plist
	
		postResult_x = [mpJson_x postJSONDataForMethodWithExtraKeyAndValue:@"mp_patch_loader"
																   key:@"OS" 
																 value:xOSRev_x 
																  data:xData_x 
																 error:&xErr_x];
		if (xErr_x) {
			logit(lcl_vError,@"%@ %@",[xErr_x localizedDescription], [xErr_x localizedFailureReason]);
			exit(1);
		}
		
		if (postResult_x) {
			logit(lcl_vInfo,@"Content for %@ has been posted.",xOSRev_x);
		} else {
			logit(lcl_vError,@"Content for %@ has not been posted and returned a error.",xOSRev_x);
		}
		[mpJson_x release];
		exit(0);
	}

	// Setup paths
	NSString *appSupportPath = [[NSFileManager defaultManager] applicationSupportDirectoryForDomain:NSSystemDomainMask];
	NSString *appSupportFile = [appSupportPath stringByAppendingPathComponent:@"mppatchloader.plist"];
	
	// Set up local storage
	NSMutableDictionary *appSupportFileDict;
	if ([fm fileExistsAtPath:appSupportFile]) {
		appSupportFileDict = [[NSMutableDictionary alloc] initWithContentsOfFile:appSupportFile];
	} else {
		appSupportFileDict = [[NSMutableDictionary alloc] init];
	}
	
	// Process main app
	SUCatalog *su = [[SUCatalog alloc] init];
	
	NSString *lName = NULL;
	NSMutableArray *dlPatchSets = [[NSMutableArray alloc] init];
	NSArray *catDictionaries = [[sm g_Defaults] objectForKey:@"Catalogs"];
	
	// Download ther sucatalog for each of the OS's supported
	for (id dict in catDictionaries) {
		lName = [su downloadSUContent:[[sm g_Defaults] objectForKey:@"ASUSServer"] catalog:[dict objectForKey:@"catalogurl"] osver:[dict objectForKey:@"osver"]];
		if (lName) {
			[dlPatchSets addObject:lName];
			logit(lcl_vInfo, @"Downloaded %@", lName);
		}	
	}

	[su release];
	su = nil;
	
	// Post the data which has been collected.
	MPJson *mpJson = [[MPJson alloc] init];
	NSError *xErr = nil;
	NSArray *xData = nil;
	NSString *xOSRev = nil;
	NSString *xHash = nil;
	BOOL postResult = NO;
    
    NSMutableArray *aArray = [[NSMutableArray alloc] init];
    NSMutableArray *bArray = [[NSMutableArray alloc] init];
    NSMutableSet *aSet = [[NSMutableSet alloc] init];
	
	for (id patchFile in dlPatchSets) {

		xErr = nil;
		xData = [NSArray arrayWithContentsOfFile:patchFile];
        if ([xData count] <= 0) {
            logit(lcl_vError,@"Contents of file %@ was nil.",patchFile);
            continue;
        }
        [aArray addObjectsFromArray:xData];
        //[aSet addObjectsFromArray:xData];
        /*
		xHash = nil;
		xHash = [patchFile getSHA1FromFile]; 
		
		xErr = nil;
		xData = [NSArray arrayWithContentsOfFile:patchFile];
        if ([xData count] <= 0) {
            logit(lcl_vError,@"Contents of file %@ was nil.",patchFile);
            continue;
        }
        
		xOSRev = [[xData objectAtIndex:0] objectForKey:@"osver"];
		if (([appSupportFileDict objectForKey:xOSRev]) && (forceRepost == NO)) {
			if ([[appSupportFileDict objectForKey:xOSRev] isEqualToString:xHash]) {
				logit(lcl_vInfo,@"Content hash for %@ has not changed. No need to re-post.",xOSRev);
				continue;
			} else {
				logit(lcl_vInfo,@"Content hash for %@ has changed.",xOSRev);
			}
		}
		
		postResult = [mpJson postJSONDataForMethodWithExtraKeyAndValue:@"mp_patch_loader"
																key:@"OS" 
															  value:xOSRev 
															   data:xData 
															  error:&xErr];
		if (xErr) {
			logit(lcl_vError,@"%@ %@",[xErr localizedDescription], [xErr localizedFailureReason]);
			continue;
		}
		
		if (postResult) {
			logit(lcl_vInfo,@"Content for %@ has been posted.",xOSRev);
		} else {
			logit(lcl_vError,@"Content for %@ has not been posted and returned a error.",xOSRev);
		}
		
		[appSupportFileDict setObject:xHash forKey:xOSRev];
		[appSupportFileDict writeToFile:appSupportFile atomically:YES];
		
		if (keepPatchFiles == NO) {
			xErr = nil;
			[fm removeItemAtPath:patchFile error:&xErr];
			if (xErr)
				logit(lcl_vError,@"Error trying to remove %@",patchFile);
		}
        */
	}
    NSSet *cats = [NSSet setWithArray:[aArray valueForKey: @"akey"]];
    for (NSString *_akey in cats)
    {
        for (NSDictionary *d in aArray) {
            if ([[d objectForKey:@"akey"] isEqualToString:_akey]) {
                [bArray addObject:d];
                break;
            }
        }
    }
    
    NSMutableArray *cArray = [[NSMutableArray alloc] init];
    NSSet *cats2 = [NSSet setWithArray:[bArray valueForKey:@"supatchname"]];
    for (NSString *_supatchname in cats2)
    {
        for (NSDictionary *s in bArray) {
            if ([[s objectForKey:@"supatchname"] isEqualToString:_supatchname]) {
                [cArray addObject:s];
                break;
            }
        }
    }
    
    postResult = [mpJson postJSONDataForMethodWithExtraKeyAndValue:@"mp_patch_loader"
                                                               key:@"OS"
                                                             value:@"*"
                                                              data:(NSArray *)cArray
                                                             error:&xErr];
    if (xErr) {
        logit(lcl_vError,@"%@ %@",[xErr localizedDescription], [xErr localizedFailureReason]);
        exit(1);
    }
    
    if (postResult) {
        logit(lcl_vInfo,@"Content has been posted.");
    } else {
        logit(lcl_vError,@"Content has not been posted and returned a error.");
    }
    
    //[appSupportFileDict setObject:xHash forKey:xOSRev];
    //[appSupportFileDict writeToFile:appSupportFile atomically:YES];
    /*
    if (keepPatchFiles == NO) {
        xErr = nil;
        [fm removeItemAtPath:patchFile error:&xErr];
        if (xErr)
            logit(lcl_vError,@"Error trying to remove %@",patchFile);
    }
    */
    
	
	// Release memory objects
	[mpJson release];
	[appSupportFileDict release];
	[pool drain];
    return 0;
}

void usage(void) {
    printf("MPPatchLoader: MacPatch Apple Software Update Loader.\n");
    printf("Version %s\n\n",APPVERSION);
    printf("Usage: MPPatchLoader [-f] [-V] [-v] \n\n");
    printf(" -c\t\tConfig file.\n");
    printf(" -f\t\tForce repost of data.\n");
	printf(" -k\t\tKeep patch files. (In /tmp)\n");
	printf(" -V \t\tVerbose logging.\n");
	printf(" -d \t\tenable debug logging.\n");
	printf(" -v \t\tDisplay version info. \n");
	printf("\n");
    exit(0);
}