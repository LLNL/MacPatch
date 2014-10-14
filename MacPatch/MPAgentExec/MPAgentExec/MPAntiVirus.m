//
//  MPAntiVirus.m
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

#import "MPAntiVirus.h"
#import "MacPatch.h"

@implementation MPAntiVirus

@synthesize avType;
@synthesize avApp;
@synthesize avAppInfo;
@synthesize avDefsDate;
@synthesize l_Defaults;
@synthesize isNewerSEPSW;

-(id)init
{
    self = [super init];
	if (self) {
        fm = [NSFileManager defaultManager];
		avApp = nil;
        [self setIsNewerSEPSW:NO];
        MPDefaults *mpDefaults = [[MPDefaults alloc] init];
		[self setL_Defaults:[mpDefaults defaults]];
	}
	return self;
}


-(void)scanDefs
{
	[self avScanAndUpdate:NO];
}

-(void)scanAndUpdateDefs
{
	[self avScanAndUpdate:YES];
}

- (void)avScanAndUpdate:(BOOL)runUpdate
{
    // Look for a Supported AV App, if not bail.
	NSDictionary *_avAppInfo = [self getAvAppInfo];
	if (_avAppInfo == nil) {
		logit(lcl_vInfo,@"No AV software was found, nothing to post.");
		return;
	}

	NSMutableDictionary *_avInfoToPost = [[NSMutableDictionary alloc] initWithDictionary:_avAppInfo];

	// Check for Valid Defs data, else post data, can not update
	NSString *_localDefsDate = [self getLocalDefsDate];
	if (_localDefsDate == nil) {
		logit(lcl_vError,@"No AV Defs software was found, nothing to validate.");
		[_avInfoToPost setValue:@"NA" forKey:@"DefsDate"];
	} else {
        logit(lcl_vInfo, @"Host AV defs date is %@",_localDefsDate);
        [_avInfoToPost setValue:_localDefsDate forKey:@"DefsDate"];
    }
    // Get Latest Defs Date from Server
    NSString *_remoteAvDefsDate = [self getLatestAVDefsDate];

    if (isNewerSEPSW == YES) {
        if (_remoteAvDefsDate != nil)
        {
            logit(lcl_vInfo, @"Latest AV defs date is %@",_remoteAvDefsDate);
            NSString *justTheDateString = @"0";
            @try {
                NSRange justTheDate = NSMakeRange(0, 8);
                justTheDateString = [_localDefsDate substringWithRange:justTheDate];
            }
            @catch (NSException *exception) {
                logit(lcl_vError,@"%@",exception);
            }

            if (([_remoteAvDefsDate intValue] > [justTheDateString intValue]) && [justTheDateString intValue] != -1)
            {
                logit(lcl_vInfo,@"AV Defs are out of date.")
                if (runUpdate == YES)
                {
                    int avUpdateRes = -1;
                    avUpdateRes = [self runAVDefsUpdate];
                    if (avUpdateRes == 0) {
                        logit(lcl_vInfo,@"AV Defs were updated.");
                        // Get Defs Info and Update The Data to Post
                        _localDefsDate = [self getLocalDefsDate];
                        [_avInfoToPost setValue:_localDefsDate forKey:@"DefsDate"];
                    }
                }
            }
        }
    } else {
        if (_remoteAvDefsDate != nil)
        {
            logit(lcl_vInfo, @"Latest AV defs date is %@",_remoteAvDefsDate);
            // If Updates are enabled
            if (([_remoteAvDefsDate intValue] > [_localDefsDate intValue]) && [_localDefsDate intValue] != -1) {
                logit(lcl_vInfo,@"AV Defs are out of date.")
                if (runUpdate == YES)
                {
                    logit(lcl_vInfo,@"Run the AV Defs update, defs are out of date.")
                    // Install the Software
                    NSString *_avDefsURL = [self getAvUpdateURL];
                    logit(lcl_vDebug,@"AV Defs URL: %@",_avDefsURL);
                    if (_avDefsURL) {
                        int installResult = -1;
                        installResult = [self downloadUnzipAndInstall:_avDefsURL];
                        if (installResult != 0) {
                            logit(lcl_vError,@"AV Defs were not updated. Please see the install.log file for reason.");
                        } else {
                            logit(lcl_vInfo,@"AV Defs were updated.");
                            // Get Defs Info and Update The Data to Post
                            _localDefsDate = [self getLocalDefsDate];
                            [_avInfoToPost setValue:_localDefsDate forKey:@"DefsDate"];
                        }
                    }
                }
            } else {
                logit(lcl_vInfo, @"AV Defs are current.");
            }
        }
    }
	// Post AV to WebService
    MPWebServices *mpws = [[MPWebServices alloc] init];
    NSError *wsErr = nil;
    [mpws postClientAVData:_avInfoToPost error:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"%@",wsErr.localizedDescription);
    }

	return;
}

