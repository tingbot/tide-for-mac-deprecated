//
//  NSImage+MXUtilities.m
//  Mixim
//
//  Created by Joe Rickerby on 21/05/2015.
//  Copyright (c) 2015 Mixim Technology Ltd. All rights reserved.
//

#import "NSImage+MXUtilities.h"

@implementation NSImage (MXUtilities)

- (NSImage *)tintedImageWithColor:(NSColor *)tint
{
    NSRect imageBounds = NSMakeRect(0, 0, self.size.width, self.size.height);
    
    NSImage *result = [self copy];
    
    [result lockFocus];
    
    [tint set];
    NSRectFillUsingOperation(imageBounds, NSCompositeSourceIn);
    
    [result unlockFocus];
    
    [result setTemplate:NO];
    
    return result;
}

@end
