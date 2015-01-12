//
//  Document.m
//  Tide
//
//  Created by Joe Rickerby on 01/10/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "Document.h"
#import <ACEView.h>
#import "FileSystemOutlineViewDataSource.h"

#import "NSViewDocument.h"
#import "CodeDocument.h"
#import "QuickLookDocument.h"
#import "NSFileWrapper+QuicklookURL.h"

@import Quartz;

@interface Document () <NSOutlineViewDelegate>

@property (weak) IBOutlet ACEView *codeView;
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSSplitView *splitView;

@property (strong) NSString *code;
@property (strong) NSFileWrapper *fileWrapper;
@property (strong) FileSystemOutlineViewDataSource *outlineDataSource;
@property (strong) NSViewDocument *editingDocument;

- (void)addQuicklookURLsToFileWrapper:(NSFileWrapper *)fileWrapper baseURL:(NSURL *)baseURL;

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    self.outlineView.dataSource = self.outlineDataSource;
    self.outlineView.delegate = self;
    self.codeView.string = self.code;
    
    [self.outlineView registerForDraggedTypes:@[@"public.data"]];
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self.code = self.codeView.string;

    NSFileWrapper *oldMainWrapper = self.fileWrapper.fileWrappers[@"main.py"];
    NSFileWrapper *mainWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:
                                  [self.code dataUsingEncoding:NSUTF8StringEncoding]];
    mainWrapper.preferredFilename = @"main.py";
    
    
    [self.fileWrapper removeFileWrapper:oldMainWrapper];
    [self.fileWrapper addFileWrapper:mainWrapper];
    
    return self.fileWrapper;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSData *data = [fileWrapper.fileWrappers[@"main.py"] regularFileContents];
    
    self.code = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.codeView.string = self.code;
    
    self.outlineDataSource = [[FileSystemOutlineViewDataSource alloc] initWithFileWrapper:fileWrapper];
    self.fileWrapper = fileWrapper;
    self.outlineView.dataSource = self.outlineDataSource;
    
    self.fileWrapper.quicklookURL = self.fileURL;
    
    return self.code ? YES : NO;
}

#pragma mark NSOutlineViewDelegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSFileWrapper *fileWrapper = [self.outlineView itemAtRow:self.outlineView.selectedRow];
    NSError *error = nil;
    
    self.editingDocument = [[QuickLookDocument alloc] init];
    BOOL success = [self.editingDocument readFromFileWrapper:fileWrapper
                                                      ofType:@"public.data"
                                                       error:&error];
    
    if (!success) {
        NSLog(@"Failed to load editingDocument, %@", error);
    }
    
    [self setEditorView:self.editingDocument.view];
}

#pragma mark Private

- (void)setEditorView:(NSView *)view
{
    NSView *outlineView = self.splitView.subviews[0];
    
    self.splitView.subviews = @[ outlineView, view ];
    [self.splitView adjustSubviews];
}

@end
