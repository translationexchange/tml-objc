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

#import "ApplicationViewController.h"
#import "IIViewDeckController.h"

@interface ApplicationViewController () {
    BOOL _observingTMLNotifications;
}

@end

@implementation ApplicationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self localize];
    [self setupTMLNotificationObserving];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self teardownTMLNotificationObserving];
    }
    else {
        [self setupTMLNotificationObserving];
    }
}

#pragma mark - Notifications
- (void)setupTMLNotificationObserving {
    if (_observingTMLNotifications == YES) {
        return;
    }
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(tmlTranslationsLoaded:)
                               name:TMLLanguageChangedNotification
                             object:nil];
    [notificationCenter addObserver:self selector:@selector(tmlBundleDidChange:)
                               name:TMLLocalizationDataChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(tmlDidFinishSync:)
                               name:TMLDidFinishSyncNotification
                             object:nil];
    _observingTMLNotifications = YES;
}

- (void)teardownTMLNotificationObserving {
    if (_observingTMLNotifications == NO) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _observingTMLNotifications = NO;
}

- (IBAction)toggleMenu:(id)sender {
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

- (void)localize {
    TMLLocalizeView(self.view);
}

- (void)tmlTranslationsLoaded:(NSNotification *)aNotification {
    [self localize];
}

- (void)tmlBundleDidChange:(NSNotification *)aNotification {
    [self localize];
}

- (void)tmlDidFinishSync:(NSNotification *)aNotification {
    [self localize];
}

@end

