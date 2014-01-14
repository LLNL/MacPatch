//
//  MPInventory.m
//  MPInventoryD
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

#import "MPInventory.h"
#import "MysqlServer.h"
#import "MysqlConnection.h"
#import "MysqlFetch.h"
#import "MPDataMgr.h"

#undef  ql_component
#define ql_component lcl_cMPInventory

@interface MPInventory ()

@end

@implementation MPInventory

@synthesize files;
@synthesize filesBaseDir;
@synthesize myServer;
@synthesize keepProcessedFiles;

- (id)init
{
    self = [super init];
    if (self) {
        [self setKeepProcessedFiles:NO];
    }
    return self;
}

- (BOOL)processFiles
{
    if ([files count] > 0)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *errDir  = [[filesBaseDir stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Errors"];
        NSString *keepDir = [[filesBaseDir stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Processed"];

        // Date and time format for results
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd"];
        NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateFormat:@"HH-mm-ss"];

        NSDate *now = [[NSDate alloc] init];
        NSString *nDate = [dateFormat stringFromDate:now];
        NSString *nTime = [timeFormat stringFromDate:now];
        NSString *curProcessDateTime = [NSString stringWithFormat:@"%@_%@",nDate,nTime];

        MysqlConnection *myCon;
        myCon = [self createConnection];
        if (!myCon) {
            qlerror(@"Unable to open connection to database.");
            return NO;
        }

        NSError *myErr = nil;
        MPDataMgr *dataMgr;

        for (id afile in files)
        {
            if ([self testMySQLConnection:myCon] == NO) {
                myCon = nil;
                myCon = [self createConnection];
                if (!myCon) {
                    qlerror(@"Unable to open connection to database.");
                    return NO;
                }
            }

            myErr = nil;
            dataMgr = nil;
            dataMgr = [[MPDataMgr alloc] initWithMySQLServerConnection:myCon server:myServer];

            if ([dataMgr pasreXMLDocFromPath:[afile path]])
            {
                qldebug(@"Processed: %@",afile);
                @try {
                    if (keepProcessedFiles)
                    {
                        if (![fm fileExistsAtPath:[keepDir stringByAppendingPathComponent:curProcessDateTime]])
                        {
                            myErr = nil;
                            [fm createDirectoryAtPath:[keepDir stringByAppendingPathComponent:curProcessDateTime]
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:&myErr];
                            if (myErr) {
                                qlerror(@"%@",myErr.localizedDescription);
                            }
                        }
                        myErr = nil;
                        [fm moveItemAtPath:[afile path]
                                    toPath:[[keepDir stringByAppendingPathComponent:curProcessDateTime] stringByAppendingPathComponent:[afile lastPathComponent]]
                                     error:&myErr];
                        if (myErr) {
                            qlerror(@"%@",myErr.localizedDescription);
                            [fm removeItemAtPath:[afile path] error:NULL];
                        }
                    } else {
                        myErr = nil;
                        [fm removeItemAtPath:[afile path] error:&myErr];
                        if (myErr) {
                            qlerror(@"%@",myErr.localizedDescription);
                            [fm moveItemAtPath:[afile path]
                                        toPath:[@"/private/tmp" stringByAppendingPathComponent:[afile lastPathComponent]]
                                         error:NULL];
                        }
                    }
                }
                @catch (NSException *exception) {
                    qlerror(@"%@",exception);
                }
            } else {
                qlerror(@"Processing Error: %@",afile);
                @try {
                    if (![fm fileExistsAtPath:[errDir stringByAppendingPathComponent:curProcessDateTime]]) {
                        [fm createDirectoryAtPath:[errDir stringByAppendingPathComponent:curProcessDateTime]
                      withIntermediateDirectories:YES
                                       attributes:nil
                                            error:NULL];
                    }
                    [fm moveItemAtPath:[afile path]
                                toPath:[[errDir stringByAppendingPathComponent:curProcessDateTime] stringByAppendingPathComponent:[afile lastPathComponent]]
                                 error:NULL];
                }
                @catch (NSException *exception) {
                    qlerror(@"%@",exception);
                }
            } //dataMgr
        } // afile in files
    } // files count

    return YES;
}

- (MysqlConnection *)createConnection
{
    MysqlConnection *testConn = nil;
    @try
    {
        testConn = [MysqlConnection connectToServer:myServer];
        if (!testConn) {
            return nil;
        }
        [testConn disableTransactions];

        if ([self testMySQLConnection:testConn] == NO) {
            return nil;
        }
    }
    @catch (NSException *exception)
    {
        qlerror(@"%@",exception);
        return nil;
    }

    return testConn;
}

- (BOOL)testMySQLConnection:(MysqlConnection *)mConn
{
    NSString *sqlText = [NSString stringWithFormat:@"SELECT table_name FROM information_schema.tables WHERE table_schema = '%@'",myServer.schema];
    @try {
        MysqlFetch *fetch = [MysqlFetch fetchWithCommand:sqlText onConnection:mConn];
        if (fetch.results.count <= 0) {
            qlerror(@"No results found.");
            return NO;
        }
    }
    @catch (NSException *exception) {
        qlerror(@"%@",exception);
        return NO;
    }

    return YES;
}


@end
