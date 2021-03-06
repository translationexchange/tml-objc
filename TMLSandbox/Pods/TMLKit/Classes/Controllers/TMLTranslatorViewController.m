/*
 *  Copyright (c) 2015 Translation Exchange, Inc. All rights reserved.
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


#import "MBProgressHUD.h"
#import "TML.h"
#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLTranslatorViewController.h"
#import "NSURL+TML.h"

@interface TMLTranslatorViewController ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSString *translationKey;

- (IBAction) reloadButtonPressed: (id) sender;
- (IBAction) backButtonPressed: (id) sender;
- (IBAction) nextButtonPressed: (id) sender;
- (IBAction) actionButtonPressed: (id) sender;

@end

@implementation TMLTranslatorViewController

- (instancetype)init {
    return [self initWithTranslationKey:nil];
}

- (instancetype)initWithTranslationKey:(NSString *)translationKey {
    if (self = [super init]) {
        self.translationKey = translationKey;
    }
    return self;
}

- (void) loadView {
    [super loadView];
    
    UIView *ourView = self.view;
    ourView.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f];
    
    self.title = TMLLocalizedString(@"Translate");
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:TMLLocalizedString(@"Done") style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload:)];
    self.navigationItem.rightBarButtonItem = reloadButton;

    UIWebView *webView = [[UIWebView alloc] initWithFrame:ourView.bounds];
    [webView  setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    webView.delegate = self;
    self.webView = webView;
    [self.view addSubview:webView];
}

- (NSURL *) translationCenterURL {
    NSURL *url = nil;
    TMLApplication *app = [TML sharedInstance].application;
    NSString *host = [app.tools objectForKey: @"host"];
    if (host != nil) {
        url = [NSURL URLWithString:host];
    }
    else {
        url = [[[TML sharedInstance] configuration] translationCenterURL];
    }
    return [url URLByAppendingPathComponent:@"mobile"];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    TMLApplication *app = [[TML sharedInstance] application];
    TMLLanguage *lang = [[TML sharedInstance] currentLanguage];
    
    NSURL *url = [self translationCenterURL];
    
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:@{@"locale": lang.locale,
                                                                                 @"key": app.key}];

    if (self.translationKey) {
        query[@"translation_key"] = self.translationKey;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[url URLByAppendingQueryParameters:query]];
    
    if (request != nil) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [self.webView loadRequest:request];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *path = request.URL.path;
    if (path && [path rangeOfString:@"dismiss"].location != NSNotFound) {
        [self dismiss:webView];
        return NO;
    }
    else if ([path rangeOfString:@"logout"].location != NSNotFound) {
        NSString *origin = [[[request.URL scheme] stringByAppendingString:@"://"] stringByAppendingString:[request.URL host]];
        NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray* facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:origin]];
        for (NSHTTPCookie* cookie in facebookCookies) {
            [cookies deleteCookie:cookie];
        }
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (IBAction) backButtonPressed: (id) sender {
    [self.webView goBack];
}

- (IBAction) nextButtonPressed: (id) sender {
    [self.webView goForward];
}

- (IBAction) actionButtonPressed: (id) sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self.webView.request URL] absoluteString]]];
}

- (IBAction)reloadButtonPressed:(id)sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self reload:sender];
}

-(IBAction)dismiss:(id)sender {
    [[TML sharedInstance] reloadLocalizationData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)reload:(id)sender {
    [self signoutIfError];
    [self.webView reload];
}

- (void)signoutIfError {
    if ([NSThread isMainThread] == NO) {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
        return;
    }
    
    UIWebView *webView = self.webView;
    @try {
        [webView stringByEvaluatingJavaScriptFromString:@"(function(){ var i=document.createNodeIterator(document.body, NodeFilter.SHOW_COMMENT); var n=null; while (n = i.nextNode()) {if (n.textContent.match(\"public/500.html\")) { document.location.href = document.location.origin + \"/logout\"; } } })()"];
    }
    @catch(NSException *e) {
        TMLDebug(@"Error signing out from translation center: %@", e);
    }
}

@end
