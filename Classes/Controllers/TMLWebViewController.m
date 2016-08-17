//
//  TMLWebViewController.m
//  TMLKit
//
//  Created by Pasha on 8/16/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLWebViewController.h"

@interface TML(Private)
- (void)presentAlertController:(UIAlertController *)alertController;
@end

@interface TMLWebViewController ()
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation TMLWebViewController

- (instancetype)init {
    if (self = [super init]) {
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
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.webView.frame = self.view.bounds;
    [self.view addSubview:self.webView];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
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
    
    if ([@"error" isEqualToString:result[@"status"]] == YES) {
        NSString *message = result[@"message"];
        if (message == nil) {
            message = @"Unknown Error";
        }
        [self postedErrorMessage:message];
    }
    else {
        [self postedUserInfo:result];
    }
}

#pragma mark - Message post handling

- (void)postedErrorMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:TMLLocalizedString(@"Error") message:message preferredStyle:UIAlertControllerStyleAlert];
    [[TML sharedInstance] presentAlertController:alert];
}

- (void)postedUserInfo:(NSDictionary *)userInfo {
    TMLDebug(@"WebView posted message: %@", userInfo);
}

@end
