//
//  PandaButton.m
//  VideoCapture
//
//  Created by Wilson Lei on 9/21/13.
//  Copyright (c) 2013 wilson.lei. All rights reserved.
//

#import "PandaButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation PandaButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self pandaStyle];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self pandaStyle];
}

- (void)pandaStyle
{
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self setTitleColor:[UIColor darkGrayColor] forState:UIControlStateSelected];
    self.backgroundColor = [UIColor whiteColor];
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [UIColor blackColor].CGColor;
    self.layer.cornerRadius = 5.0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