#pragma mark Collect Data
-(NSDictionary *)getAvAppInfo
{
    NSString *avApplication;
	NSArray *avAppArray = [NSArray arrayWithObjects:
						   @"/Applications/Symantec Solutions/Symantec AntiVirus.app",
						   @"/Applications/Symantec Solutions/Norton AntiVirus.app",
						   @"/Applications/Norton Solutions/Symantec AntiVirus.app",
						   @"/Applications/Norton Solutions/Norton AntiVirus.app", 
						   @"/Applications/Symantec Solutions/Symantec Endpoint Protection.app",
						   @"/Applications/Sophos Anti-Virus.app",
						   nil];	
	// Find the 
	for (NSString *item in avAppArray) {
		if ([fm fileExistsAtPath:item]) {
            logit(lcl_vDebug,@"Found AV app, %@.",item);
			avApplication = [NSString stringWithString:item];
			break;
		}
	}
	
	if (avApplication == nil) {
		logit(lcl_vError,@"Unable to find a AV product.");
        return nil;
	}

	NSDictionary *_avAppInfo = [NSDictionary dictionaryWithContentsOfFile:[avApplication stringByAppendingPathComponent:@"Contents/Info.plist"]];
	NSMutableDictionary *_tmpAvDict = [[NSMutableDictionary alloc] init];
	[_tmpAvDict setValue:[MPSystemInfo clientUUID] forKey:@"cuuid"];
    [_tmpAvDict setValue:[_avAppInfo valueForKey:@"CFBundleExecutable"] forKey:@"CFBundleExecutable"];
    [_tmpAvDict setValue:avApplication forKey:@"NSBundleResolvedPath"];
    [_tmpAvDict setValue:[_avAppInfo valueForKey:@"CFBundleVersion"] forKey:@"CFBundleVersion"];
    [_tmpAvDict setValue:[_avAppInfo valueForKey:@"CFBundleShortVersionString"] forKey:@"CFBundleShortVersionString"];

    [self setAvApp:avApplication];
	[self setAvAppInfo:_tmpAvDict];
	return _tmpAvDict;
}

