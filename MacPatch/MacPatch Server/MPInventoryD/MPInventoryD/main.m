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
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <unistd.h>
#import "MysqlServer.h"
#import "MysqlConnection.h"
#import "MysqlFetch.h"
#import "MPDataMgr.h"

#define APPVERSION	@"1.3.1"
#define APPNAME		@"MPInventoryD"
#define CONFFILE    @"/Library/MacPatch/Server/conf/etc/siteconfig.xml"

#undef  ql_component
#define ql_component lcl_cMain

void usage(void);

@interface ParseConf : NSObject

- (NSDictionary *)parseConfFile:(NSString *)aConfFile;

@end

@implementation ParseConf

- (NSDictionary *)parseConfFile:(NSString *)aConfFile
{
    NSError *err = nil;
    NSXMLDocument *confxXmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:aConfFile] options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) error:NULL];
    NSArray *cNodes = [confxXmlDoc nodesForXPath:@"//settings/database/prod/*" error:&err];
    
    if ([cNodes count] <= 0) {
        qlinfo(@"Nothing found ...");
        return nil;
    }
    
    NSString *dbHost = NULL;
    NSString *dbPort = NULL;
    NSString *dbUsr = NULL;
    NSString *dbPass = NULL;
    NSString *dbName = NULL;
    
    for (NSXMLNode *n in cNodes)
    {
        if ([[n name] isEqualToString:@"hoststring"]) {
            NSURL *u = [NSURL URLWithString:[[n stringValue] stringByReplacingOccurrencesOfString:@"jdbc:mysql:" withString:@"http:"]];
            dbHost = [u host];
            dbPort = [[u port] stringValue];
        } else if ([[n name] isEqualToString:@"databasename"]) {
            dbName = [n stringValue];
        } else if ([[n name] isEqualToString:@"username"]) {
            dbUsr = [n stringValue];
        } else if ([[n name] isEqualToString:@"password"]) {
            dbPass = [n stringValue];
        }
    }
    NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
    NSDictionary *conf;
    
    [tmpDict setObject:dbHost forKey:@"dbHost"];
    [tmpDict setObject:dbPort forKey:@"dbPort"];
    [tmpDict setObject:dbUsr forKey:@"dbUsr"];
    [tmpDict setObject:dbPass forKey:@"dbPass"];
    [tmpDict setObject:dbName forKey:@"dbName"];
    
    conf = [NSDictionary dictionaryWithDictionary:tmpDict];
    return conf;
}
@end

