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
#define TMLDefaultApplicationKey @"fc4e6ffc979553fc5993381dc22c82dd4ec599c0e3310a52eb5a764ad9e7ad17"
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
