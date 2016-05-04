//
//  TMLAuthorizationController.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TMLAuthorizationController.h"
#import <SSKeychain/SSKeychain.h>

NSString * const TMLKeychainServiceName = @"translationexchange.com";

@implementation TMLAuthorizationController

+ (instancetype)sharedAuthorizationController {
    static TMLAuthorizationController *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TMLAuthorizationController alloc] init];
    });
    return sharedInstance;
}

- (void)setAccessToken:(NSString *)accessToken
            forAccount:(NSString *)account {
    [SSKeychain setPassword:accessToken forService:TMLKeychainServiceName account:account];
}

- (NSString *)accessTokenForAccount:(NSString *)account {
    return [SSKeychain passwordForService:TMLKeychainServiceName
                                  account:account];
}

@end
