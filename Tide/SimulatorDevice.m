//
//  SimulatorDevice.m
//  Tide
//
//  Created by Joe Rickerby on 04/02/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "SimulatorDevice.h"

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
    NSPipe *taskStdout = task.standardOutput = [NSPipe pipe];
    
    [task launch];
    
    return [taskStdout fileHandleForReading];
}

@end
