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

@interface TMLAuthorizationViewController ()
@property (strong, nonatomic) NSURL *authorizationURL;
@property (strong, nonatomic) NSURL *deauthorizationURL;
@end

@implementation TMLAuthorizationViewController

- (instancetype)init {
    if (self = [super init]) {
        NSURL *gatewayURL = [[[TML sharedInstance] configuration] gatewayURL];
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
        if (accessToken == nil) {
            TMLWarn(@"No authentication token found in posted message");
        }
        else {
            TML *tml = [TML sharedInstance];
            TMLAPIClient *apiClient = [[TMLAPIClient alloc] initWithBaseURL:tml.configuration.apiURL
                                                                accessToken:accessToken];
            TMLTranslator *user = [TMLAPISerializer materializeObject:userInfo[@"translator"] withClass:[TMLTranslator class]];
            [self setAccessToken:accessToken forUser:user];
        }
    }
    else {
        TMLWarn(@"Unrecognized message posted");
    }
}

@end
