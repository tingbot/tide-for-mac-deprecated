//
//  SimulatorDevice.m
//  Tide
//
//  Created by Joe Rickerby on 04/02/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "SimulatorDevice.h"

#import <Cocoa/Cocoa.h>

@implementation SimulatorDevice

+ (BOOL)canInstall
{
    return NO;
}

- (NSFileHandle *)run:(NSString *)path error:(NSError *__autoreleasing *)error
{
    NSTask *task = [NSTask new];
    
    task.launchPath = [[NSBundle mainBundle] pathForResource:@"tbtool" ofType:@""];
    task.arguments = @[ @"simulate", path ];

    NSPipe *taskOutput = [NSPipe pipe];
    task.standardOutput = task.standardError = taskOutput;
    
    [task launch];
    
    return [taskOutput fileHandleForReading];
}

- (NSString *)name
{
    return @"Tingbot Simulator";
}

- (NSImage *)image
{
    return [NSImage imageNamed:NSImageNameComputer];
}

- (BOOL)isEqual:(id)object
{
    if ([object class] == [SimulatorDevice class]) {
        return YES;
    }
    
    return NO;
}

@end
