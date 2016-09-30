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
#import "NSObject+TML.h"
#import "NSURL+TML.h"
#import "TML.h"
#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLTranslation.h"
#import "TMLTranslatorViewController.h"
#import <WebKit/WebKit.h>

@interface TMLTranslatorViewController ()

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
        self.title = TMLLocalizedString(@"Translate");
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:TMLLocalizedString(@"Done") style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
        self.navigationItem.leftBarButtonItem = doneButton;
        
        UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload:)];
        self.navigationItem.rightBarButtonItem = reloadButton;
        
        [self translate];
    }
    return self;
}

- (NSURL *) translationCenterURL {
    TML *tml = [TML sharedInstance];
    TMLApplication *app = tml.application;
    NSURL *url = [app translationCenterURLForTranslationKey:self.translationKey locale:tml.currentLocale];
    return url;
}

- (void)translate {
    NSURL *url = [self translationCenterURL];
    NSURLRequest *request = (url == nil) ? nil : [NSURLRequest requestWithURL:url];
    if (request != nil) {
        [self.webView loadRequest:request];
    }
}

- (IBAction) backButtonPressed: (id) sender {
    [self.webView goBack];
}

- (IBAction) nextButtonPressed: (id) sender {
    [self.webView goForward];
}

- (IBAction) actionButtonPressed: (id) sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self.webView URL] absoluteString]]];
}

- (IBAction)reloadButtonPressed:(id)sender {
    [self reload:sender];
}

-(IBAction)dismiss:(id)sender {
    [[TML sharedInstance] reloadLocalizationData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)reload:(id)sender {
    [self.webView reload];
}

#pragma mark - TMLWebViewController
- (void)postedUserInfo:(NSDictionary *)userInfo {
    [super postedUserInfo:userInfo];
    if (userInfo == nil) {
        return;
    }
    
    NSString *action = userInfo[@"action"];
    if ([@"next" isEqualToString:action] == YES) {
        [self dismiss:nil];
        return;
    }
    
    NSString *locale = userInfo[@"target_locale"];
    NSString *label = userInfo[@"translation"];
    NSString *key = userInfo[@"translation_key"];
    if (locale == nil || label == nil || key == nil) {
        TMLDebug(@"No translation data found");
        return;
    }
    
    TML *tml = [TML sharedInstance];
    TMLTranslation *translation = [TMLTranslation translationWithKey:key locale:locale label:label];
    [tml addTranslation:translation locale:locale];
    [tml updateReusableTMLStrings];
    [tml reloadLocalizationData];
}

@end
