  //
//  main.m
//  Sample
//
//  Created by Michael Berkovich on 1/30/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "TMLPrivateConfig.h"

#ifndef TMLDefaultApplicationKey
#define TMLDefaultApplicationKey @"9102347fa327caedc04673441c16defa12e52c0a2fdf62b83c151086c418b39b"
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
