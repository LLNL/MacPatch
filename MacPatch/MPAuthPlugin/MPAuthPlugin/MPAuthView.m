//
//  MPAuthView.m
//  MPAuthPlugin
//
//  Created by Heizer, Charles on 10/29/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "MPAuthView.h"

@implementation MPAuthView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        //self.wantsLayer = YES;
        //self.layer.frame = self.frame;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Round the Corners
    //self.layer.cornerRadius = 10.0;
    //self.layer.masksToBounds = YES;

    // Draw the Gradient
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor gridColor] endingColor:[NSColor blackColor]];
    [gradient drawFromPoint: NSMakePoint(0,0)
                    toPoint: NSMakePoint(0,560)
                    options: NSGradientDrawsAfterEndingLocation
     ];
}

@end
