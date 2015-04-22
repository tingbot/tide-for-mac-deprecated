//
//  Document.m
//  Tide
//
//  Created by Joe Rickerby on 01/10/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "Document.h"

#import <ACEView.h>
#import <FBKVOController.h>

#import "FileSystemOutlineViewDataSource.h"
#import "NSViewDocument.h"
#import "CodeDocument.h"
#import "QuickLookDocument.h"
#import "NSFileWrapper+QuicklookURL.h"
#import "SimulatorDevice.h"
#import "NetworkDevice.h"
#import "NetworkDeviceDiscoverer.h"
#import "ConsoleView.h"

@import Quartz;

@interface Document () <NSOutlineViewDelegate, NSSplitViewDelegate>

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSPopUpButton *runDestinationDropdown;
@property (weak) IBOutlet NSSplitView *verticalSplitView;
@property (weak) IBOutlet NSSplitView *horizontalSplitView;

@property (strong) NSString *code;
@property (strong) NSFileWrapper *fileWrapper;
@property (strong) FileSystemOutlineViewDataSource *outlineDataSource;
@property (strong) NSViewDocument *editingDocument;
@property (strong) NSFileWrapper *editingFileWrapper;
@property (weak) IBOutlet ConsoleView *consoleView;

@end

@implementation Document

- (instancetype)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self = [super initWithType:typeName error:outError];
    
    if (self) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"default" withExtension:@"tingapp"];
        NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:url
                                                                options:NSFileWrapperReadingImmediate
                                                                  error:outError];
        
        if (!fileWrapper) {
            return nil;
        }
        
        BOOL success = [self readFromFileWrapper:fileWrapper ofType:typeName error:outError];
        
        if (!success) {
            return nil;
        }
    }
    
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    self.outlineView.dataSource = self.outlineDataSource;
    self.outlineView.delegate = self;
    [self.verticalSplitView setPosition:self.verticalSplitView.bounds.size.height ofDividerAtIndex:0];
    
    [self.outlineView registerForDraggedTypes:@[@"public.data"]];
    [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    
    [self.runDestinationDropdown removeAllItems];
    
    [self.KVOController observe:[NetworkDeviceDiscoverer sharedInstance]
                        keyPath:@"devices"
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                          block:^(id observer, id object, NSDictionary *change) {
                              [self setNetworkDevices:change[NSKeyValueChangeNewKey]];
                          }];
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
    
    return YES;
}

#pragma mark UI Callbacks

- (IBAction)runButtonPressed:(id)sender {
    NSString *runDirectory = [NSTemporaryDirectory() stringByAppendingString:[[NSUUID UUID] UUIDString]];
    NSURL *runDirectoryURL = [NSURL fileURLWithPath:runDirectory];
    
    NSError *error = nil;
    
    [self saveEditingDocumentChanges];
    
    [self.fileWrapper writeToURL:runDirectoryURL options:0 originalContentsURL:nil error:&error];
    
    Device *device = self.runDestinationDropdown.selectedItem.representedObject;
    
    NSFileHandle *consoleFD = [device run:runDirectory error:&error];
    [self.consoleView clear];
    self.consoleView.fileHandleToRead = consoleFD;
    
    if ([self.verticalSplitView isSubviewCollapsed:self.consoleView]) {
        [self.verticalSplitView setPosition:self.verticalSplitView.bounds.size.height * 4.0/5.0
                           ofDividerAtIndex:0];
    }
}

#pragma mark NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    if (subview == self.consoleView) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    if (subview == self.consoleView) {
        return YES;
    } else {
        return NO;
    }
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    return 100.0;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (splitView == self.verticalSplitView) {
        // the console should not be smaller than 100px high
        return splitView.bounds.size.height - 100;
    }
    
    return proposedMaximumPosition;
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

- (void)setNetworkDevices:(NSSet *)networkDevices
{
    NSArray *networkDevicesArray = [[networkDevices allObjects] sortedArrayUsingDescriptors:
                                    @[ [NSSortDescriptor sortDescriptorWithKey:@"hostname" ascending:YES] ]];
    
    NSArray *allDevices = [@[ [SimulatorDevice new] ] arrayByAddingObjectsFromArray:networkDevicesArray];
    
    [self setDropdownDevices:allDevices];
}

- (void)setDropdownDevices:(NSArray *)dropdownDevices
{
    // remove items no longer in the array
    for (NSMenuItem *item in self.runDestinationDropdown.itemArray) {
        if (![dropdownDevices containsObject:item.representedObject]) {
            if ([self.runDestinationDropdown selectedItem] == item) {
                item.enabled = NO;
            } else {
                [self.runDestinationDropdown removeItemWithTitle:item.title];
            }
        }
    }
    
    NSArray *existingDevices = [self.runDestinationDropdown.itemArray valueForKey:@"representedObject"];
    
    // add items that are new
    for (Device *device in dropdownDevices) {
        if (![existingDevices containsObject:device]) {
            [self.runDestinationDropdown addItemWithTitle:device.name];
            self.runDestinationDropdown.lastItem.representedObject = device;
            
            NSImage *image = device.image;
            
            image.size = CGSizeMake(16, 16);
            self.runDestinationDropdown.lastItem.image = image;
        }
    }
    
    [self.runDestinationDropdown invalidateIntrinsicContentSize];
}

- (void)setEditorView:(NSView *)view
{
    NSView *oldEditorView = self.horizontalSplitView.subviews[1];
    
    view.frame = oldEditorView.frame;
    
    [self.horizontalSplitView replaceSubview:oldEditorView with:view];
    [self.horizontalSplitView adjustSubviews];
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
