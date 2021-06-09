//
//  NSDictionary+Helper
/*
 Copyright (c) 2021, Lawrence Livermore National Security, LLC.
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
//
//	URLEncodedString
//	From : http://blog.ablepear.com/2008/12/urlencoding-category-for-nsdictionary.html

#import "NSDictionary+Helper.h"

// helper function: get the string form of any object
static NSString *toString(id object) 
{
	return [NSString stringWithFormat: @"%@", object];
}

// helper function: get the url encoded string form of any object
static NSString *urlEncode(id object) 
{
	NSString *string = toString(object);
	return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

@implementation NSDictionary (NSDictionaryHelper)

- (BOOL)hasKey:(id)aKey
{
	if ([[self allKeys] containsObject:aKey]) {
		return TRUE;
	} else {
		return FALSE;
	}
}

- (NSString *)urlEncodedString 
{
	NSMutableArray *parts = [NSMutableArray array];
	for (id key in self) {
		id value = [self objectForKey: key];
		NSString *part = [NSString stringWithFormat: @"%@=%@", urlEncode(key), urlEncode(value)];
		[parts addObject: part];
	}
	return [parts componentsJoinedByString: @"&"];
}

- (NSString *)asJSON
{
	NSError *error = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
													   options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
														 error:&error];
	
	if (!jsonData) {
		NSLog(@"Got an error: %@", error);
	} else {
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		return jsonString;
	}
	
	return nil;
}

@end
