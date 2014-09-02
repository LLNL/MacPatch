//
//  CHMenuViewController.h
//  TestMenu
//
//  Created by Heizer, Charles on 8/28/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHMenuViewController : NSViewController
{
    IBOutlet NSImageView *rebootImage;
    IBOutlet NSTextField *ptitle;
    IBOutlet NSTextField *pversion;
    IBOutlet NSView *altView;
    IBOutlet NSView *titleView;
}

@property (nonatomic, strong) NSString *xtitle;
@property (nonatomic, strong) NSString *xversion;
@property (nonatomic, strong) NSImage *ximage;

@property (nonatomic, strong) IBOutlet NSView *altView;
@property (nonatomic, strong) IBOutlet NSView *titleView;

- (void)addTitle:(NSString *)aTitle version:(NSString *)aVer;


@end
