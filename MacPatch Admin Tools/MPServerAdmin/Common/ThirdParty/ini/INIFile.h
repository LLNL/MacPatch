// © 2010 Mirek Rusin
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

#import <Foundation/Foundation.h>
#import "INIEntry.h"

// Ini file support
//
// Read and write access to ini-style files with simple interface preserving file formatting.
//
// Author: Mirek Rusin <mirek [at] me [dot] com>
// Copyright: 2010 Mirek Rusin
// License: Apache 2.0 License
//
@interface INIFile : NSObject {
  NSMutableArray *entries;
}

@property (nonatomic, retain) NSMutableArray *entries;
@property (assign, readwrite) NSString *contents;

- (id) initWithUTF8ContentsOfFile: (NSString *) path error: (NSError **) error;
- (id) initWithContentsOfFile: (NSString *) path encoding: (NSStringEncoding) encoding error: (NSError **) error;


- (NSIndexSet *) sectionIndexes;
- (NSArray *) sections;

- (NSString *) valueForKey: (NSString *) key;
- (NSMutableArray *) valuesForKey: (NSString *) key;

- (NSString *) valueForKey: (NSString *) key inSection: (NSString *) section;
- (NSMutableArray *) valuesForKey: (NSString *) key inSection: (NSString *) section;

@end
