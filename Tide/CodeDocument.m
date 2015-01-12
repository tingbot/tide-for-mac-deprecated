//
//  CodeDocument.m
//  Tide
//
//  Created by Joe Rickerby on 02/12/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "CodeDocument.h"
#import <ACEView.h>

@interface CodeDocument ()

@property (strong, nonatomic) ACEView *view;

@end

@implementation CodeDocument

@dynamic view;

- (void)loadView
{
    self.view = [[ACEView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    [self.view awakeFromNib];
    
    self.view.mode = ACEModePython;
    self.view.theme = ACEThemeMonokai;
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

@end
