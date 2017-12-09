//
//  LocalAdminAccounts.m
//  MPAgent
//
//  Created by Charles Heizer on 12/7/17.
//  Copyright © 2017 LLNL. All rights reserved.
//

#import "LocalAdminAccounts.h"
#import "MPUsersAndGroups.h"

@implementation LocalAdminAccounts


- (NSArray *)gatherLocalAdminAccounts
{
	NSMutableArray *accounts = [NSMutableArray array];
	MPUsersAndGroups *m = [[MPUsersAndGroups alloc] init];
	NSArray *localGroups = [m getLocalGroups:NULL];
	
	// Admin Group is #80, no need to process after 80 is found
	NSDictionary *result;
	for (NSDictionary *d in localGroups) {
		if ([[d objectForKey:@"GroupID"] integerValue] == 80) {
			result = d;
			break;
		}
	}
	
	NSDictionary *account;
	NSArray *_idList = [[result objectForKey:@"GroupMembers"] componentsSeparatedByString:@","];
	for (NSString *gid in _idList)
	{
		account = [m getInfoForUserGUID:gid];
		if (account != nil) {
			[accounts addObject:account];
		}
	}
	
	return (NSArray *)accounts;
}

@end
