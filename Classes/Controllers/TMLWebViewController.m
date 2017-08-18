/*
 *  Copyright (c) 2017 Translation Exchange, Inc. All rights reserved.
 *
 *  _______                  _       _   _             ______          _
 * |__   __|                | |     | | (_)           |  ____|        | |
 *    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
 *    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
 *    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
 *    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
 *                                                                                        __/ |
 *                                                                                       |___/
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */


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
        webView.UIDelegate = self;
        
        self.webView = webView;
        UIView *ourView = self.view;
        [ourView addSubview:webView];
    }
    return self;
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"No"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(NO);
                                                      }]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Yes"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(YES);
                                                      }]];

    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor whiteColor];
    self.view = view;
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
    
    NSDictionary *result = nil;
    if ([message.body isKindOfClass:[NSDictionary class]] == YES) {
        result = message.body;
    }
    else {
        NSData *bodyData = [[NSData alloc] initWithBase64EncodedString:message.body options:0];
        NSString *body = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        if (body != nil) {
            result = [body tmlJSONObject];
        }
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
