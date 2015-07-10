//
//  CustomSplitView.h
//  Tide
//
//  Created by Joe Rickerby on 10/07/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CustomSplitView : NSSplitView

- (instancetype)initWithDividerColor:(NSColor *)dividerColor dividerThickness:(CGFloat)dividerThickness;

@end
