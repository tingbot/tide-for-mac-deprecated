//
//  CustomSplitView.m
//  Tide
//
//  Created by Joe Rickerby on 10/07/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "CustomSplitView.h"

@implementation CustomSplitView
{
    NSColor *_dividerColor;
    CGFloat _dividerThickness;
}

- (instancetype)initWithDividerColor:(NSColor *)dividerColor dividerThickness:(CGFloat)dividerThickness
{
    _dividerColor = dividerColor;
    _dividerThickness = dividerThickness;
    
    return [super init];
}

- (NSColor *)dividerColor
{
    return _dividerColor;
}

- (CGFloat)dividerThickness
{
    return _dividerThickness;
}

@end
