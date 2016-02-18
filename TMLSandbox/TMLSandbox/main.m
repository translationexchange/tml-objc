//
//  main.m
//  TMLSandbox
//
//  Created by Pasha on 2/17/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#define APP_KEY @"d1050d61e1db4d5fbf8808727e60ec18b6f321b7b9977ae08e778c52ab4bf473"
#define APP_TOKEN @""

int main(int argc, char * argv[]) {
    @autoreleasepool {
        TMLConfiguration *config = [[TMLConfiguration alloc] initWithApplicationKey:APP_KEY accessToken:APP_TOKEN];
        config.neverSubmitNewTranslationKeys = YES;
        [TML sharedInstanceWithConfiguration:config];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
