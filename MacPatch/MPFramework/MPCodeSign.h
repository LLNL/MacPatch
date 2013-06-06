//
//  MPCodeSign.h
//  MPFramework
//
//  Created by Heizer, Charles on 6/6/13.
//
//

#import <Foundation/Foundation.h>

@interface MPCodeSign : NSObject

// CodeSign Validate
+ (BOOL)checkSignature:(NSString *)aStringPath;

@end
