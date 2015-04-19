//
//  NetworkDeviceDiscoverer.h
//  Tide
//
//  Created by Joe Rickerby on 11/04/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkDeviceDiscoverer : NSObject

+ (instancetype)sharedInstance;

// set of NetworkDevice objects
@property (copy) NSSet *devices;

@end
