//
//  TMLAuthorizationController.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLAPISerializer.h"
#import "TMLAuthorizationController.h"

NSString * const TMLAuthorizationStatusKey = @"status";
NSString * const TMLAuthorizationStatusAuthorized = @"authorized";
NSString * const TMLAuthorizationAccessTokenKey = @"access_token";
NSString * const TMLAuthorizationTranslatorKey = @"translator";

@implementation TMLAuthorizationController

- (NSString *)applicationAuthorizationCookieName {
    TMLConfiguration *config = [[TML sharedInstance] configuration];
    NSString *appKey = [config applicationKey];
    NSString *authCookieName = [NSString stringWithFormat:@"trex_%@", appKey];
    return authCookieName;
}

- (void)removeStoredAuthorizationInfo {
    TMLConfiguration *config = [[TML sharedInstance] configuration];
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSString *cookieName = [self applicationAuthorizationCookieName];
    NSArray *cookies = [cookieJar cookiesForURL:config.gatewayURL];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:cookieName] == NO) {
            continue;
        }
        [cookieJar deleteCookie:cookie];
        break;
    }
}

- (NSDictionary *)storedAuthorizationInfo {
    return [self authorizationInfoFromSharedCookieJar];
}

- (NSDictionary *)authorizationInfoFromSharedCookieJar {
    NSMutableDictionary *authInfo = [[self sharedAuthCookieData] mutableCopy];
    NSDictionary *userInfo = authInfo[TMLAuthorizationTranslatorKey];
    if (authInfo != nil && userInfo != nil) {
        TMLTranslator *translator = [self translatorFromUserInfo:userInfo];
        authInfo[TMLAuthorizationTranslatorKey] = translator;
    }
    return [authInfo copy];
}

- (void)saveAuthorizationInfo:(NSDictionary *)authInfo {
    TMLConfiguration *config = [[TML sharedInstance] configuration];
    NSString *authCookieName = [self applicationAuthorizationCookieName];
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSURL *gatewayURL = config.gatewayURL;
    
    NSMutableDictionary *info = [authInfo mutableCopy];
    id translator = [info valueForKey:TMLAuthorizationTranslatorKey];
    if ([translator isKindOfClass:[TMLTranslator class]] == YES) {
        NSDictionary *translatorInfo = [self translatorInfoFromTranslator:translator];
        if (translatorInfo != nil) {
            info[TMLAuthorizationTranslatorKey] = translatorInfo;
        }
    }
    
    NSData *data = [[info tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *cookieValue = [data base64EncodedStringWithOptions:0];
    NSString *domain = gatewayURL.host;
    NSArray *domainParts = [domain componentsSeparatedByString:@"."];
    if (domainParts.count > 2) {
        domainParts = [domainParts subarrayWithRange:NSMakeRange(domainParts.count - 2, 2)];
        domain = [NSString stringWithFormat:@".%@", [domainParts componentsJoinedByString:@"."]];
    }
    NSDictionary *cookieProps = @{
                                  NSHTTPCookiePath:@"/",
                                  NSHTTPCookieSecure: @(YES),
                                  NSHTTPCookieName: authCookieName,
                                  NSHTTPCookieValue: cookieValue,
                                  NSHTTPCookieDomain: domain,
                                  NSHTTPCookieExpires: [[NSDate date] dateByAddingTimeInterval:86400]
                                  };
    NSHTTPCookie *authCookie = [NSHTTPCookie cookieWithProperties:cookieProps];
    [cookieJar setCookies:@[authCookie]
                   forURL:gatewayURL
          mainDocumentURL:[gatewayURL URLByAppendingPathComponent:@"authorize"]];
}

- (TMLTranslator *)storedAuthorizedTranslator {
    NSDictionary *authInfo = [self sharedAuthCookieData];
    TMLTranslator *translator = [self translatorFromUserInfo:authInfo];
    return translator;
}

#pragma mark - Utility Methods

- (NSDictionary *)sharedAuthCookieData {
    NSHTTPCookie *authCookie = [self sharedAuthCookie];
    NSDictionary *authInfo = nil;
    if (authCookie != nil) {
        NSString *cookieString = [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:authCookie.value
                                                                                                    options:0]
                                                       encoding:NSUTF8StringEncoding];
        authInfo = [cookieString tmlJSONObject];
    }
    return authInfo;
}

- (NSHTTPCookie *)sharedAuthCookie {
    TMLConfiguration *config = [[TML sharedInstance] configuration];
    NSString *appKey = config.applicationKey;
    NSString *authCookieName = [NSString stringWithFormat:@"trex_%@", appKey];
    NSURL *gatewayURL = config.gatewayURL;
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:gatewayURL];
    NSHTTPCookie *authCookie;
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:authCookieName] == YES) {
            authCookie = cookie;
            break;
        }
    }
    return authCookie;
}

- (TMLTranslator *)translatorFromUserInfo:(NSDictionary *)userInfo {
    if (userInfo == nil) {
        return nil;
    }
    TMLTranslator *translator = [TMLAPISerializer materializeObject:userInfo withClass:[TMLTranslator class]];
    if (translator.userID.length == 0) {
        return nil;
    }
    return translator;
}

- (NSDictionary *)translatorInfoFromTranslator:(TMLTranslator *)translator {
    if (translator == nil) {
        return nil;
    }
    NSDictionary *info = [[TMLAPISerializer serializeObject:translator] tmlJSONObject];
    return info;
}

@end
