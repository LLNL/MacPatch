// © 2010 Mirek Rusin
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

#import "INIFile.h"

@implementation INIFile

@synthesize entries;
@synthesize contents;

- (id) init {
  if (self = [super init]) {
    self.entries = [NSMutableArray array];
  }
  return self;
}

- (id) initWithUTF8ContentsOfFile: (NSString *) path error: (NSError **) error {
  if (self = [self init]) {
    self.contents = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: error];
  }
  return self;
}

- (id) initWithContentsOfFile: (NSString *) path encoding: (NSStringEncoding) encoding error: (NSError **) error {
  if (self = [self init]) {
    self.contents = [NSString stringWithContentsOfFile: path encoding: encoding error: error];
  }
  return self;
}

- (void) setContents: (NSString *) contents_ {
  self.entries = [NSMutableArray array];
  for (NSString *line in [contents_ componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]]) {
    [self.entries addObject: [[INIEntry alloc] initWithLine: line]];
  }
}

- (NSString *) valueForKey: (NSString *) key {
  return nil;
}

- (NSMutableArray *) valuesForKey: (NSString *) key {
  return [NSMutableArray array];
}

- (NSString *) valueForKey: (NSString *) key inSection: (NSString *) section {
  return [[self valuesForKey: key inSection: section] objectAtIndex: 0];
}

- (NSMutableArray *) valuesForKey: (NSString *) key inSection: (NSString *) section {
  return [NSMutableArray array];
}

- (void) setValue: (NSString *) value forKey: (NSString *) key inSection: (NSString *) section {
}

- (NSIndexSet *) sectionIndexes {
  return [self.entries indexesOfObjectsPassingTest: ^(id entry, NSUInteger index, BOOL *stop) {
    return (BOOL)((INIEntry *)[entry entryType] == INIEntryTypeSection);
  }];
}

- (NSArray *) sections {
  return [self.entries objectsAtIndexes: [self sectionIndexes]];
}

@end
