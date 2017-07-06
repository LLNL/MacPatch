//
//  MPAuthViewMin.m
//  MPLoginAgent
//
//  Created by Charles Heizer on 6/30/17.
//  Copyright © 2017 Charles Heizer. All rights reserved.
//

#import "MPAuthViewMin.h"

@implementation MPAuthViewMin

- (BOOL) canBecomeKeyWindow { return YES; }
- (BOOL) canBecomeMainWindow { return YES; }
- (BOOL) acceptsFirstResponder { return YES; }
- (BOOL) becomeFirstResponder { return YES; }
- (BOOL) resignFirstResponder { return YES; }

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        // self.wantsLayer = YES;
        // self.layer.frame = self.frame;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    //NSColor *backgroundColor = [NSColor colorWithRed:204 green:204 blue:204 alpha:1.0]; // Light Silver
    [[NSColor windowBackgroundColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

@end
