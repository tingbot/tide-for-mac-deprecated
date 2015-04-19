//
//  NSFileWrapper+QuicklookURL.m
//  Tide
//
//  Created by Joe Rickerby on 12/01/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "NSFileWrapper+QuicklookURL.h"

#import <objc/runtime.h>

@implementation NSFileWrapper (QuicklookURL)

- (NSURL *)quicklookURL
{
    return objc_getAssociatedObject(self, "quicklookURL");
}

- (void)setQuicklookURL:(NSURL *)quicklookURL
{
    objc_setAssociatedObject(self, "quicklookURL", quicklookURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSString *filePath = quicklookURL.path;
    
    if (quicklookURL && self.isDirectory) {
        for (NSString *childFilename in self.fileWrappers) {
            NSFileWrapper *child = self.fileWrappers[childFilename];
            NSString *childPath = [filePath stringByAppendingPathComponent:childFilename];
            
            child.quicklookURL = [NSURL fileURLWithPath:childPath];
        }
    }
}

@end
