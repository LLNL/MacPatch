//
//  NumberField.h
//  MPServerAdmin
//
//  Created by Heizer, Charles on 1/26/16.
//  Copyright © 2016 Charles Heizer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NumberField : NSTextField { }

-(void) textDidEndEditing:(NSNotification *)aNotification;

@end
