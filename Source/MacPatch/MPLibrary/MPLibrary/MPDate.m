//
//  MPDate.m
/*
 Copyright (c) 2024, Lawrence Livermore National Security, LLC.
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

#import "MPDate.h"

#undef  ql_component
#define ql_component lcl_cMPDate

@implementation MPDate

+ (NSString *)dateTimeStamp
{
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *dateString = [dateFormatter stringFromDate:date];
	return dateString;
}

+ (BOOL)dateLessThan:(NSDate *)aDate Date:(NSDate *)bDate {
	BOOL result = false;
	if ((int)[aDate timeIntervalSince1970] < (int)[bDate timeIntervalSince1970]) result = true;
	return result;
}

+ (BOOL)dateEqualTo:(NSDate *)aDate Date:(NSDate *)bDate {
	BOOL result = false;
	if ((int)[aDate timeIntervalSince1970] == (int)[bDate timeIntervalSince1970]) result = true;
	return result;
}

+ (BOOL)dateGreaterThan:(NSDate *)aDate Date:(NSDate *)bDate {
	BOOL result = false;
	if ((int)[aDate timeIntervalSince1970] > (int)[bDate timeIntervalSince1970]) result = true;
	return result;
}

+ (BOOL)currentDateBetween:(NSDate *)aDate Date:(NSDate *)bDate {
	BOOL result = false;
	NSDate *now = [[NSDate alloc] init];
	if ([self dateGreaterThan:aDate Date:now] && [self dateLessThan:bDate Date:now]) result = true;
	now = nil;
	return result;
}


@end
