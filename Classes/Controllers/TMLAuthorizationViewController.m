//
//  TMLAuthorizationViewController.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLAPISerializer.h"
#import "TMLAuthorizationViewController.h"
#import "TMLTranslator.h"
#import <WebKit/WebKit.h>

NSString * const TMLAuthorizationAccessTokenKey = @"access_token";
NSString * const TMLAuthorizationUserKey = @"user";
NSString * const TMLAuthorizationErrorDomain = @"TMLAuthorizationErrorDomain";

@interface TMLAuthorizationViewController ()
@property (strong, nonatomic) NSURL *authorizationURL;
@property (strong, nonatomic) NSURL *deauthorizationURL;
@end

@implementation TMLAuthorizationViewController

- (instancetype)init {
    if (self = [super init]) {
        NSURL *gatewayURL = [[[TML sharedInstance] configuration] gatewayBaseURL];
        NSURL *url = [gatewayURL copy];
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.query = [NSString stringWithFormat:@"s=iOS&app_id=%@", TMLSharedConfiguration().applicationKey];
        self.authorizationURL = components.URL;
        
        url = [gatewayURL URLByAppendingPathComponent:@"logout"];
        components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.query = @"s=iOS";
        self.deauthorizationURL = components.URL;
    }
    return self;
}

#pragma mark - Authorizing

- (void)authorize {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.authorizationURL];
    [self.webView loadRequest:request];
}

- (void) setAccessToken:(NSString *)accessToken forUser:(TMLBasicUser *)user {
    [[TMLAuthorizationController sharedAuthorizationController] setAccessToken:accessToken
                                                                    forAccount:user.username];
    [self notifyDelegateWithGrantedAccessToken:accessToken user:user];
}

- (void) failAuthorizationWithError:(NSError *)error {
    [self notifyDelegateAuthorizationFailed:error];
}

#pragma mark - Deauthorizing

- (void)deauthorize {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.deauthorizationURL];
    [self.webView loadRequest:request];
}

#pragma mark - Notifying Delegate
- (void)notifyDelegateWithGrantedAccessToken:(NSString *)accessToken user:(TMLBasicUser *)user {
    id<TMLAuthorizationViewControllerDelegate>delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(authorizationViewController:didGrantAuthorization:)] == YES) {
        NSDictionary *authInfo = @{
                                   TMLAuthorizationAccessTokenKey: accessToken,
                                   TMLAuthorizationUserKey: user
                                   };
        [delegate authorizationViewController:self didGrantAuthorization:authInfo];
    }
}

- (void)notifyDelegateWithRevokedAccess {
    id<TMLAuthorizationViewControllerDelegate>delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(authorizationViewControllerDidRevokeAuthorization:)] == YES) {
        [delegate authorizationViewControllerDidRevokeAuthorization:self];
    }
}

- (void)notifyDelegateAuthorizationFailed:(NSError *)error {
    id<TMLAuthorizationViewControllerDelegate>delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(authorizationViewController:didFailToAuthorize:)] == YES) {
        [delegate authorizationViewController:self didFailToAuthorize:error];
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [super webView:webView didFinishNavigation:navigation];
    NSURL *url = webView.URL;
    if ([url isEqual:self.deauthorizationURL] == YES) {
        [self notifyDelegateWithRevokedAccess];
    }
}

- (void)postedUserInfo:(NSDictionary *)userInfo {
    [super postedUserInfo:userInfo];
    if ([@"unauthorized" isEqualToString:userInfo[@"status"]] == YES) {
        NSURL *authURL = [NSURL URLWithString:userInfo[@"url"]];
        if (authURL == nil) {
            TMLWarn(@"Unauthorized and don't know what to do...");
            return;
        }
        [self.webView loadRequest:[NSURLRequest requestWithURL:authURL]];
    }
    else if ([@"authorized" isEqualToString:userInfo[@"status"]] == YES) {
        NSString *accessToken = userInfo[@"access_token"];
        TMLTranslator *user = nil;
        NSError *error = nil;
        if (accessToken == nil) {
            TMLWarn(@"No authentication token found in posted message");
            error = [NSError errorWithDomain:TMLAuthorizationErrorDomain
                                        code:TMLAuthorizationUnexpectedResponseError
                                    userInfo:@{NSLocalizedDescriptionKey : @"No authentication token found in authorization response"}];
        }
        else {
            user = [TMLAPISerializer materializeObject:userInfo[@"translator"] withClass:[TMLTranslator class]];
            if (user == nil || [[NSNull null] isEqual:user] == YES) {
                TMLError(@"No translator indicated in auth response");
                user = nil;
                error = [NSError errorWithDomain:TMLAuthorizationErrorDomain
                                            code:TMLAuthorizationUnexpectedResponseError
                                        userInfo:@{NSLocalizedDescriptionKey : @"No translator description found in authorization response"}];
            }
        }
        if (user != nil) {
            [self setAccessToken:accessToken forUser:user];
        }
        else {
            if (error == nil) {
                error = [NSError errorWithDomain:TMLAuthorizationErrorDomain
                                            code:TMLAuthorizationUnknownError
                                        userInfo:nil];
            }
            [self notifyDelegateAuthorizationFailed:error];
        }
    }
    else {
        TMLWarn(@"Unrecognized message posted");
    }
}

@end
