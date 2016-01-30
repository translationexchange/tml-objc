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

#ifndef TMLDefaultAccessToken
#define TMLDefaultAccessToken @""
#endif
#ifndef TMLDefaultApplicationKey
#define TMLDefaultApplicationKey @"8641229aae46c7d39e78657e9da0c86c80f432c21e4e4fb5bf0934673499be7a"
#endif

int main(int argc, char * argv[])
{
    @autoreleasepool {
        [TML sharedInstanceWithApplicationKey:TMLDefaultApplicationKey accessToken:TMLDefaultAccessToken];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
