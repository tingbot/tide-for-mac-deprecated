//
//  ConsoleView.h
//  Tide
//
//  Created by Joe Rickerby on 01/04/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ConsoleView : NSView

@property (strong, nonatomic) NSFileHandle *fileHandleToRead;
@property (assign) BOOL visible;

@end
