//
//  MPTaskValidate.m
/*
 Copyright (c) 2017, Lawrence Livermore National Security, LLC.
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

#import "MPTaskValidate.h"

NSString * const kMPCheckIn			= @"Every@900";
NSString * const kMPAgentCheck		= @"Every@3600";
NSString * const kMPVulScan			= @"Recurring@Daily@12:00:00";
NSString * const kMPVulUpdate		= @"Recurring@Daily@12:10:00";
NSString * const kMPAVCheck			= @"EVERYRAND@14400";
NSString * const kMPAVInfo			= @"EVERYRAND@1800";
NSString * const kMPInvScan			= @"EVERY@21600";
NSString * const kMPSWDistMan       = @"EVERY@14400";
NSString * const kMPCMD             = @"EVERY@21600";
NSString * const kMPProfiles        = @"EVERY@1800";
NSString * const kMPSrvList         = @"EVERY@600";
NSString * const kMPSUSrvList       = @"EVERY@1800";
NSString * const kMPAppStore        = @"EVERY@7200";
NSString * const kStartDate			= @"2011-01-01";
NSString * const kEndDate			= @"3000-01-01";
NSString * const kMPPatchCrit		= @"EVERY@1800";

#define MP_TASKS_PLIST_DEFAULT		@"/Library/MacPatch/Client/.tasks/gov.llnl.mp.tasks.plist.default"
#define DEFAULT_TASKS_DATA @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \
<plist version=\"1.0\"> \
<dict> \
<key>mpTasks</key> \
<array> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPCheckIn</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Client Checkin Task</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>1</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>Every@900</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Client Checkin</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2011-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPAgentCheck</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Update Agent Task</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>2</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>Every@3600</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Update Agent </string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2011-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPVulScan</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Client Vulnerability Scan Task</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>3</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>Recurring@Daily@12:00:00</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Client Vulnerability Scan</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2011-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPVulUpdate</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Client Vulnerability Update Task</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>4</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>Recurring@Daily@12:30:00</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Client Vulnerability Update</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2011-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPAVCheck</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Client Antivirus Scan &amp; Update Task</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>5</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>EVERYRAND@14400</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Client Antivirus Scan &amp; Update</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2011-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPAVInfo</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Client Antivirus Info Scan Task</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>8</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>EVERYRAND@1800</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Client Antivirus Info Scan</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2011-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPInvScan</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Client Inventory Scan Task</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>6</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>EVERY@21600</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Client Inventory Scan</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2011-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPSWDistMan</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Check for Mandatory Software</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>7</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>EVERY@14400</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Mandatory Software Install</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2012-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPSrvList</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>Server List scan and update</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>9</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>EVERY@600</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>Server List scan and update</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2012-01-01</string> \
</dict> \
<dict> \
<key>active</key> \
<string>1</string> \
<key>cmd</key> \
<string>kMPSUSrvList</string> \
<key>cmdalt</key> \
<string>0</string> \
<key>description</key> \
<string>SU Server List scan and update</string> \
<key>enddate</key> \
<string>3000-01-01</string> \
<key>id</key> \
<string>12</string> \
<key>idrev</key> \
<string>1</string> \
<key>idsig</key> \
<string>0</string> \
<key>interval</key> \
<string>EVERY@1800</string> \
<key>mode</key> \
<string>0</string> \
<key>name</key> \
<string>SU Server List scan and update</string> \
<key>parent</key> \
<string>0</string> \
<key>scope</key> \
<string>Global</string> \
<key>startdate</key> \
<string>2012-01-01</string> \
</dict> \
</array> \
</dict> \
</plist> \
"

#pragma mark -
#pragma mark NSString Category

@interface NSString (String_Task_Helper)

-(BOOL)isValidTimeString;
-(BOOL)isValidTimeStringUsingFormatter:(NSString *)aFormat;
-(BOOL)isValidNumberString;

@end

@implementation NSString (String_Task_Helper)

-(BOOL)isValidTimeString
{
	return [self isValidTimeStringUsingFormatter:@"HH:mm:ss"];
}

-(BOOL)isValidTimeStringUsingFormatter:(NSString *)aFormat
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:aFormat];
	
	NSDate *_date = [dateFormatter dateFromString:self];
	if (_date != NULL) {
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)isValidNumberString
{
	BOOL valid;	
	NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
	NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:self];
	
	valid = [alphaNums isSupersetOfSet:inStringSet];
	
	return valid;
}
@end

#pragma mark -
#pragma mark MPTaskValidate

@implementation MPTaskValidate

@synthesize defaultTasks;

-(id)init
{
    if (self = [super init])
    {
        [self readDefaultTasks];
    }
    return self;
}

- (int)validateTask:(NSDictionary *)aTask
{
	//	Return Codes
	//	0 = Valid	
	//	1 = Error, replace with default cmd
	//	2 = Invalid Interval, we will reset startdate and endate as well
	//	3 = End Date has to be updated, due to bug in 10.8 NSDate. NSDate cant be older than 3512-12-31
	//	99 = Not a valid command type, should disable it.
	
	NSArray *intervalArray = [[aTask objectForKey:@"interval"] componentsSeparatedByString:@"@"];
	// If there are not enough args for the Interval
	if ([intervalArray count] <= 1) {
		logit(lcl_vError,@"Major error found in tasks file. Replacing current tasks file with default config.");
		return 1;
	}
    NSArray *approvedTasks = [NSArray arrayWithObjects:@"KMPCHECKIN",@"KMPAGENTCHECK",@"KMPVULSCAN",@"KMPVULUPDATE",@"KMPAVCHECK",@"KMPINVSCAN",
                              @"KMPCMD",@"KMPSWDISTMAN",@"KMPAVINFO",@"KMPSRVLIST",@"KMPPROFILES",@"KMPWSPOST",@"KMPSUSRVLIST",
                              @"KMPAPPSTORE", nil];
	
	if (![[aTask allKeys] containsObject:@"startdate"]) return 1;
	if (![[aTask allKeys] containsObject:@"enddate"]) return 1;
	if ([[aTask allKeys] containsObject:@"cmd"]) {
        int found = 0;
        NSString *_cmd = [NSString stringWithString:[aTask objectForKey:@"cmd"]];
        for (NSString *_taskName in approvedTasks) {
            if ([[_cmd uppercaseString] isEqualToString:_taskName]) {
                found++;
                break;
            }
        }
        if (found == 0) {
            // No Task Found
            return 99;
        }
	} else {
		return 1;
	}
	
	if ([self validateInterval:intervalArray] == NO) {
		return 2;
	}	
	
	if ([self validateEndDate:[aTask objectForKey:@"enddate"]] == NO) {
		return 3;
	}	
	
	return 0;
}

- (BOOL)validateInterval:(NSArray *)aInterval
{
	
	/*	Valid Formats:
	 Once@Time; Recurring@Daily,Weekly,Monthly@Time; Every@seconds; EveryRand@seconds 
	 */
	
	if ([aInterval count] <= 1) return NO;
	if ([aInterval count] > 3) return NO;
	
	if ([[[aInterval objectAtIndex:0] uppercaseString] isEqual:@"RECURRING"] || [[[aInterval objectAtIndex:0] uppercaseString] isEqual:@"ONCE"]
		|| [[[aInterval objectAtIndex:0] uppercaseString] isEqual:@"EVERY"] || [[[aInterval objectAtIndex:0] uppercaseString] isEqual:@"EVERYRAND"]) {
	} else {
		return NO;
	}
	
	if ([aInterval count] == 2) {
		if ([aInterval objectAtIndex:0] == NULL || [aInterval objectAtIndex:1] == NULL) {
			return NO;	
		}
		if ([[[aInterval objectAtIndex:0] uppercaseString] isEqual:@"ONCE"]) {
			return [[aInterval objectAtIndex:1] isValidTimeString];	
		}
		if ([[[aInterval objectAtIndex:0] uppercaseString] isEqual:@"EVERY"]) {
			return [[aInterval objectAtIndex:1] isValidNumberString];	
		}
		if ([[[aInterval objectAtIndex:0] uppercaseString] isEqual:@"EVERYRAND"]) {
			return [[aInterval objectAtIndex:1] isValidNumberString];
		}
	}
	
	if ([aInterval count] == 3) {
		if ([aInterval objectAtIndex:0] == NULL || [aInterval objectAtIndex:1] == NULL || [aInterval objectAtIndex:2] == NULL) {
			return NO;	
		}
		NSString *_mod = [[aInterval objectAtIndex:1] uppercaseString];
		if ([_mod isEqualToString:@"DAILY"] || [_mod isEqualToString:@"WEEKLY"] || [_mod isEqualToString:@"MONTHLY"]) {
			return [[aInterval objectAtIndex:2] isValidTimeString];
		} else {
			return NO;
		}
	}
	
	return NO;
}

