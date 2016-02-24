//
//  TMLAuthorizationViewController.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLAuthorizationViewController.h"

#define MOCK_AUTH 1

@interface TMLAuthorizationViewController ()<UIWebViewDelegate>
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSURL *authorizationURL;
@property (strong, nonatomic) NSURL *authorizationCompleteURL;
@property (strong, nonatomic) NSURL *deauthorizationURL;
@property (strong, nonatomic) NSURL *deauthorizationCompleteURL;
@end

@implementation TMLAuthorizationViewController

- (instancetype)init {
    if (self = [super init]) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.backgroundColor = [UIColor whiteColor];
        self.view = view;
        
        NSURL *gatewayURL = [[[TML sharedInstance] configuration] gatewayURL];
        NSURL *url = [gatewayURL URLByAppendingPathComponent:@"authorize"];
        self.authorizationCompleteURL = [url URLByAppendingPathComponent:@"response"];
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.query = @"s=iOS";
        self.authorizationURL = components.URL;
        
        url = [gatewayURL URLByAppendingPathComponent:@"logout"];
        self.deauthorizationCompleteURL = [url URLByAppendingPathComponent:@"response"];
        components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.query = @"s=iOS";
        self.deauthorizationURL = components.URL;
        
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        webView.delegate = self;
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.webView = webView;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
}

- (void)authorize {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.authorizationURL];
    [self.webView loadRequest:request];
}

- (void)deauthorize {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.deauthorizationURL];
    [self.webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    TMLError(@"Error loading authorization controller: %@", error);
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *authorizationCompleteURL = self.authorizationCompleteURL;
    NSURL *deauthorizationCompleteURL = self.deauthorizationCompleteURL;
    NSURL *requestURL = request.URL;
    
    if ([requestURL.host isEqualToString:authorizationCompleteURL.host] == NO
        && [requestURL.host isEqualToString:deauthorizationCompleteURL.host] == NO) {
        return NO;
    }
    
    id<TMLAuthorizationViewControllerDelegate>delegate = self.delegate;
    if ([requestURL.path isEqualToString:authorizationCompleteURL.path] == YES) {
        if ([delegate respondsToSelector:@selector(authorizationViewController:didAuthorize:)] == YES) {
            NSDictionary *authInfo = nil;
            TMLAuthorizationController *authController = [TMLAuthorizationController new];
#if MOCK_AUTH
            TMLTranslator *translator = [TMLTranslator new];
            translator.userID = @"1";
            translator.firstName = @"Cookie";
            translator.lastName = @"Monster";
            translator.displayName = @"I am Cookie Monster";
            translator.inlineTranslationAllowed = YES;
            translator.mugshotURL = [NSURL URLWithString:@"http://images.clipartpanda.com/cookie-monster-clip-art-cookiecookiecookie.jpg"];
            authInfo = @{
                         TMLAuthorizationStatusKey: TMLAuthorizationStatusAuthorized,
                         TMLAuthorizationAccessTokenKey: @"048f31c32dc56be8c81affad60a25cf64dd03d4944efbb31cdf8cac6d18b18b9",
                         TMLAuthorizationTranslatorKey: translator
                         };
            [authController saveAuthorizationInfo:authInfo];
#else
            authInfo = [authController authorizationInfoFromSharedCookieJar];
#endif
            if (authInfo != nil) {
                [delegate authorizationViewController:self didAuthorize:authInfo];
                [[NSNotificationCenter defaultCenter] postNotificationName:TMLAuthorizationGrantedNotification
                                                                    object:nil
                                                                  userInfo:authInfo];
            }
        }
        return YES;
    }
    else if ([requestURL.path isEqualToString:deauthorizationCompleteURL.path] == YES) {
        if ([delegate respondsToSelector:@selector(authorizationViewControllerDidRevokeAuthorization:)] == YES) {
            TMLAuthorizationController *authController = [TMLAuthorizationController new];
            [authController removeStoredAuthorizationInfo];
            [delegate authorizationViewControllerDidRevokeAuthorization:self];
            [[NSNotificationCenter defaultCenter] postNotificationName:TMLAuthorizationRevokedNotification
                                                                object:nil
                                                              userInfo:nil];
        }
        return YES;
    }
    
#if MOCK_AUTH
    if ([requestURL.path isEqualToString:self.authorizationURL.path] == YES) {
        [webView loadRequest:[NSURLRequest requestWithURL:authorizationCompleteURL]];
    }
    else if ([requestURL.path isEqualToString:self.deauthorizationURL.path] == YES) {
        [webView loadRequest:[NSURLRequest requestWithURL:deauthorizationCompleteURL]];
    }
    return NO;
#else
    return YES;
#endif
}

@end
