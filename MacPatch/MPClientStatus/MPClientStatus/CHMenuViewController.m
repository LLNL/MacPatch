//
//  CHMenuViewController.m
//  TestMenu
//
//  Created by Heizer, Charles on 8/28/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import "CHMenuViewController.h"

@interface CHMenuViewController ()

@end

@implementation CHMenuViewController

@synthesize xtitle;
@synthesize xversion;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)addTitle:(NSString *)aTitle version:(NSString *)aVer
{
    xtitle = aTitle;
    xversion = aVer;
    [[self view] setNeedsDisplay:YES];
}

@end
