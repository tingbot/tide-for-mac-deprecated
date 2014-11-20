//
//  FileSystemObject.m
//  Tide
//
//  Created by Joe Rickerby on 18/11/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "FileSystemObject.h"

@interface FileSystemItem ()
{
    NSString *relativePath;
    FileSystemItem *parent;
    NSMutableArray *children;
}

@end

@implementation FileSystemItem

static NSMutableArray *leafNode = nil;

+ (void)initialize {
    if (self == [FileSystemItem class]) {
        leafNode = [[NSMutableArray alloc] init];
    }
}

- (id)initWithPath:(NSString *)path parent:(FileSystemItem *)parentItem {
    self = [super init];
    if (self) {
        parent = parentItem;

        if (!parentItem) {
            relativePath = path;
        } else {
            relativePath = [path lastPathComponent];
        }
    }
    return self;
}

// Creates, caches, and returns the array of children
// Loads children incrementally
- (NSArray *)children {
    
    if (children == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fullPath = [self fullPath];
        BOOL isDir, valid;
        
        valid = [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        
        if (valid && isDir) {
            NSArray *array = [fileManager contentsOfDirectoryAtPath:fullPath error:NULL];
            
            NSUInteger numChildren, i;
            
            numChildren = [array count];
            children = [[NSMutableArray alloc] initWithCapacity:numChildren];
            
            for (i = 0; i < numChildren; i++)
            {
                FileSystemItem *newChild = [[FileSystemItem alloc]
                                            initWithPath:[array objectAtIndex:i] parent:self];
                [children addObject:newChild];
            }
        }
        else {
            children = leafNode;
        }
    }
    return children;
}


- (NSString *)relativePath {
    return relativePath;
}


- (NSString *)fullPath {
    // If no parent, return our own relative path
    if (parent == nil) {
        return relativePath;
    }
    
    // recurse up the hierarchy, prepending each parent’s path
    return [[parent fullPath] stringByAppendingPathComponent:relativePath];
}


- (FileSystemItem *)childAtIndex:(NSUInteger)n {
    return [[self children] objectAtIndex:n];
}


- (NSInteger)numberOfChildren {
    NSArray *tmp = [self children];
    return (tmp == leafNode) ? (-1) : [tmp count];
}

@end
