//
//  NSViewDocument.h
//  Tide
//
//  Created by Joe Rickerby on 02/12/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSViewDocument : NSDocument

- (void)loadView;
- (void)viewDidLoad;

@property (strong, nonatomic) NSView *view;

@end
