//
//  FileSystemObject.h
//  Tide
//
//  Created by Joe Rickerby on 18/11/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileSystemItem : NSObject

- (id)initWithPath:(NSString *)path parent:(FileSystemItem *)parentItem;
- (NSInteger)numberOfChildren;// Returns -1 for leaf nodes
- (FileSystemItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;

@end
