//
//  SimulatorDevice.m
//  Tide
//
//  Created by Joe Rickerby on 04/02/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "SimulatorDevice.h"

@implementation SimulatorDevice

- (void)run:(NSString *)path;
{
    NSString *pathToTingbotLibrary = [[NSBundle mainBundle] pathForResource:@"tingbot" ofType:@""];
    
    NSTask *task = [NSTask new];
    
    task.currentDirectoryPath = path;
    task.environment = @{ @"PYTHONPATH": pathToTingbotLibrary.stringByDeletingLastPathComponent };
    task.launchPath = @"/usr/bin/python";
    task.arguments = @[ @"-c", @"import main, tingbot; tingbot.run(main)" ];
    
    [task launch];
}

@end
