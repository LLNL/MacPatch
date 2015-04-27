//
//  main.m
//  gov.llnl.mp.admin.helper
//
//  Created by Heizer, Charles on 1/9/15.
//  Copyright (c) 2015 Charles Heizer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HelperTool.h"

int main(int argc, char **argv)
{
    // We just create and start an instance of the main helper tool object and then
    // have it run the run loop forever.
    
    @autoreleasepool {
        HelperTool *  m;
        
        m = [[HelperTool alloc] init];
        [m run];                // This never comes back...
    }
    
    return EXIT_FAILURE;        // ... so this should never be hit.
}