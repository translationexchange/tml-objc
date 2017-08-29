  //
//  main.m
//  Sample
//
//  Created by Michael Berkovich on 1/30/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

#ifndef TMLDefaultApplicationKey
#define TMLDefaultApplicationKey @"5bfd8c10c41088b3ea2efd06d6ad6014d4a4da0d481cd3214d5de3e0e173433b"
#endif

#ifndef DEBUG
#define DEBUG true
#endif

int main(int argc, char * argv[])
{
    @autoreleasepool {
        [TML sharedInstanceWithApplicationKey:TMLDefaultApplicationKey];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
