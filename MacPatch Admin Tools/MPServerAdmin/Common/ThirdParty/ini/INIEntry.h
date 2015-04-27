// © 2010 Mirek Rusin
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

#import <Foundation/Foundation.h>

typedef enum {
  INIEntryTypeSection,
  INIEntryTypeKeyValue,
  INIEntryTypeComment,
  INIEntryTypeOther
} INIEntryType;

typedef struct {
  NSRange key;
  NSRange value;
  NSRange section;
} INIEntryInfo;

@interface INIEntry : NSObject {
  NSString *line;
  INIEntryInfo info;
  INIEntryType type;
}

@property (nonatomic, retain) NSString *line;
@property (assign) INIEntryInfo info;
@property (assign) INIEntryType type;

- (id) init;
- (id) initWithLine: (NSString *) line;

+ (INIEntry *) entryWithLine: (NSString *) line;

- (NSString *) key;
- (void) setKey: (NSString *) key;

- (NSString *) value;
- (void) setValue: (NSString *) value;

- (NSString *) section;

- (void) parse;

@end
