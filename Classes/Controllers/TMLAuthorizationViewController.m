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
@end

@implementation TMLAuthorizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *ourView = self.view;
    CGRect ourBounds = ourView.bounds;
    UIWebView *webView = [[UIWebView alloc] initWithFrame:ourBounds];
    webView.delegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView = webView;
    [ourView addSubview:webView];
    
    self.title = TMLLocalizedString(@"Sign in");
    
    [self authorize];
}

- (void)authorize {
    NSURL *gatewayURL = [[[TML sharedInstance] configuration] gatewayURL];
    NSURL *url = [gatewayURL URLByAppendingPathComponent:@"authorize"];
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.query = @"s=iOS";
    NSURLRequest *request = [NSURLRequest requestWithURL:[components URL]];
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
    NSURL *responseURL = [[[[[TML sharedInstance] configuration] gatewayURL] URLByAppendingPathComponent:@"authorize"] URLByAppendingPathComponent:@"response"];
    NSURL *requestURL = request.URL;
    if ([requestURL.host isEqualToString:responseURL.host] == YES
        && [requestURL.path isEqualToString:responseURL.path] == YES) {
        id<TMLAuthorizationViewControllerDelegate>delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(authorizationViewController:didAuthorize:)] == YES) {
            NSDictionary *authInfo = nil;
            TMLAuthorizationController *authController = [TMLAuthorizationController new];
#if MOCK_AUTH
            TMLTranslator *translator = [TMLTranslator new];
            translator.userID = @"1";
            translator.firstName = @"Mock";
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
            }
        }
        return YES;
    }
    
#if MOCK_AUTH
    [webView loadRequest:[NSURLRequest requestWithURL:responseURL]];
    return NO;
#else
    return YES;
#endif
}

@end
