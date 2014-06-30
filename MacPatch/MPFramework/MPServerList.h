//
//  MPServerList.h
//  MPServersTest
//
//  Created by Heizer, Charles on 10/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPServerList : NSObject
{
    
@private
    NSFileManager *fm;
}

// Init
- (id)init;
- (id)initAndGetHostListFromServer;

- (NSDictionary *)readServerPlistFromHost;

// Network Methods for Getting the Data
- (BOOL)usingCurrentMPHostList:(NSError **)err;
- (BOOL)getServerListFromServer:(NSError **)err;
- (NSArray *)randomizeArray:(NSArray *)arrayToRandomize;

@end
