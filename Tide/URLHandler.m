//
//  URLHandler.m
//  Tide
//
//  Created by Joe Rickerby on 22/10/2015.
//  Copyright © 2015 Tingbot. All rights reserved.
//

#import "URLHandler.h"

#import <Cocoa/Cocoa.h>

#import "Document.h"

@implementation URLHandler

+ (instancetype)sharedInstance
{
    static id result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [[self alloc] init];
    });
    
    return result;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                           andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass
                                                            andEventID:kAEGetURL];
    }
    
    return self;
}


- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
    NSLog(@"%@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"%@", url.query);
    
    NSDictionary *queryDict = [self parseQueryString:url.query];
    
    NSString *code = queryDict[@"code"];
    
    if (!code) {
        NSLog(@"Malformed URL %@", urlString);
        return;
    }
    
    Document *doc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"TideApp"
                                                                                          error:NULL];
    
    NSFileWrapper *bundle = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
    
    [bundle addRegularFileWithContents:[code dataUsingEncoding:NSUTF8StringEncoding]
                     preferredFilename:@"main.py"];
    
    [doc readFromFileWrapper:bundle
                      ofType:@"TideApp"
                       error:NULL];
    
    [doc makeWindowControllers];
    [doc showWindows];
}

- (NSDictionary *)parseQueryString:(NSString *)queryString
{
    NSMutableDictionary *queryDict = [[NSMutableDictionary alloc] init];
    
    for (NSString *qs in [queryString componentsSeparatedByString:@"&"]) {
        // Get the parameter name
        NSString *key = [[qs componentsSeparatedByString:@"="] objectAtIndex:0];
        // Get the parameter value
        NSString *value = [[qs componentsSeparatedByString:@"="] objectAtIndex:1];
        value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        queryDict[key] = value;
    }
    
    return queryDict;
}

@end
