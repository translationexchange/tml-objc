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

NSString * const TMLAuthorizationStatusKey = @"status";
NSString * const TMLAuthorizationStatusAuthorized = @"authorized";
NSString * const TMLAuthorizationAccessTokenKey = @"access_token";
NSString * const TMLAuthorizationTranslatorInfoKey = @"translator";
NSString * const TMLAuthorizationTranslatorIDKey = @"id";
NSString * const TMLAuthorizationTranslatorFirstNameKey = @"first_name";
NSString * const TMLAuthorizationTranslatorMugshotKey = @"mugshot";
NSString * const TMLAuthorizationTranslatorInlineModeKey = @"inline_mode";

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
            NSDictionary *userInfo = nil;
            NSString *appKey = [[[TML sharedInstance] configuration] applicationKey];
            NSString *authCookieName = [NSString stringWithFormat:@"trex_%@", appKey];
            NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
            NSHTTPCookie *authCookie;
            for (NSHTTPCookie *cookie in cookies) {
                if ([cookie.name isEqualToString:authCookieName] == YES) {
                    authCookie = cookie;
                    break;
                }
            }
            if (authCookie != nil) {
                NSString *cookieString = [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:authCookie.value
                                                                                                            options:0]
                                                               encoding:NSUTF8StringEncoding];
                userInfo = [cookieString tmlJSONObject];
            }
            if (userInfo != nil) {
                [delegate authorizationViewController:self didAuthorize:userInfo];
            }
        }
    }
    return YES;
}

@end
