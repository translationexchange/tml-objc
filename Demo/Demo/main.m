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
#define TMLDefaultApplicationKey @"145581a710562dce1198f3a5c764c06b23e6dcc47b45844e7161dd92a5bd92c9"
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
