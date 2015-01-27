//
//  QuickLookDocument.m
//  Tide
//
//  Created by Joe Rickerby on 04/12/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "QuickLookDocument.h"

#import "NSFileWrapper+QuicklookURL.h"

@import Quartz;

@interface QuickLookDocument ()

@property (strong, nonatomic) QLPreviewView *view;
@property (strong) NSFileWrapper *fileWrapper;

@end

@implementation QuickLookDocument

@dynamic view;

+ (BOOL)canHandleFileWithExtension:(NSString *)extension
{
    
    static NSSet *supportedExtensions = nil;
    
    if (!supportedExtensions) {
        supportedExtensions = [NSSet setWithArray:@[ @"jpg",
                                                     @"jpeg",
                                                     @"png",
                                                     @"mpg",
                                                     @"bmp",
                                                     @"gif",
                                                     @"m4v",
                                                     @"pdf",
                                                     @"tiff",
                                                     @"psd", ]];
    }
    
    return [supportedExtensions containsObject:extension];
}

- (void)loadView
{
    self.view = [[QLPreviewView alloc] initWithFrame:NSZeroRect style:QLPreviewViewStyleNormal];
    
    self.view.previewItem = self.fileWrapper.quicklookURL;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self.fileWrapper = fileWrapper;
    return YES;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return self.fileWrapper;
}

@end
