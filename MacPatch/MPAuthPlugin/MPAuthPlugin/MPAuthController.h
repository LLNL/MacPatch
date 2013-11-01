//
//  MPAuthController.h
//  MPAuthPlugin
//
//  Created by Heizer, Charles on 10/29/13.
//  Copyright (c) 2013 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MPAuthController : NSWindowController
{
    IBOutlet NSWindow		*mpAuthWindow;
	void					*mMechanismRef;
	BOOL					mModal;
}

- (void)setRef:(void *)ref;
- (void)dismissWindow;

- (IBAction)closeWindow:(id)sender;

@end
