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
#define TMLDefaultApplicationKey @"2f3bf80d0c46815c6cbf922b0877f9e2cf5dd4bc65e84a0fdbc883e22259cf7e"
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
