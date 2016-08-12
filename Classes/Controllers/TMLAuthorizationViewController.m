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
#import "TMLAuthorizationViewController.h"
#import "TMLUser.h"
#import <WebKit/WebKit.h>

NSString * const TMLAuthorizationAccessTokenKey = @"access_token";
NSString * const TMLAuthorizationUserKey = @"user";

@interface TMLAuthorizationViewController ()<WKScriptMessageHandler, WKNavigationDelegate>
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSURL *authorizationURL;
@property (strong, nonatomic) NSURL *deauthorizationURL;
@end

@implementation TMLAuthorizationViewController

- (instancetype)init {
    if (self = [super init]) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.backgroundColor = [UIColor whiteColor];
        self.view = view;
        
        NSURL *gatewayURL = [[[TML sharedInstance] configuration] gatewayURL];
        NSURL *url = [gatewayURL copy];
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.query = [NSString stringWithFormat:@"s=iOS&app_id=%@", TMLSharedConfiguration().applicationKey];
        self.authorizationURL = components.URL;
        
        url = [gatewayURL URLByAppendingPathComponent:@"logout"];
        components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.query = @"s=iOS";
        self.deauthorizationURL = components.URL;
        
        WKUserContentController *webContentController = [[WKUserContentController alloc] init];
        [webContentController addScriptMessageHandler:self name:@"tmlMessageHandler"];
        
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:@"var tmlMessageHandler = window.webkit.messageHandlers.tmlMessageHandler;" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [webContentController addUserScript:userScript];
        
        WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
        webViewConfig.userContentController = webContentController;
        
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webViewConfig];
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        webView.navigationDelegate = self;
        self.webView = webView;
        [view addSubview:webView];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
}

#pragma mark - Authorizing

- (void)authorize {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.authorizationURL];
    [self.webView loadRequest:request];
}

- (void) setAccessToken:(NSString *)accessToken forUser:(TMLUser *)user {
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
- (void)notifyDelegateWithGrantedAccessToken:(NSString *)accessToken user:(TMLUser *)user {
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
    NSURL *url = webView.URL;
    if ([url isEqual:self.deauthorizationURL] == YES) {
        [self notifyDelegateWithRevokedAccess];
    }
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (message.body == nil) {
        TMLDebug(@"No body in posted message");
        return;
    }
    
    NSData *bodyData = [[NSData alloc] initWithBase64EncodedString:message.body options:0];
    NSString *body = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    NSDictionary *result = nil;
    if (body != nil) {
        result = [body tmlJSONObject];
    }
    
    if (result == nil) {
        TMLDebug(@"Didn't find anything relevant in posted message");
        return;
    }
    
    if ([@"unauthorized" isEqualToString:result[@"status"]] == YES) {
        NSURL *authURL = [NSURL URLWithString:result[@"url"]];
        if (authURL == nil) {
            TMLWarn(@"Unauthorized and don't know what to do...");
            return;
        }
        [self.webView loadRequest:[NSURLRequest requestWithURL:authURL]];
    }
    else if ([@"authorized" isEqualToString:result[@"status"]] == YES) {
        NSString *accessToken = result[@"access_token"];
        if (accessToken == nil) {
            TMLWarn(@"No authentication token found in posted message");
        }
        else {
            TML *tml = [TML sharedInstance];
            TMLAPIClient *apiClient = [[TMLAPIClient alloc] initWithBaseURL:tml.configuration.apiURL
                                                                accessToken:accessToken];
            TMLUser *user = [TMLAPISerializer materializeObject:result[@"translator"] withClass:[TMLUser class]];
            [self setAccessToken:accessToken forUser:user];
        }
    }
    else {
        TMLWarn(@"Unrecognized message posted");
    }
}

@end
