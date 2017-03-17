//
//  AppStoreOperation.h
//  MPAgent
//
//  Created by Charles Heizer on 11/14/16.
//  Copyright © 2016 LLNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPAgent;

@interface AppStoreOperation : NSOperation
{
    BOOL isExecuting;
    BOOL isFinished;
    
@private
    
    MPAgent *si;
    NSFileManager *fm;
}

@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isFinished;

@end
