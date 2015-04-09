//
//  NetworkDevice.m
//  Tide
//
//  Created by Joe Rickerby on 22/03/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "NetworkDevice.h"

@implementation NetworkDevice

- (instancetype)initWithHostname:(NSString *)hostname
{
    self = [super init];
    
    if (self) {
        _hostname = hostname;
    }
    
    return self;
}

+ (BOOL)canInstall
{
    return YES;
}

- (NSFileHandle *)run:(NSString *)path error:(NSError **)error
{
    NSTask *task = [NSTask new];
    
    task.launchPath = [[NSBundle mainBundle] pathForResource:@"tbtool" ofType:@""];
    task.arguments = @[ @"run", path, _hostname ];
    NSPipe *taskStdout = task.standardOutput = [NSPipe pipe];
    
    [task launch];
    
    return [taskStdout fileHandleForReading];
}

- (void)install:(NSString *)path
{
    NSTask *task = [NSTask new];
    
    task.launchPath = [[NSBundle mainBundle] pathForResource:@"tbtool" ofType:@""];
    task.arguments = @[ @"install", path, _hostname ];
    
    [task launch];
}

@end
