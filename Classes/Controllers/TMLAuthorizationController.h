//
//  TMLAuthorizationController.h
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMLTranslator;

extern NSString * const TMLAuthorizationStatusKey;
extern NSString * const TMLAuthorizationStatusAuthorized;
extern NSString * const TMLAuthorizationAccessTokenKey;
extern NSString * const TMLAuthorizationTranslatorKey;

@interface TMLAuthorizationController : NSObject

- (NSDictionary *)storedAuthorizationInfo;
- (NSDictionary *)authorizationInfoFromSharedCookieJar;
- (void)saveAuthorizationInfo:(NSDictionary *)authInfo;
- (TMLTranslator *)storedAuthorizedTranslator;

@end