-(NSString *)getLocalDefsDate
{
	NSString *_avDefsPath = nil;
	NSArray *avDefsArray = [NSArray arrayWithObjects:
						   @"/Library/Application Support/Symantec/AntiVirus/Engine/V.GRD",
						   @"/Library/Application Support/Norton Solutions Support/Norton AntiVirus/Engine/v.grd",
						   @"/Library/Application Support/Norton Solutions Support/Norton AntiVirus/Engine/V.GRD",
						   nil];

    NSString *avDefsAltPath = @"/Library/Application Support/Symantec/LiveUpdate/ActiveRegistry/NAV12Defs.plist";

	// Find the 
	for (NSString *item in avDefsArray) {
		if ([fm fileExistsAtPath:item]) {
			logit(lcl_vDebug,@"Reading defs file, %@",item);
			_avDefsPath = [NSString stringWithString:item];
			break;
		}
	}
	
	if (_avDefsPath == nil)
    {
        if ([fm fileExistsAtPath:avDefsAltPath]) {
			logit(lcl_vDebug,@"Reading defs file, %@",avDefsAltPath);
			NSDictionary *newAVDefsFileData = [NSDictionary dictionaryWithContentsOfFile:avDefsAltPath];
            if (newAVDefsFileData) {
                /*
                 Symantec changed the location of the AV Defs file info as of SEP 12.1.4013
                 It's now stored in a plist and easier to get, but the date still has to be
                 parsed.
                 */
                [self setIsNewerSEPSW:YES];
                if ([newAVDefsFileData objectForKey:@"ProductArray"])
                {
                    if ([[newAVDefsFileData objectForKey:@"ProductArray"] count] >= 1) {
                        if ([[[newAVDefsFileData objectForKey:@"ProductArray"] objectAtIndex:0] objectForKey:@"itemSeqData"]) {
                            NSString *itemSeqData = [[[newAVDefsFileData objectForKey:@"ProductArray"] objectAtIndex:0] objectForKey:@"itemSeqData"];
                            NSString *newDefsDate = [self parseNewDefsDateFormat:itemSeqData];
                            [self setAvDefsDate:newDefsDate];
                            return newDefsDate;
                        }
                        if ([[[newAVDefsFileData objectForKey:@"ProductArray"] objectAtIndex:0] objectForKey:@"ItemSeqData"]) {
                            NSString *itemSeqData = [[[newAVDefsFileData objectForKey:@"ProductArray"] objectAtIndex:0] objectForKey:@"ItemSeqData"];
                            NSString *newDefsDate = [self parseNewDefsDateFormat:itemSeqData];
                            [self setAvDefsDate:newDefsDate];
                            return newDefsDate;
                        }
                    }
                }

            }
		}

		logit(lcl_vError,@"Unable to find a AV Defs.");
		return nil;
	}

	// Read Defs file
	NSError *err = nil;
	NSString *_avDefsFileData = [NSString stringWithContentsOfFile:_avDefsPath encoding:NSUTF8StringEncoding error:&err];
	if (err) {
		logit(lcl_vError,@"Unable to read AV Defs file\n%@.",[err localizedDescription]);
		return nil;
	}
	logit(lcl_vDebug,@"avDefsFile Data: %@",_avDefsFileData);
	
	// Parse Defs File
	NSString *_defsDate = nil;
	NSArray *_lines = [_avDefsFileData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for (NSString *_line in _lines) {
		//LastModifiedGmtFormated
		if ([_line containsString:@"LastModifiedGmtFormated" ignoringCase:YES]) {
			logit(lcl_vDebug,@"containsString: %@",_line);
			_defsDate = [[[[_line componentsSeparatedByString:@"="] objectAtIndex:1] componentsSeparatedByString:@" "] objectAtIndex:0];
			logit(lcl_vDebug,@"_defsDate: %@",_defsDate);
			break;
		}
	}
	[self setAvDefsDate:[NSString stringWithString:_defsDate]];
	return _defsDate;
}

- (NSString *)parseNewDefsDateFormat:(NSString *)defsDate
{
    logit(lcl_vDebug,@"Raw Defs Date: %@",defsDate);
    NSString *result = @"NA";
    if (defsDate.length >= 6) {
        NSRange year = NSMakeRange(0, 2);
        NSString *strYear = [NSString stringWithFormat:@"20%@",[defsDate substringWithRange:year]];
        NSRange month = NSMakeRange(2, 2);
        NSString *strMonth = [defsDate substringWithRange:month];
        NSRange day = NSMakeRange(4, 2);
        NSString *strDay = [defsDate substringWithRange:day];
        NSString *strRev = @"0";
        @try {
            NSRange rev = NSMakeRange(6, defsDate.length-6);
            strRev = [defsDate substringWithRange:rev];
        }
        @catch (NSException *exception) {
            logit(lcl_vError,@"%@",exception);
        }
        result = [NSString stringWithFormat:@"%@%@%@ r%@",strYear,strMonth,strDay,strRev];
    }
    logit(lcl_vDebug,@"Parsed Defs Date: %@",result);
    return result;
}

#pragma mark Download & Update Methods
-(NSString *)getLatestAVDefsDate
{
	NSString *result;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    NSError *wsErr = nil;
    result = [mpws getLatestAVDefsDate:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"%@",wsErr.localizedDescription);
        return nil;
    }

    if ([result isEqualToString:@"NA"]) {
		logit(lcl_vError,@"Did not recieve a vaild defs date.");
		return nil;
	}
	return result;
}

