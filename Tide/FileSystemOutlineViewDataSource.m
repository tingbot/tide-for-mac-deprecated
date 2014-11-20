//
//  FileSystemOutlineViewDataSource.m
//  Tide
//
//  Created by Joe Rickerby on 18/11/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "FileSystemOutlineViewDataSource.h"
#import "FileSystemObject.h"

@interface FileSystemOutlineViewDataSource ()
{
    FileSystemItem *_rootItem;
}

@end

@implementation FileSystemOutlineViewDataSource

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    
    if (self) {
        self.path = path;
        
        _rootItem = [[FileSystemItem alloc] initWithPath:path parent:nil];
    }
    
    return self;
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        item = _rootItem;
    }
    
    return [item numberOfChildren];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == nil) {
        item = _rootItem;
    }
    
    return ([item numberOfChildren] != -1);
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        item = _rootItem;
    }
    
    return [(FileSystemItem *)item childAtIndex:index];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (item == nil) {
        item = _rootItem;
    }
    
    return [item relativePath];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    return NSDragOperationCopy;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    NSString *urlString = [info.draggingPasteboard stringForType:@"public.file-url"];
    
    
//    [[info draggingPasteboard] writeFileWrapper:<#(NSFileWrapper *)#>]
    return YES;
}

@end
