//
//  NSViewDocument.m
//  Tide
//
//  Created by Joe Rickerby on 02/12/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "NSViewDocument.h"

@implementation NSViewDocument

@synthesize view = _view;

- (void)loadView
{
    [NSException raise:NSInternalInconsistencyException
                format:@"Subclasses should override %s", __PRETTY_FUNCTION__];
}

- (NSView *)view
{
    if (!_view) {
        [self loadView];
        
        if (!_view) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Subclasses should set self.view in -loadView"];
        }
        
        [self viewDidLoad];
    }
    
    return _view;
}

- (void)viewDidLoad
{
    ;
}

@end