-(NSString *)getAvUpdateURL
{
    NSString *result;
    MPWebServices *mpws = [[MPWebServices alloc] init];
    NSError *wsErr = nil;
    result = [mpws getAvUpdateURL:&wsErr];
    if (wsErr) {
        logit(lcl_vError,@"%@",wsErr.localizedDescription);
        return nil;
    }

    if ([result isEqualToString:@"NA"]) {
		logit(lcl_vError,@"Did not recieve a vaild defs file.");
		return nil;
	}
    
    logit(lcl_vDebug,@"[getAvUpdateURL] result: %@",result);
	return result;
}

-(int)downloadUnzipAndInstall:(NSString *)pkgURL
{
	// First we need to download the update
	int result = 0;
	MPAsus *mpAsus = [[MPAsus alloc] init];
	NSError *err = nil;
	NSString *dlPatchLoc = [mpAsus downloadUpdate:pkgURL error:&err];

	if (err) {
		logit(lcl_vError,@"Error downloading a patch, skipping %@. Err Message: %@",pkgURL, [err localizedDescription]);
		result = 1;
	}

	// Now we need to unzip
	if (result == 0) {
		logit(lcl_vInfo,@"Uncompressing patch, to begin install.");
		logit(lcl_vInfo,@"Begin decompression of file, %@",dlPatchLoc);
		err = nil;
		[mpAsus unzip:dlPatchLoc error:&err];
		if (err) {
			logit(lcl_vError,@"Error decompressing a patch, skipping %@. Err Message:%@",dlPatchLoc,[err localizedDescription]);
			result = 1;
		}
		logit(lcl_vInfo,@"File has been decompressed.");
	}
	// *****************************
	// Install the update
	if (result == 0) {
		NSString *pkgPath;
		NSString *pkgBaseDir = [dlPatchLoc stringByDeletingLastPathComponent];						
		NSPredicate *pkgPredicate = [NSPredicate predicateWithFormat:@"(SELF like [cd] '*.pkg') OR (SELF like [cd] '*.mpkg')"];
		NSArray *pkgList = [[fm directoryContentsAtPath:[dlPatchLoc stringByDeletingLastPathComponent]] filteredArrayUsingPredicate:pkgPredicate];
		int installResult = -1;
		MPInstaller *mpi = [[MPInstaller alloc] init];
		// Install pkg(s)
		for (id _pkg in pkgList) {
			pkgPath = [pkgBaseDir stringByAppendingPathComponent:_pkg];
			logit(lcl_vInfo,@"Start install of %@",pkgPath);
			installResult = [mpi installPkg:pkgPath target:@"/" env:nil];
			if (installResult != 0) {
				logit(lcl_vError,@"Error installing package, error code %d.",installResult);
				result = 1;
			}
		}
	}
	
	return result;
}

- (int)runAVDefsUpdate
{
    NSString *appPath = @"/Library/Application Support/Symantec/LiveUpdate/LUTool";

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: appPath];

    NSPipe *readPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [readPipe fileHandleForReading];

    [task setStandardOutput: readPipe];
    [task setStandardError: readPipe];
    [task launch];

    NSMutableData *data = [[NSMutableData alloc] init];
    NSData *readData;

    while ((readData = [readHandle availableData]) && [readData length]) {
        [data appendData: readData];
    }

    NSString *strResult = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    logit(lcl_vDebug,@"runAVDefsUpdate Output: %@",strResult);

    int taskTerminationStatus = 4;

    @try {
        taskTerminationStatus = [task terminationStatus];
    }
    @catch (NSException *exception) {
        logit(lcl_vError,@"%@",exception);
        logit(lcl_vError,@"Setting result to LU error.");
    }

    int result = -1;
    switch (taskTerminationStatus)
    {
        case 0:
            logit(lcl_vInfo,@"LU completed successfully with new update.");
            result = 0;
            break;
        case 1:
            logit(lcl_vInfo,@"LU found nothing new. It did successfully contact the LU server, but found nothing new to update.");
            result = 0;
            break;
        case 4:
            logit(lcl_vInfo,@"LU failed with error, such as network error.");
            result = 1;
            break;
        default:
            logit(lcl_vInfo,@"LU failed with error (%d).",[task terminationStatus]);
            result = 1;
            break;
    }

    return result;
}

@end
