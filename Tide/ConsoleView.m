//
//  ConsoleView.m
//  Tide
//
//  Created by Joe Rickerby on 01/04/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "ConsoleView.h"

#import <Masonry.h>
#import <AMR_ANSIEscapeHelper.h>

@interface ConsoleView ()
{
    NSTextView *_textView;
    NSScrollView *_scrollView;
    AMR_ANSIEscapeHelper *_ansiParser;
}
@end

@implementation ConsoleView

@synthesize fileHandleToRead = _fileHandleToRead;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    _ansiParser = [[AMR_ANSIEscapeHelper alloc] init];
    _ansiParser.defaultStringColor = [NSColor colorWithWhite:0.9 alpha:1.0];
    _ansiParser.font = [NSFont fontWithName:@"Monaco" size:10];
    
    _scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
    _scrollView.hasVerticalScroller = YES;
    _scrollView.autohidesScrollers = YES;
    
    _textView = [[NSTextView alloc] initWithFrame:self.bounds];
    _textView.editable = NO;
    _textView.backgroundColor = [NSColor colorWithWhite:0.13 alpha:1.0];
    
    _scrollView.documentView = _textView;
    
    [self addSubview:_scrollView];
    
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (void)setFileHandleToRead:(NSFileHandle *)fileHandleToRead
{
    if (fileHandleToRead == _fileHandleToRead) {
        return;
    }
    
    __typeof__(self) __weak weakSelf = self;
    
    _fileHandleToRead.readabilityHandler = nil;
    _fileHandleToRead = fileHandleToRead;
    _fileHandleToRead.readabilityHandler = ^(NSFileHandle *handle) {
        if (!weakSelf) {
            return;
        }
        
        ConsoleView *strongSelf = weakSelf;
        
        NSTextView *textView = strongSelf->_textView;
        NSString *newText = [[NSString alloc] initWithData:[handle availableData] encoding:NSUTF8StringEncoding];
        
        NSAttributedString *coloredText = [strongSelf->_ansiParser attributedStringWithANSIEscapedString:newText];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL scrolledToBottom = (strongSelf->_scrollView.verticalScroller.floatValue > 0.99);

            [textView.textStorage appendAttributedString:coloredText];
            
            if (scrolledToBottom) {
                [textView scrollRangeToVisible:NSMakeRange(textView.string.length, 0)];
            }
        });
    };
}

- (void)clear
{
    [_textView.textStorage setAttributedString:[[NSAttributedString alloc] init]];
}

@end