int main(int argc, char * argv[])
{

    @autoreleasepool
    {
        int reqOpts = 0;
        BOOL echoToConsole = NO;
        BOOL traceLogging = NO;
        BOOL verboseLogging = NO;
        BOOL keepProcessedFiles = NO;
        
        NSString *_configPath;
        NSString *_filesPath;
        
        // Setup argument processing
        int c;
        while (1)
        {
            static struct option long_options[] =
            {
                {"Config"			,required_argument	,0, 'c'},
                {"Files"			,required_argument	,0, 'f'},
                {"KeepFiles"        ,no_argument        ,0, 'k'},
                {"Debug"			,no_argument	    ,0, 'D'},
                {"Trace"			,no_argument	    ,0, 'T'},
                {"Echo"				,no_argument		,0, 'e'},
                {"Verbose"			,no_argument		,0, 'V'},
                {"version"			,no_argument		,0, 'v'},
                {"help"				,no_argument		,0, 'h'},
                {0, 0, 0, 0}
            };
            // getopt_long stores the option index here.
            int option_index = 0;
            c = getopt_long (argc, argv, "c:f:DTeVvh", long_options, &option_index);
            
            // Detect the end of the options.
            if (c == -1)
                break;
            
            switch (c)
            {
                case 'c':
                    _configPath = [NSString stringWithUTF8String:optarg];
                    reqOpts++;
                    break;
                case 'f':
                    _filesPath = [NSString stringWithUTF8String:optarg];
                    reqOpts++;
                    break;
                case 'k':
                    keepProcessedFiles = YES;
                    break;
                case 'D':
                    verboseLogging = YES;
                    break;	
                case 'T':
                    traceLogging = YES;
                    break;		
                case 'e':
                    echoToConsole = YES;
                    break;
                case 'V':
                    verboseLogging = YES;
                    break;
                case 'v':
                    printf("%s\n",[APPVERSION UTF8String]);
                    return 0;
                case 'h':
                    usage();
                case '?':
                    usage();
                default:
                    break;
            }
        }
        
        if (reqOpts != 2) {
            usage();
            exit(0);
        }

        if (optind < argc)
        {
            usage();
            exit(0);
        }
        
        // Make sure the user is root or is using sudo
        if (getuid()) {
            printf("You must be root to run this app. Try using sudo.\n");
#if DEBUG
            printf("Running as debug...\n");
#else		
            //exit(0);
#endif		
        }
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        // Setup Logging
        NSString *_logFile = @"/Library/MacPatch/Server/Logs/MPInventoryD.log";
        
        BOOL isDir;
        if ([fm fileExistsAtPath:[_logFile stringByDeletingLastPathComponent] isDirectory:&isDir]) {
            if (isDir == NO) {
                [fm removeItemAtPath:_logFile error:NULL];
                [fm createDirectoryAtPath:[_logFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
            }
        } else {
            [fm createDirectoryAtPath:[_logFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        
        [LCLLogFile setPath:_logFile];
        [LCLLogFile setAppendsToExistingLogFile:YES];
        lcl_configure_by_name("*", lcl_vDebug);

        if (verboseLogging) {
            lcl_configure_by_name("*", lcl_vDebug);
            [LCLLogFile setMirrorsToStdErr:YES];
            logit(lcl_vInfo,@"***** %@ v.%@ started -- Debug Enabled *****", APPNAME, APPVERSION);
        } else {
            lcl_configure_by_name("*", lcl_vInfo);
            if (echoToConsole) {
                [LCLLogFile setMirrorsToStdErr:YES];
            }
            logit(lcl_vInfo,@"***** %@ v.%@ started *****", APPNAME, APPVERSION);
        }
        
        

        // Validate Paths
        if (![fm fileExistsAtPath:_configPath]) {
            qlerror(@"%@ file not found.",_configPath);
            exit(1);
        }
        if (![fm fileExistsAtPath:_filesPath]) {
            NSError *fErr = nil;
            if (![fm createDirectoryAtPath:_filesPath withIntermediateDirectories:YES attributes:nil error:&fErr]){
                qlerror(@"Failed to create %@.",_filesPath);
                if (fErr) {
                    qlerror(@"%@",fErr.localizedDescription);
                }
            }
            qlerror(@"%@ dir not found. Exiting app.",_filesPath);
            exit(1);
        }
        
        ParseConf *pConf = [[ParseConf alloc] init];
        NSDictionary *conf = [pConf parseConfFile:_configPath];
        if (!conf) {
            qlerror(@"Could not read siteconfig.");
            exit(1);
        }
        
        // Create Server Obj
        MysqlServer *mServer = [[MysqlServer alloc] init];
        [mServer setHost:[conf objectForKey:@"dbHost"]];
        [mServer setPort:[[conf objectForKey:@"dbPort"] intValue]];
        [mServer setUser:[conf objectForKey:@"dbUsr"]];
        [mServer setPassword:[conf objectForKey:@"dbPass"]];
        [mServer setSchema:[conf objectForKey:@"dbName"]];
        qldebug(@"%@",[mServer description]);
        
        // Create Test Connection, to verify all is working
        MysqlConnection *testConn;
        @try {
            testConn = [MysqlConnection connectToServer:mServer];
            [testConn disableTransactions];
        }
        @catch (NSException *exception) {
            qlerror(@"%@",exception);
            exit(1);
        }
        
        // Test the Connection with a quick query
        NSString *sqlText = [NSString stringWithFormat:@"SELECT table_name FROM information_schema.tables WHERE table_schema = '%@'",mServer.schema];
        @try {
            MysqlFetch *fetch = [MysqlFetch fetchWithCommand:sqlText onConnection:testConn];
            if (fetch.results.count <= 0) {
                qlerror(@"No results found.");
                exit(1);
            }            
        }
        @catch (NSException *exception) {
            qlerror(@"%@",exception);
            exit(1);
        }
        
        
        NSString *errDir = [[_filesPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Errors"];
        NSString *keepDir = [[_filesPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Processed"];
        
        BOOL isRunning = YES;
        while (isRunning)
        {
            @autoreleasepool
            {
                NSError *myErr = nil;
                NSArray *extensions = [NSArray arrayWithObjects:@"txt", @"xml", @"mpi", @"mpx", @"mpj", nil];
                NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:_filesPath]
                                                                     includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsRegularFileKey]
                                                                                        options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                                          error:&myErr];
                NSArray *files = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", extensions]];
                
                if ([files count] > 0) {
                    qlinfo(@"%ld file(s) to process",[files count]);

                    // Date and time format for results
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"yyyy-MM-dd"];
                    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
                    [timeFormat setDateFormat:@"HH-mm-ss"];
                    
                    NSDate *now = [[NSDate alloc] init];
                    NSString *nDate = [dateFormat stringFromDate:now];
                    NSString *nTime = [timeFormat stringFromDate:now];
                    NSString *curProcessDateTime = [NSString stringWithFormat:@"%@_%@",nDate,nTime];
                    
                    // Parse the files
                    for (id afile in files)
                    {
                        @autoreleasepool
                        {
                            myErr = nil;
                            MPDataMgr *dataMgr = [[MPDataMgr alloc] initWithMySQLServer:mServer error:&myErr];
                            if (myErr) {
                                qlerror(@"%@",[myErr description]);
                                continue;
                            }
                            if ([dataMgr pasreXMLDocFromPath:[afile path]]) {
                                qldebug(@"Processed: %@",afile);
                                if (keepProcessedFiles)
                                {
                                    if (![fm fileExistsAtPath:[keepDir stringByAppendingPathComponent:curProcessDateTime]]) {
                                        [fm createDirectoryAtPath:[keepDir stringByAppendingPathComponent:curProcessDateTime] withIntermediateDirectories:YES attributes:nil error:NULL];
                                    }
                                    [fm moveItemAtPath:[afile path] toPath:[[keepDir stringByAppendingPathComponent:curProcessDateTime] stringByAppendingPathComponent:[afile lastPathComponent]] error:NULL];
                                } else {
                                    [fm removeItemAtPath:[afile path] error:NULL];
                                }
                            } else {
                                qlerror(@"Processing Error: %@",afile);
                                if (![fm fileExistsAtPath:[errDir stringByAppendingPathComponent:curProcessDateTime]]) {
                                    [fm createDirectoryAtPath:[errDir stringByAppendingPathComponent:curProcessDateTime] withIntermediateDirectories:YES attributes:nil error:NULL];
                                }
                                [fm moveItemAtPath:[afile path] toPath:[[errDir stringByAppendingPathComponent:curProcessDateTime] stringByAppendingPathComponent:[afile lastPathComponent]] error:NULL];
                            }
                        } // Autorelease
                    } // Files Loop
                } // File Count
            } // Autorelease
            sleep(3);
        }
    }
    return 0;
}

void usage(void) {
    printf("MPInventoryD: MacPatch inventory file processing tool.\n");
    printf("Version %s\n\n",[APPVERSION UTF8String]);
    printf("Usage: MPInventoryD [-V] [-v] \n\n");
	printf(" -c \tDatabase config file (siteconfig.xml)\n");
    printf(" -f \tDirectory containing inventory files to process.\n");
    printf(" -e \tEcho logging data to console.\n");
	printf(" -V \tVerbose logging.\n");
	printf("\n -v \tDisplay version info. \n");
	printf("\n");
    exit(0);
}

