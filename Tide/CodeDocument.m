//
//  CodeDocument.m
//  Tide
//
//  Created by Joe Rickerby on 02/12/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "CodeDocument.h"
#import <ACEView.h>

@interface CodeDocument () <ACEViewDelegate>

@property (strong, nonatomic) ACEView *view;

@end

@implementation CodeDocument

@dynamic view;

+ (BOOL)canHandleFileWithExtension:(NSString *)extension
{
    return [@[ @"py",
               @"txt",
               @"json",
               @"xml" ] containsObject:extension.lowercaseString];
}

- (void)dealloc
{
    self.view.delegate = nil;
}

- (void)loadView
{
    self.view = [[ACEView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    [self.view awakeFromNib];
    
    self.view.mode = ACEModePython;
    self.view.theme = ACEThemeMonokai;
    self.view.delegate = self;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.borderType = NSNoBorder;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return [self.view.string dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (!string) {
        if (outError) *outError = [NSError errorWithDomain:@"Tide"
                                                      code:'!enc'
                                                  userInfo:@{ NSLocalizedDescriptionKey:
                                                                  @"Failed to decode data to UTF8 string" }];
        return NO;
    }
    
    self.view.string = string;
    return YES;
}

#pragma mark ACEViewDelegate

- (void)textDidChange:(NSNotification *)notification
{
    [self updateChangeCount:NSChangeDone];
}

@end
