//
//  TMLAuthorizationController.h
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMLAuthorizationController : NSObject

+ (instancetype)sharedAuthorizationController;

- (void)setAccessToken:(NSString *)accessToken
            forAccount:(NSString *)account;

- (NSString *)accessTokenForAccount:(NSString *)account;

@end
