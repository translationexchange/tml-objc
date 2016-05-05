//
//  TMLAuthorizationController.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TML.h"
#import "TMLAuthorizationController.h"
#import <SSKeychain/SSKeychain.h>

@implementation TMLAuthorizationController

+ (instancetype)sharedAuthorizationController {
    static TMLAuthorizationController *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TMLAuthorizationController alloc] init];
    });
    return sharedInstance;
}

- (NSString *)currentService {
    return [[[[TML sharedInstance] configuration] gatewayURL] absoluteString];
}

- (void)setAccessToken:(NSString *)accessToken
            forAccount:(NSString *)account {
    [SSKeychain setPassword:accessToken forService:[self currentService] account:account];
}

- (NSString *)accessTokenForAccount:(NSString *)account {
    return [SSKeychain passwordForService:[self currentService]
                                  account:account];
}

@end
