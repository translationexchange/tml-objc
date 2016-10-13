//
//  TMLAuthorizationController.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TML.h"
#import "TMLAuthorizationController.h"
#import <SAMKeychain/SAMKeychain.h>

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
    return [[[[TML sharedInstance] configuration] gatewayBaseURL] absoluteString];
}

- (void)setAccessToken:(NSString *)accessToken
            forAccount:(NSString *)account {
    NSError *error = nil;
    if ([SAMKeychain setPassword:accessToken forService:[self currentService]
                         account:account
                           error:&error] == NO) {
        TMLError(@"Failed to store access token in keychain: %@", error);
    }
}

- (NSString *)accessTokenForAccount:(NSString *)account {
    NSError *error = nil;
    NSString *result = [SAMKeychain passwordForService:[self currentService]
                                               account:account
                                                 error:&error];
    if (error != nil) {
        TMLError(@"Error retrieving access token from keychain: %@", error);
    }
    return result;
}

@end
