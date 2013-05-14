//
//  NSData+Base64.h
//  MPPatchLoader
//
//  Created by Heizer, Charles on 10/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


void *NewBase64Decode(
					  const char *inputBuffer,
					  size_t length,
					  size_t *outputLength);

char *NewBase64Encode(
					  const void *inputBuffer,
					  size_t length,
					  bool separateLines,
					  size_t *outputLength);

@interface NSData (Base64)

+ (NSData *)dataFromBase64String:(NSString *)aString;
- (NSString *)base64EncodedString;

@end

@interface NSData (Hex)
+ (NSData *) dataFromHexidecimal: (NSString *)hexString;
- (NSString *) hexString;
@end