- (BOOL)validateStateDate:(NSString *)aStringDate
{
	return YES;
}

- (BOOL)validateEndDate:(NSString *)aStringDate
{
	NSRange range = NSMakeRange (0, 4); // Get First 4 Chars
	NSString *_year = [aStringDate substringWithRange:range];
	if ([_year intValue] <= 3000) {
		return YES;
	} else {
		return NO;
	}
}

- (void)readDefaultTasks
{
	NSString *error;
	NSPropertyListFormat format;
	NSData *dataDefault = [NSData dataWithData:[DEFAULT_TASKS_DATA dataUsingEncoding:NSUTF8StringEncoding]];
	NSMutableDictionary *theDefaultPlist = [NSPropertyListSerialization propertyListFromData:dataDefault 
																			mutabilityOption:NSPropertyListImmutable 
																					  format:&format 
																			errorDescription:&error];
	if (!theDefaultPlist) {
		logit(lcl_vError,@"Error, unable to read defaults. %@",error);	
	}
	
	[self setDefaultTasks:[NSDictionary dictionaryWithDictionary:theDefaultPlist]];
}

- (NSDictionary *)resetTaskFromDefaults:(NSString *)aCMDName
{
	NSArray *x = [NSArray arrayWithArray:[defaultTasks objectForKey:@"mpTasks"]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"cmd contains[cd] %@",aCMDName];
	NSArray *filtered = [x filteredArrayUsingPredicate:p];
	
	if ([filtered count] == 1) {
		return [filtered objectAtIndex:0];
	} else {
		return nil;
	}
}

