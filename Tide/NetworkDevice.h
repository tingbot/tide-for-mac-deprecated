//
//  NetworkDevice.h
//  Tide
//
//  Created by Joe Rickerby on 22/03/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Device.h"

@interface NetworkDevice : Device

@property (copy) NSString *hostname;

- (instancetype)initWithHostname:(NSString *)hostname;

@end
