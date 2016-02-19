//
//  NumberField.m
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/26/16.
//  Copyright © 2016 Charles Heizer. All rights reserved.
//

#import "NumberField.h"

@implementation NumberField


-(void) textDidEndEditing:(NSNotification *)aNotification
{
    // replace content with its intValue ( or process the input's value differently )
    [self setIntValue:[self intValue]];
    
    [super textDidEndEditing:aNotification];
}

@end
