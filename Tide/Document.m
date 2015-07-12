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
#import <Masonry.h>
#import <ReactiveCocoa.h>

#import "FileSystemOutlineViewDataSource.h"
#import "NSViewDocument.h"
#import "CodeDocument.h"
#import "QuickLookDocument.h"
#import "NSFileWrapper+QuicklookURL.h"
#import "SimulatorDevice.h"
#import "NetworkDevice.h"
#import "NetworkDeviceDiscoverer.h"
#import "ConsoleView.h"
#import "CustomSplitView.h"

@import Quartz;

@interface Document () <NSOutlineViewDelegate, NSSplitViewDelegate>
{
    NSOutlineView *_outlineView;
    NSPopUpButton *_runDestinationDropdown;
    NSSplitView *_verticalSplitView;
    NSSplitView *_horizontalSplitView;
    ConsoleView *_consoleView;
    NSTask *_runningTask;
}

@property (strong) NSTask *runningTask;

@property (strong) NSString *code;
@property (strong) NSFileWrapper *fileWrapper;
@property (strong) FileSystemOutlineViewDataSource *outlineDataSource;
@property (strong) NSViewDocument *editingDocument;
@property (strong) NSFileWrapper *editingFileWrapper;

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
    _outlineDataSource = [[FileSystemOutlineViewDataSource alloc] initWithFileWrapper:fileWrapper];
    self.fileWrapper = fileWrapper;
    _outlineView.dataSource = _outlineDataSource;
    self.fileWrapper.quicklookURL = self.fileURL;
    
    return YES;
}

- (void)makeWindowControllers
{
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 632, 533)
                                                   styleMask:NSClosableWindowMask | NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
                                                     backing:NSBackingStoreBuffered
                                                       defer:YES];
    
    NSView *view = [NSView new];
    [window setContentView:view];
    
    NSBox *topBar = [NSBox new];
    topBar.boxType = NSBoxCustom;
    topBar.borderWidth = 0;
    topBar.fillColor = [NSColor colorWithSRGBRed:0.145 green:0.145 blue:0.145 alpha:1];
    [view addSubview:topBar];
    [topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(view);
        make.height.equalTo(@41);
    }];
    
    NSButton *runButton = [[NSButton alloc] init];
    runButton.bordered = NO;
    runButton.image = [NSImage imageNamed:@"play-pink"];
    runButton.toolTip = @"Run";
    [topBar addSubview:runButton];
    [runButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(@28);
        make.centerY.equalTo(topBar);
        make.left.equalTo(topBar).offset(21);
    }];
    runButton.target = self;
    runButton.action = @selector(runButtonPressed:);
    
    NSButton *stopButton = [[NSButton alloc] init];
    stopButton.bordered = NO;
    stopButton.image = [NSImage imageNamed:@"stop-pink"];
    stopButton.toolTip = @"Stop";
    [topBar addSubview:stopButton];
    [stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(runButton);
    }];
    stopButton.target = self;
    stopButton.action = @selector(stopButtonPressed:);
    
    RACSignal *runningTaskSignal = [RACObserve(self, runningTask) map:^id(id value) {
        return @(value != nil);
    }];
    
    RAC(runButton, hidden) = runningTaskSignal;
    RAC(stopButton, hidden) = [runningTaskSignal not];
    
    NSButton *uploadButton = [[NSButton alloc] init];
    uploadButton.bordered = NO;
    uploadButton.image = [NSImage imageNamed:@"upload-dark"];
    uploadButton.enabled = NO;
    uploadButton.toolTip = @"Upload";
    [topBar addSubview:uploadButton];
    [uploadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(runButton);
        make.left.equalTo(runButton.mas_right).offset(10);
    }];
    
    _runDestinationDropdown = [[NSPopUpButton alloc] init];
    [topBar addSubview:_runDestinationDropdown];
    [_runDestinationDropdown mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(topBar).offset(-10);
        make.centerY.equalTo(topBar);
        make.width.greaterThanOrEqualTo(@195);
    }];
    
    _verticalSplitView = [[CustomSplitView alloc] initWithDividerColor:[NSColor colorWithSRGBRed:0.118 green:0.122 blue:0.118 alpha:1]
                                                      dividerThickness:1.0];
    _verticalSplitView.dividerStyle = NSSplitViewDividerStyleThin;
    _verticalSplitView.vertical = YES;
    _verticalSplitView.delegate = self;
    [view addSubview:_verticalSplitView];
    [_verticalSplitView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(view);
        make.top.equalTo(topBar.mas_bottom);
        make.bottom.equalTo(view).offset(-20);
    }];
    
    _outlineView = [NSOutlineView new];
    [_verticalSplitView addSubview:_outlineView];
    _outlineView.dataSource = self.outlineDataSource;
    _outlineView.delegate = self;
    _outlineView.backgroundColor = [NSColor colorWithSRGBRed:0.200 green:0.204 blue:0.204 alpha:1];
    
    NSTableColumn *iconColumn = [[NSTableColumn alloc] initWithIdentifier:@"icon"];
    iconColumn.title = @"Icon";
    iconColumn.dataCell = [NSImageCell new];
    iconColumn.width = 31;
    iconColumn.minWidth = 30;
    [_outlineView addTableColumn:iconColumn];
    _outlineView.outlineTableColumn = iconColumn;
    
    NSTableColumn *filenameColumn = [[NSTableColumn alloc] initWithIdentifier:@"filename"];
    filenameColumn.title = @"Filename";
    filenameColumn.dataCell = ({
        NSTextFieldCell *c = [NSTextFieldCell new];
        c.textColor = [NSColor whiteColor];
        c;
    });
    filenameColumn.resizingMask = NSTableColumnAutoresizingMask;
    [_outlineView addTableColumn:filenameColumn];

    _horizontalSplitView = [NSSplitView new];
    _horizontalSplitView.dividerStyle = NSSplitViewDividerStyleThin;
    _horizontalSplitView.vertical = NO;
    _horizontalSplitView.delegate = self;
    [_verticalSplitView addSubview:_horizontalSplitView];
    
    [_horizontalSplitView addSubview:[NSView new]];
    
    _consoleView = [ConsoleView new];
    [_horizontalSplitView addSubview:_consoleView];
    
    NSBox *pinkBox = [NSBox new];
    pinkBox.fillColor = [NSColor colorWithSRGBRed:0.890 green:0.129 blue:0.298 alpha:1];
    pinkBox.boxType = NSBoxCustom;
    [view addSubview:pinkBox];
    [pinkBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(view);
        make.top.equalTo(_verticalSplitView.mas_bottom);
    }];
    
    [window setInitialFirstResponder:view];
    
    NSWindowController *controller = [[NSWindowController alloc] initWithWindow:window];
    [self addWindowController:controller];
    
    [window layoutIfNeeded];
    
    [_horizontalSplitView setPosition:_horizontalSplitView.bounds.size.height ofDividerAtIndex:0];
    [_verticalSplitView setPosition:150 ofDividerAtIndex:0];
    
    [_outlineView registerForDraggedTypes:@[@"public.data"]];
    [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    
    [_runDestinationDropdown removeAllItems];
    
    [self.KVOController observe:[NetworkDeviceDiscoverer sharedInstance]
                        keyPath:@"devices"
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                          block:^(id observer, id object, NSDictionary *change) {
                              [self setNetworkDevices:change[NSKeyValueChangeNewKey]];
                          }];

}

