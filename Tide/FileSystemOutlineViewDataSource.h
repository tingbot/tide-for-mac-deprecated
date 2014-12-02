//
//  FileSystemOutlineViewDataSource.h
//  Tide
//
//  Created by Joe Rickerby on 18/11/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface FileSystemOutlineViewDataSource : NSObject <NSOutlineViewDataSource>

- (instancetype)initWithFileWrapper:(NSFileWrapper *)path;

@property (strong) NSFileWrapper *fileWrapper;

@end
