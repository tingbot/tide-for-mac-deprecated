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
#import "SimulatorDevice.h"

@import Quartz;

@interface Document () <NSOutlineViewDelegate>

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSPopUpButton *runDestinationDropdown;

@property (strong) NSString *code;
@property (strong) NSFileWrapper *fileWrapper;
@property (strong) FileSystemOutlineViewDataSource *outlineDataSource;
@property (strong) NSViewDocument *editingDocument;
@property (strong) NSFileWrapper *editingFileWrapper;

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
    [self saveEditingDocumentChanges];
    
    return self.fileWrapper;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self.outlineDataSource = [[FileSystemOutlineViewDataSource alloc] initWithFileWrapper:fileWrapper];
    self.fileWrapper = fileWrapper;
    self.outlineView.dataSource = self.outlineDataSource;
    self.fileWrapper.quicklookURL = self.fileURL;
    
    [self.outlineView reloadData];
    
    return YES;
}

#pragma mark UI Callbacks

- (IBAction)runButtonPressed:(id)sender {
    NSString *runDirectory = [NSTemporaryDirectory() stringByAppendingString:[[NSUUID UUID] UUIDString]];
    NSURL *runDirectoryURL = [NSURL fileURLWithPath:runDirectory];
    
    NSError *error = nil;
    
    [self saveEditingDocumentChanges];
    
    [self.fileWrapper writeToURL:runDirectoryURL options:0 originalContentsURL:nil error:&error];
    
    long deviceIndex = self.runDestinationDropdown.indexOfSelectedItem;
    Device *device = nil;
    
    switch (deviceIndex) {
        case 0:
            // simulator
            device = [SimulatorDevice new];
            break;
        default:
            break;
    }
    
    [device runCodeInFolder:runDirectory];
}

#pragma mark NSOutlineViewDelegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSFileWrapper *fileWrapper = [self.outlineView itemAtRow:self.outlineView.selectedRow];
    
    if (fileWrapper.isRegularFile) {
        [self saveEditingDocumentChanges];
        
        self.editingDocument = [self editingDocumentForFileWrapper:fileWrapper];
        self.editingFileWrapper = fileWrapper;
        
        [self setEditorView:self.editingDocument.view];
    }
}

#pragma mark Private

- (void)setEditorView:(NSView *)view
{
    NSView *outlineView = self.splitView.subviews[0];
    
    self.splitView.subviews = @[ outlineView, view ];
    [self.splitView adjustSubviews];
}

- (NSViewDocument *)editingDocumentForFileWrapper:(NSFileWrapper *)fileWrapper
{
    NSViewDocument *result;
    
    if ([QuickLookDocument canHandleFileWithExtension:fileWrapper.filename.pathExtension]) {
        result = [[QuickLookDocument alloc] init];
    } else if ([CodeDocument canHandleFileWithExtension:fileWrapper.filename.pathExtension]) {
        result = [[CodeDocument alloc] init];
    } else {
        // is it UTF8 text? if so use the code editor. Otherwise, quick look.
        NSString *text = [[NSString alloc] initWithData:fileWrapper.regularFileContents
                                               encoding:NSUTF8StringEncoding];
        if (text) {
            result = [[CodeDocument alloc] init];
        } else {
            result = [[QuickLookDocument alloc] init];
        }
    }
    
    NSError *error;
    
    BOOL success = [result readFromFileWrapper:fileWrapper ofType:@"public.data" error:&error];
    
    if (!success) {
        NSLog(@"Failed to load editingDocument, %@", error);
        return nil;
    }
    
    return result;
}

- (NSFileWrapper *)parentOfFileWrapper:(NSFileWrapper *)target usingRoot:(NSFileWrapper *)root
{
    for (NSFileWrapper *fileWrapper in root.fileWrappers) {
        if (fileWrapper == target) {
            return root;
        }
        
        NSFileWrapper *parent = [self parentOfFileWrapper:target usingRoot:fileWrapper];
        
        if (parent) {
            return parent;
        }
    }
    
    return nil;
}

- (void)saveEditingDocumentChanges
{
    if (!self.editingDocument.documentEdited) {
        return;
    }
    
    NSFileWrapper *parent = [self.outlineView parentForItem:self.editingFileWrapper];
    
    if (!parent) {
        parent = self.fileWrapper;
    }
    
    NSError *error = nil;
    
    NSString *filename = self.editingFileWrapper.filename;
    
    NSFileWrapper *oldFileWrapper = parent.fileWrappers[filename];
    NSFileWrapper *newFileWrapper = [self.editingDocument fileWrapperOfType:@"public.data"
                                                                      error:&error];
    
    if (!newFileWrapper) {
        NSLog(@"Failed to save changes to %@. %@ %s",
              self.editingFileWrapper.filename, error, __PRETTY_FUNCTION__);
        return;
    }
    
    newFileWrapper.preferredFilename = filename;
    newFileWrapper.filename = filename;
    
    [parent removeFileWrapper:oldFileWrapper];
    [parent addFileWrapper:newFileWrapper];
    
    if (parent == self.fileWrapper) {
        [self.outlineView reloadItem:nil reloadChildren:YES];
    } else {
        [self.outlineView reloadItem:parent reloadChildren:YES];
    }
}

@end
