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
#import "CHDownloader.h"
#import "AVDefs.h"
#import "MPLog.h"
#import "MPSoap.h"
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>


#define APPVERSION	@"2.1"
#define APPNAME		@"mpAVDL"

void usage(void);

#pragma mark main method

int main (int argc, char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// Read PLIST
	NSDictionary *prefs;
	
	BOOL echoToConsole = NO;
	BOOL verboseLogging = NO;
	
	// Setup Base Defaults
	BOOL purgeLocalFiles = NO;
	BOOL usePlistFromArg = NO;
	NSString *plistLoc = nil;
	NSString *argDownloadURL = nil;
	NSString *argDownloadLoc = nil;
	
	// Setup argument processing
	int c;
	while (1)
	{
		static struct option long_options[] =
		{
			{"OverWrite"		,no_argument		,0, 'o'},
			{"DownloadURL"		,required_argument	,0, 'u'},
			{"DownloadLoc"		,no_argument		,0, 'd'},
			{"plist"			,required_argument	,0, 'p'},
			{"Echo"				,no_argument		,0, 'e'},
			{"Verbose"			,no_argument		,0, 'V'},
			{"version"			,no_argument		,0, 'v'},
			{"help"				,no_argument		,0, 'h'},
			{0, 0, 0, 0}
		};
		/* getopt_long stores the option index here. */
		int option_index = 0;
		c = getopt_long (argc, argv, "ou:d:p:eVvh", long_options, &option_index);
		
		/* Detect the end of the options. */
		if (c == -1)
			break;
		
		switch (c)
		{
			case 'o':
				purgeLocalFiles = YES;
				break;
			case 'u':
				argDownloadURL = [NSString stringWithUTF8String:optarg];
				break;
			case 'd':
				argDownloadLoc = [NSString stringWithUTF8String:optarg];
				break;
			case 'p':
				plistLoc = [NSString stringWithUTF8String:optarg];
				usePlistFromArg = YES;
				break;
			case 'V':
				verboseLogging = YES;
				break;
			case 'e':
				echoToConsole = YES;
				break;
			case 'v':
				printf("%s\n",[APPVERSION UTF8String]);
				return 0;
			case 'h':
			case '?':
			default:
				//printf("Silly Rabbit, Trix are for Kids!\n");
				usage();
		}
	}
	/* Print any remaining command line arguments (not options). */
	if (optind < argc) {
		//printf ("non-option ARGV-elements: ");
		while (optind < argc)
			argv[optind++];
		usage();
		exit(0);
	}
	
	
	NSString *_logFile = [NSString stringWithFormat:@"%@/Logs/MPAVDownloader.log",MP_ROOT_SERVER];
	[MPLog setupLogging:_logFile level:lcl_vDebug];
	
	if (verboseLogging) {
		lcl_configure_by_name("*", lcl_vDebug);
		[LCLLogFile setMirrorsToStdErr:YES];
		logit(lcl_vInfo,@"***** %@ v.%@ started -- Debug Enabled *****", APPNAME, APPVERSION);
	} else {
		lcl_configure_by_name("*", lcl_vInfo);
		if (echoToConsole)
			[LCLLogFile setMirrorsToStdErr:YES];
		logit(lcl_vInfo,@"***** %@ v.%@ started *****", APPNAME, APPVERSION);
	}
	
	// Read Plist Settings
	NSMutableDictionary *_prefs;
	if (usePlistFromArg) {
		_prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:plistLoc];
	} else {
		_prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:mpPlistPath];
	}
	
	if (![_prefs objectForKey:@"avDefsInfoURL"]) {
		logit(lcl_vError,@"No download url is specified. Now exiting.");
		exit(1);
	}
	if (![_prefs objectForKey:@"avDownloadURL"]) {
		logit(lcl_vError,@"No download url is specified. Now exiting.");
		exit(1);
	}
	if (![_prefs objectForKey:@"MPServerAddress"]) {
		logit(lcl_vError,@"No host server is specified. Now exiting.");
		exit(1);
	}
	if (![_prefs objectForKey:@"MPServerSSL"]) {
		logit(lcl_vError,@"MPServerSSL was not specified, defaulting to true.");
		[_prefs setObject:@"1" forKey:@"MPServerSSL"];
	}
	if (![_prefs objectForKey:@"MPServerPort"]) {
		logit(lcl_vError,@"MPServerPort was not specified, defaulting to 2600.");
		[_prefs setObject:@"2600" forKey:@"MPServerPort"];
	}
	if (![_prefs objectForKey:@"avDownloadToFilePath"]) {
		[_prefs setObject:MP_AV_DL_PATH forKey:@"avDownloadToFilePath"];
	}
	if (![_prefs objectForKey:@"avHostDLPrefixURL"]) {
		[_prefs setObject:@"" forKey:@"avHostDLPrefixURL"];
	}
	if (![_prefs objectForKey:@"avPath"]) {
		[_prefs setObject:@"/mp-content/sav" forKey:@"avPath"];
	}
	
	prefs = [NSDictionary dictionaryWithDictionary:_prefs];
	
	if (_prefs) {
		[_prefs release];
		_prefs = nil;
	}
    
	
	// AVDefs
	AVDefs *av = [[AVDefs alloc] init];
	[av setRemoteAVInfoURL:[prefs objectForKey:@"avDefsInfoURL"]];
	//[av setRemoteAVURL:[prefs objectForKey:@"avDownloadURL"]];
	[av setRemoteAVURL:[prefs objectForKey:@"avDefsInfoURL"]];
	[av setDlFilePathDir:[prefs objectForKey:@"avDownloadToFilePath"]];
	[av setDlFilePath:[NSString stringWithFormat:@"%@%@",[prefs objectForKey:@"avHostDLPrefixURL"],[prefs objectForKey:@"avPath"]]];
	[av remoteAVData];
	
	// Create the XML Data
	NSXMLDocument *xmlData = [av createAVXMLDoc:[av avDefsDictArray]];
	
	// File Download
	CHDownloader *fDownloader = [[CHDownloader alloc] init];
	
	logit(lcl_vInfo,@"Download any missing AV def packages");
	logit(lcl_vInfo,@"%@",[av avDefsDict]);
	
	// Build an array of files to download
	NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:[[av avDefsDict] objectForKey:@"ppc"]];
	[tmpArr addObjectsFromArray:[[av avDefsDict] objectForKey:@"x86"]];
	
	// Create html contents dir
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:[prefs objectForKey:@"avDownloadToFilePath"]] == NO)
	{
		NSError *fhErr = nil;
		[fileManager createDirectoryAtPath:[prefs objectForKey:@"avDownloadToFilePath"] withIntermediateDirectories:YES attributes:nil error:&fhErr];
		
		if (fhErr) {
			logit(lcl_vError,@"Error creating download directory (%@): %@ %@",[prefs objectForKey:@"avDownloadToFilePath"] , [fhErr localizedDescription], [[fhErr userInfo] objectForKey:NSErrorFailingURLStringKey]);
			logit(lcl_vError,@"Now exiting.");
			exit(0);
		}
	}
	
	
	NSEnumerator *enumerator = [tmpArr objectEnumerator];
	id anObject;
	// Loop Through tmpArr
	while (anObject = [enumerator nextObject]) {
		NSString *theLoFile = [[prefs objectForKey:@"avDownloadToFilePath"] stringByAppendingPathComponent:anObject];
		NSString *theDLFile = anObject; //[[av remoteAVURL] stringByAppendingPathComponent:anObject];
		if ([[NSFileManager defaultManager] fileExistsAtPath:theLoFile] == NO || purgeLocalFiles == YES) {
			[fDownloader setFileURL:[[prefs objectForKey:@"avDownloadURL"] stringByAppendingPathComponent:theDLFile]];
			[fDownloader setFilePath:[prefs objectForKey:@"avDownloadToFilePath"]];
			[fDownloader startDownloadingURL];
			
			while ([fDownloader isDownloading] == YES) {
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
			}
		} else {
			logit(lcl_vInfo,@"File (%@) already exists, skipping.",theLoFile);
		}
	}
	[fDownloader release];
	
	// Write out the XML Data
	logit(lcl_vInfo,@"Writing savdefs.xml file");
	NSError *err = NULL;
	[[xmlData XMLStringWithOptions:NSXMLNodePrettyPrint] writeToFile:[[prefs objectForKey:@"avDownloadToFilePath"] stringByAppendingPathComponent:@"savdefs.xml"]
														  atomically:YES
															encoding:NSUTF8StringEncoding
															   error:&err];
	if(err) {
        logit(lcl_vError,@"Error creating XML file: %@ %@", [err localizedDescription], [[err userInfo] objectForKey:NSErrorFailingURLStringKey]);
	}
	
	// Send Results to WebService
	NSData * data = [NSData dataWithContentsOfFile:[[prefs objectForKey:@"avDownloadToFilePath"] stringByAppendingPathComponent:@"savdefs.xml"]];
    NSString * base64 = [data encodeBase64WithNewlines: YES];
	NSString *_httpType = @"http";
	if ([[prefs objectForKey:@"MPServerSSL"] isEqualTo:@"1"]) {
		_httpType = [NSString stringWithString:@"https"];
	}
    
    NSURL *_wsURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@/MPWSControllerCocoa.cfc",_httpType,[prefs objectForKey:@"MPServerAddress"],[prefs objectForKey:@"MPServerPort"]]];
	logit(lcl_vInfo,@"_wsURL: %@",_wsURL);
	MPSoap *mps = [[MPSoap alloc] initWithURL:_wsURL nameSpace:@"http://MPWSController.cfc"];
	
	NSString *message = [mps createSOAPMessage:@"AddSavAvDefs" argName:@"theXmlFile" argType:@"string" argValue:base64];
	logit(lcl_vInfo,@"WS message: %@",message);
	logit(lcl_vInfo,@"Posting data to web service.");
	NSData *result = [mps invoke:message isBase64:NO error:NULL];
	[mps release];
	mps = nil;
	
	NSString *aStr = [[[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding] autorelease];
	logit(lcl_vInfo,@"WebService Response: %@",aStr);
	
	[pool release];
    return 0;
    
}

void usage(void) {
    printf("mpAVDL: The MacPatch Symantec AV definitions package downloader.\n");
    printf("Version %s\n\n",[APPVERSION UTF8String]);
    printf("Usage: mpAVDL [-o] [-u url] [-d path] [-v] \n\n");
    printf(" -o\t\tOverwrite any downloaded files\n");
    printf(" -u url\t\tSymantec AV Download URL location\n");
    printf(" -d path\tDownload location\n");
	printf(" -p path\tConfig Plist location\n");
	printf("\n -v \t\tDisplay version info. \n");
	printf("\n");
    exit(0);
}