- (NSDictionary *)updateTaskIntervalForCommand:(NSDictionary *)aTask cmd:(NSString *)aCMDName
{
	NSDictionary *_res;
	NSMutableDictionary *_tmp = [NSMutableDictionary dictionaryWithDictionary:aTask];
	if ([aCMDName isEqualToString:@"kMPCheckIn"]) {
		[_tmp setObject:kMPCheckIn forKey:@"interval"];
	} else if ([aCMDName isEqualToString:@"kMPAgentCheck"]) {
		[_tmp setObject:kMPAgentCheck forKey:@"interval"];
	} else if ([aCMDName isEqualToString:@"kMPVulScan"]) {
		[_tmp setObject:kMPVulScan forKey:@"interval"];
	} else if ([aCMDName isEqualToString:@"kMPVulUpdate"]) {
		[_tmp setObject:kMPVulUpdate forKey:@"interval"];
	} else if ([aCMDName isEqualToString:@"kMPAVCheck"]) {
		[_tmp setObject:kMPAVCheck forKey:@"interval"];
    } else if ([aCMDName isEqualToString:@"kMPAVInfo"]) {
		[_tmp setObject:kMPAVInfo forKey:@"interval"];
	} else if ([aCMDName isEqualToString:@"kMPInvScan"]) {
		[_tmp setObject:kMPInvScan forKey:@"interval"];
    } else if ([aCMDName isEqualToString:@"kMPSWDistMan"]) {
        [_tmp setObject:kMPSWDistMan forKey:@"interval"];
    } else if ([aCMDName isEqualToString:@"kMPCMD"]) {
        [_tmp setObject:kMPCMD forKey:@"interval"];
    } else if ([aCMDName isEqualToString:@"kMPProfiles"]) {
        [_tmp setObject:kMPProfiles forKey:@"interval"];
    } else if ([aCMDName isEqualToString:@"kMPSrvList"]) {
        [_tmp setObject:kMPSrvList forKey:@"interval"];
    } else if ([aCMDName isEqualToString:@"kMPSUSrvList"]) {
        [_tmp setObject:kMPSUSrvList forKey:@"interval"];
    } else if ([aCMDName isEqualToString:@"kMPAppStore"]) {
        [_tmp setObject:kMPAppStore forKey:@"interval"];
    } else if ([aCMDName isEqualToString:@"kMPPatchCrit"]) {
        [_tmp setObject:kMPPatchCrit forKey:@"interval"];
    }
	
	[_tmp setObject:kStartDate forKey:@"startdate"];	
	[_tmp setObject:kEndDate forKey:@"enddate"];	
	_res = [NSDictionary dictionaryWithDictionary:_tmp];
	return _res;
}

- (NSDictionary *)updateEndDateForTask:(NSDictionary *)aTask
{
	NSDictionary *_res;
	NSMutableDictionary *_tmp = [NSMutableDictionary dictionaryWithDictionary:aTask];
	
	NSRange range = NSMakeRange (4, [[aTask objectForKey:@"enddate"] length] - 4);
	NSString *_date = [[aTask objectForKey:@"enddate"] substringWithRange:range];
	[_tmp setObject:[NSString stringWithFormat:@"3000%@",_date] forKey:@"enddate"];	
	_res = [NSDictionary dictionaryWithDictionary:_tmp];
	return _res;
}

- (NSDictionary *)disableTask:(NSDictionary *)aTask
{
	NSDictionary *_res;
	NSMutableDictionary *_tmp = [NSMutableDictionary dictionaryWithDictionary:aTask];
	[_tmp setObject:@"0" forKey:@"active"];
	_res = [NSDictionary dictionaryWithDictionary:_tmp];
	return _res;
}


@end