#pragma mark UI Callbacks

- (IBAction)runButtonPressed:(id)sender {
    NSString *runDirectory = [NSTemporaryDirectory() stringByAppendingString:[[NSUUID UUID] UUIDString]];
    NSURL *runDirectoryURL = [NSURL fileURLWithPath:runDirectory];
    
    NSError *error = nil;
    
    [self saveEditingDocumentChanges];
    
    [self.fileWrapper writeToURL:runDirectoryURL options:0 originalContentsURL:nil error:&error];
    
    Device *device = _runDestinationDropdown.selectedItem.representedObject;
    
    self.runningTask = [device run:runDirectory error:&error];
    
    if ([_horizontalSplitView isSubviewCollapsed:_consoleView]) {
        [_horizontalSplitView setPosition:_horizontalSplitView.bounds.size.height * 4.0/5.0
                         ofDividerAtIndex:0];
    }
}

- (void)stopButtonPressed:(id)sender {
    [self.runningTask terminate];
}

#pragma mark NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    if (subview == _consoleView) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    if (subview == _consoleView) {
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
    if (splitView == _horizontalSplitView) {
        // the console should not be smaller than 60px high
        return splitView.bounds.size.height - 60;
    }
    
    return proposedMaximumPosition;
}

#pragma mark NSOutlineViewDelegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSFileWrapper *fileWrapper = [_outlineView itemAtRow:_outlineView.selectedRow];
    
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
    for (NSMenuItem *item in _runDestinationDropdown.itemArray) {
        if (![dropdownDevices containsObject:item.representedObject]) {
            if ([_runDestinationDropdown selectedItem] == item) {
                item.enabled = NO;
            } else {
                [_runDestinationDropdown removeItemWithTitle:item.title];
            }
        }
    }
    
    NSArray *existingDevices = [_runDestinationDropdown.itemArray valueForKey:@"representedObject"];
    
    // add items that are new
    for (Device *device in dropdownDevices) {
        if (![existingDevices containsObject:device]) {
            [_runDestinationDropdown addItemWithTitle:device.name];
            _runDestinationDropdown.lastItem.representedObject = device;
            
            NSImage *image = device.image;
            
            image.size = CGSizeMake(16, 16);
            _runDestinationDropdown.lastItem.image = image;
        }
    }
    
    [_runDestinationDropdown invalidateIntrinsicContentSize];
}

- (void)setEditorView:(NSView *)view
{
    NSView *oldEditorView = _horizontalSplitView.subviews[0];
    
    view.frame = oldEditorView.frame;
    
    [_horizontalSplitView replaceSubview:oldEditorView with:view];
    [_horizontalSplitView adjustSubviews];
}

- (NSTask *)runningTask
{
    return _runningTask;
}

- (void)setRunningTask:(NSTask *)runningTask
{
    [_consoleView clear];
    [_consoleView setFileHandleToRead:[runningTask.standardOutput fileHandleForReading]];
    
    __typeof__(self) __weak weakSelf = self;
    
    runningTask.terminationHandler = ^(NSTask *task){
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            strongSelf->_consoleView.fileHandleToRead = nil;
            
            [weakSelf willChangeValueForKey:@"runningTask"];
            strongSelf->_runningTask = nil;
            [weakSelf didChangeValueForKey:@"runningTask"];
        }
    };
    
    _runningTask = runningTask;
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
    
    NSFileWrapper *parent = [_outlineView parentForItem:self.editingFileWrapper];
    
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
        [_outlineView reloadItem:nil reloadChildren:YES];
    } else {
        [_outlineView reloadItem:parent reloadChildren:YES];
    }
}

@end
