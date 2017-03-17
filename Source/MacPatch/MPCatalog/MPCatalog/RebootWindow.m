//
//  RebootWindow.m
//  MPCatalog
//
//  Created by Heizer, Charles on 1/27/16.
//  Copyright © 2016 LLNL. All rights reserved.
//

#import "RebootWindow.h"

@interface RebootWindow ()

@end

@implementation RebootWindow

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)didTapCancelButton:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)didTapRebootButton:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

@end
