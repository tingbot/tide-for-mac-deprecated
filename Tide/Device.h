//
//  Device.h
//  Tide
//
//  Created by Joe Rickerby on 04/02/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Device : NSObject

+ (BOOL)canInstall;

- (NSFileHandle *)run:(NSString *)path error:(NSError **)error;
- (void)install:(NSString *)path;

- (NSString *)name;
- (NSImage *)image;

@end
