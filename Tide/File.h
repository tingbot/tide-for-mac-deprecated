//
//  File.h
//  Tide
//
//  Created by Joe Rickerby on 18/03/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface File : NSObject

@property (strong) NSString *name;

- (instancetype)initWithFileHandle:(NSFileHandle *)fileHandle;
- (NSFileHandle *)saveToFileHandleError:(NSError **)error;

@end

@interface Folder : File

@property (copy) NSArray *files;

@end

@interface RegularFile : File

@end
