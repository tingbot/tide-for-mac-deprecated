//
//  QuickLookDocument.h
//  Tide
//
//  Created by Joe Rickerby on 04/12/2014.
//  Copyright (c) 2014 Tingbot. All rights reserved.
//

#import "NSViewDocument.h"

@interface QuickLookDocument : NSViewDocument

+ (BOOL)canHandleFileWithExtension:(NSString *)extension;

@end
