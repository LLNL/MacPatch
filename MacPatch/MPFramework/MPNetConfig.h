//
//  MPNetConfig.h
//  MPLibrary
//
//  Created by Heizer, Charles on 4/3/14.
//
//

#import <Foundation/Foundation.h>

@class MPNetServer;

@interface MPNetConfig : NSObject
{
    NSArray *servers;
}

@property (nonatomic, strong) NSArray *servers;

- (id)initWithServer:(MPNetServer *)netServer;

@end
