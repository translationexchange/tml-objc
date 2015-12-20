/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The main source file to this application.
*/

@import UIKit;

#import "AAPLAppDelegate.h"

#import "TMLPrivateConfig.h"

#ifndef TMLAccessToken
#define TMLAccessToken @""
#endif
#ifndef TMLApplicationKey
#define TMLApplicationKey @""
#endif

int main(int argc, char *argv[]) {
    [TML sharedInstanceWithApplicationKey:TMLApplicationKey
                              accessToken:TMLAccessToken];
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AAPLAppDelegate class]));
    }
}
