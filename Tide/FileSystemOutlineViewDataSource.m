//
//  FileSystemOutlineViewDataSource.m
//  Tide
//
//  Created by Joe Rickerby on 18/11/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "FileSystemOutlineViewDataSource.h"

#import "NSFileWrapper+QuicklookURL.h"

@interface FileSystemOutlineViewDataSource ()

@end

@implementation FileSystemOutlineViewDataSource

- (instancetype)initWithFileWrapper:(NSFileWrapper *)fileWrapper
{
    self = [super init];
    
    if (self) {
        self.fileWrapper = fileWrapper;
    }
    
    return self;
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        item = self.fileWrapper;
    }
    
    return [[item fileWrappers] count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == nil) {
        item = self.fileWrapper;
    }
    
    return [item isDirectory];
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        item = self.fileWrapper;
    }
    
    NSDictionary *fileDict = [item fileWrappers];
    
    NSArray *filenames = [[fileDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        // keep main.py at the top of the list
        if ([obj1 isEqualToString:@"main.py"]) {
            return NSOrderedAscending;
        } else if ([obj2 isEqualToString:@"main.py"]) {
            return NSOrderedDescending;
        }
        
        return [obj1 compare:obj2];
    }];
    
    return fileDict[filenames[index]];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (item == nil) {
        item = self.fileWrapper;
    }
    
    NSFileWrapper *fileWrapper = item;
    
    if ([tableColumn.identifier isEqual:@"icon"]) {
        if ([fileWrapper isDirectory]) {
            return [NSImage imageNamed:@"FolderSidebarIcon"];
        } else if ([@[ @"jpg", @"png", @"jpeg", @"gif" ] containsObject:
                    [fileWrapper.filename pathExtension]]) {
            return [NSImage imageNamed:@"ImageFileSidebarIcon"];
        } else {
            return [NSImage imageNamed:@"CodeFileSidebarIcon"];
        }
    } else {
        return [item filename];
    }
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    if ([info.draggingPasteboard.types containsObject:@"public.file-url"]) {
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    NSString *urlString = [info.draggingPasteboard stringForType:@"public.file-url"];
    
    if (!urlString) {
        NSLog(@"Drag failed because no 'public.file-url' property.");
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (!url) {
        NSLog(@"Drag failed because URL could not be parsed");
        return NO;
    }
    
    NSError *error = nil;
    
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:url
                                                            options:NSFileWrapperReadingImmediate
                                                              error:&error];
    
    if (!fileWrapper) {
        NSLog(@"Drag failed because file wrapper init failed. %@", error);
        return NO;
    }
    
    fileWrapper.quicklookURL = url;
    
    [self.fileWrapper addFileWrapper:fileWrapper];
    
    [outlineView reloadData];

    return YES;
}

@end
