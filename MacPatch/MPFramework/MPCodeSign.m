//
//  MPCodeSign.m
//  MPFramework
//
//  Created by Heizer, Charles on 6/6/13.
//
//

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
	tempString = [[[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding] autorelease];
	logit(lcl_vDebug,@"Codesign result:\n%@",tempString);
	[task release];
    
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
