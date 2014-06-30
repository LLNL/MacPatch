//
//  MPCodeSign.m
//  MPFramework
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

#import "MPCodeSign.h"
#import "MPDefaults.h"

@implementation MPCodeSign

+ (BOOL)checkSignature:(NSString *)aStringPath
{
	BOOL result = NO;
	NSArray *_fingerPrintBaseArray = [NSArray arrayWithObjects:@"a42b1c000514941e965efa6d9c80df6572ef028f",@"d82b0abf5523dbdb6b605e570ce3a005b7a3f80d",nil];
    
    // Check to see if use code sign validation is enabled
    MPDefaults *d = [[MPDefaults alloc] init];
    if ([[d defaults] objectForKey:@"CheckSignatures"]) {
        if ([[[d defaults] objectForKey:@"CheckSignatures"] boolValue] == NO) {
            return YES;
        }
    }
	
	NSTask * task = [[NSTask alloc] init];
	NSPipe * newPipe = [NSPipe pipe];
	NSFileHandle * readHandle = [newPipe fileHandleForReading];
	NSData * inData;
	NSString * tempString;
	[task setLaunchPath:@"/usr/bin/codesign"];
	NSArray *args = [NSArray arrayWithObjects:@"-h", @"-dvvv", @"-r-", aStringPath, nil];
	[task setArguments:args];
	[task setStandardOutput:newPipe];
	[task setStandardError:newPipe];
	[task launch];
	inData = [readHandle readDataToEndOfFile];
	tempString = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
	logit(lcl_vDebug,@"Codesign result:\n%@",tempString);
    
	if ([tempString rangeOfString:@"missing or invalid"].length > 0 || [tempString rangeOfString:@"modified"].length > 0 || [tempString rangeOfString:@"CSSMERR_TP_NOT_TRUSTED"].length > 0)
	{
		logit(lcl_vError,@"%@ is not signed or trusted.",aStringPath);
		goto done;
	} else if ([tempString rangeOfString:@"Apple Root CA"].length > 0) {
		logit(lcl_vDebug,@"%@ is signed and trusted.",aStringPath);
		result = YES;
		goto done;
	}
	
	for (NSString *fingerPrint in _fingerPrintBaseArray) {
		if ([tempString rangeOfString:fingerPrint].length > 0) {
			logit(lcl_vDebug,@"%@ is signed and trusted.",aStringPath);
			result = YES;
			break;
		}
	}
	
	if (result != YES) {
		logit(lcl_vError,@"%@ is not signed or trusted.",aStringPath);
	}
done:
	return result;
}

@end
