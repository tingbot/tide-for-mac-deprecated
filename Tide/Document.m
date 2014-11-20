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

@interface Document ()

@property (weak) IBOutlet ACEView *codeView;
@property (weak) IBOutlet NSOutlineView *outlineView;

@property (strong) NSString *code;
@property (strong) FileSystemOutlineViewDataSource *outlineDataSource;

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
    self.codeView.mode = ACEModePython;
    self.codeView.theme = ACEThemeMonokai;
    self.outlineView.dataSource = self.outlineDataSource;
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

- (void)setFileURL:(NSURL *)fileURL
{
    [super setFileURL:fileURL];
    
    self.outlineDataSource = [[FileSystemOutlineViewDataSource alloc] initWithPath:fileURL.path];
    self.outlineView.dataSource = self.outlineDataSource;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self.code = self.codeView.string;

    NSFileWrapper *mainWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:
                                  [self.code dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{ @"main.py": mainWrapper }];
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSData *data = [fileWrapper.fileWrappers[@"main.py"] regularFileContents];
    
    self.code = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.codeView.string = self.code;
    
    return self.code ? YES : NO;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.

    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    self.code = string;
    self.codeView.string = self.code;
    
    return self.code ? YES : NO;
}

@end
