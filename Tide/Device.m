//
//  Device.m
//  Tide
//
//  Created by Joe Rickerby on 04/02/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "Device.h"

@implementation Device

+ (BOOL)canInstall
{
    NSAssert(false, @"subclasses must override");
    return NO;
}

- (NSFileHandle *)run:(NSString *)path error:(NSError **)error
{
    NSAssert(false, @"subclasses must override");
    return nil;
}

- (void)install:(NSString *)path
{
    NSAssert(false, @"subclasses must override");
}

- (NSString *)name
{
    NSAssert(false, @"subclasses must override");
    return nil;
}

- (NSImage *)image
{
    NSAssert(false, @"subclasses must override");
    return nil;
}

@end
