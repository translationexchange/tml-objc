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

#import <UIKit/UIKit.h>
#import "UIViewController+Tml.h"
#import "Tml.h"
#import "TmlTranslatorViewController.h"

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <float.h>

NSString const *TmlViewData = @"TmlViewData";
NSString const *TmlKeyData = @"TmlKeyData";
NSString const *TmlViewTapRecognizer = @"TmlViewTapRecognizer";

@implementation UIViewController (Tml)

- (NSString *) tr8nSourceKey {
    return NSStringFromClass([self class]);
}

- (NSDictionary *) tr8nPrepareOptions {
    return [self tr8nPrepareOptions: @{}];
}

- (NSDictionary *) tr8nPrepareOptions: (NSDictionary *) options {
    if (!options) options = @{};
    NSMutableDictionary *opts = [NSMutableDictionary dictionaryWithDictionary:options];
    if (![opts objectForKey:@"source"] && ![Tml blockOptionForKey:@"source"] && [self tr8nSourceKey])
        [opts setObject: [self tr8nSourceKey] forKey:@"source"];
    return opts;
}

- (TmlLanguage *) tr8nDefaultLanguage {
    return [[Tml sharedInstance] defaultLanguage];
}

- (TmlLanguage *) tr8nCurrentLanguage {
    return [[Tml sharedInstance] currentLanguage];
}

- (TmlApplication *) tr8nCurrentApplication {
    return [[Tml sharedInstance] currentApplication];
}

- (NSObject *) tr8nCurrentUser {
    return [[Tml sharedInstance] currentUser];
}

- (void) setTextValue: (NSObject *) value toField: (id) field {
    if ([field isKindOfClass: UILabel.class]) {
        if ([value isKindOfClass: NSAttributedString.class])
            [((UILabel *) field) setAttributedText: (NSAttributedString *) value];
        else if ([value isKindOfClass: NSString.class])
            [((UILabel *) field) setText: (NSString *) value];
    } else if ([field isKindOfClass: UITextView.class]) {
        if ([value isKindOfClass: NSAttributedString.class])
            [((UITextView *) field) setAttributedText: (NSAttributedString *) value];
        else if ([value isKindOfClass: NSString.class])
            [((UITextView *) field) setText: (NSString *) value];
    } else if ([field isKindOfClass: UINavigationItem.class]) {
        if ([value isKindOfClass: NSAttributedString.class]) {
            UINavigationItem *navItem = (UINavigationItem *) field;
            UILabel *label = [[UILabel alloc] init];
            [label setAttributedText: (NSAttributedString *) value];
            [navItem setTitleView:label];
        } else if ([value isKindOfClass: NSString.class])
            [((UINavigationItem *) field) setTitle: (NSString *) value];
    }
}

- (NSValue *) viewHashKey: (UIView *) view {
    return [NSValue valueWithNonretainedObject:view];
}

- (NSDictionary *) originalViewValueForKey: (NSValue *) key {
    NSMutableDictionary *tr8nViewData = objc_getAssociatedObject(self, &TmlViewData);
    return [tr8nViewData objectForKey:key];
}

- (void) setOriginalViewValue: (NSObject *) value forKey: (NSValue *) key {
    NSMutableDictionary *tr8nViewData = objc_getAssociatedObject(self, &TmlViewData);
    if (tr8nViewData == nil) {
        tr8nViewData = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &TmlViewData, tr8nViewData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [tr8nViewData setObject:value forKey:key];
}

- (NSString *) translationKeyForKey: (NSValue *) key {
    NSMutableDictionary *tr8nKeyData = objc_getAssociatedObject(self, &TmlKeyData);
    return [tr8nKeyData objectForKey:key];
}

- (void) setTranslationKey: (NSString *) value forKey: (NSValue *) key {
    NSMutableDictionary *tr8nKeyData = objc_getAssociatedObject(self, &TmlKeyData);
    if (tr8nKeyData == nil) {
        tr8nKeyData = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &TmlKeyData, tr8nKeyData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [tr8nKeyData setObject:value forKey:key];
}

- (NSDictionary *) dataForView: (UIView *) view  withDefault: (NSDictionary *(^)()) defaultData {
    NSValue *key = [self viewHashKey:view];
    
    NSDictionary *data = [self originalViewValueForKey:key];
    if (data == nil) {
        data = defaultData();
        [self setOriginalViewValue:data forKey:key];
    }
    return data;
}

- (NSDictionary *) dataForObject: (NSObject *) object  withDefault: (NSDictionary *(^)()) defaultData {
    NSValue *key = [NSValue valueWithNonretainedObject:object];
    
    NSDictionary *data = [self originalViewValueForKey:key];
    if (data == nil) {
        data = defaultData();
        [self setOriginalViewValue:data forKey:key];
    }
    return data;
}

- (void) translateLabel: (UILabel *) label {
    NSDictionary *data = [self dataForView:label withDefault:^NSDictionary *{
        return @{
            @"text": label.text,
        };
    }];
    
    if ([[data objectForKey:@"text"] length] > 0) {
        [self setTranslationKey:TmlTranslationKey([data objectForKey:@"text"], @"") forKey:[self viewHashKey:label]];
        label.text = TmlLocalizedStringWithOptions([data objectForKey:@"text"], [self tr8nPrepareOptions]);
    }
    
    [self addInAppTranslatorGestureRecognizer: label];
}

- (void) translateButton: (UIButton *) button {
    NSDictionary *data = [self dataForView:button withDefault:^NSDictionary *{
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        if ([button titleForState:UIControlStateNormal]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_normal"];
        if ([button titleForState:UIControlStateHighlighted]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_highlighted"];
        if ([button titleForState:UIControlStateDisabled]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_disabled"];
        if ([button titleForState:UIControlStateSelected]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_selected"];
        if ([button titleForState:UIControlStateApplication]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_application"];
        if ([button titleForState:UIControlStateReserved]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_reserved"];
        return data;
    }];
    
    if ([data objectForKey:@"text_normal"]) [button setTitle:TmlLocalizedStringWithOptions([data objectForKey:@"text_normal"], [self tr8nPrepareOptions]) forState:UIControlStateNormal];
    if ([data objectForKey:@"text_highlighted"]) [button setTitle:TmlLocalizedStringWithOptions([data objectForKey:@"text_normal"], [self tr8nPrepareOptions]) forState:UIControlStateHighlighted];
    if ([data objectForKey:@"text_disabled"]) [button setTitle:TmlLocalizedStringWithOptions([data objectForKey:@"text_normal"], [self tr8nPrepareOptions]) forState:UIControlStateDisabled];
    if ([data objectForKey:@"text_selected"]) [button setTitle:TmlLocalizedStringWithOptions([data objectForKey:@"text_normal"], [self tr8nPrepareOptions]) forState:UIControlStateSelected];
    if ([data objectForKey:@"text_application"]) [button setTitle:TmlLocalizedStringWithOptions([data objectForKey:@"text_normal"], [self tr8nPrepareOptions]) forState:UIControlStateApplication];
    if ([data objectForKey:@"text_reserved"]) [button setTitle:TmlLocalizedStringWithOptions([data objectForKey:@"text_normal"], [self tr8nPrepareOptions]) forState:UIControlStateReserved];
    
    [self addInAppTranslatorGestureRecognizer: button];
}

- (void) translateTextField: (UITextField *) textField {
    NSDictionary *data = [self dataForView:textField withDefault:^NSDictionary *{
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        if (textField.placeholder) [data setObject:textField.placeholder forKey:@"placeholder"];
        return data;
    }];
    
    if ([[data objectForKey:@"placeholder"] length] > 0) {
        textField.placeholder = TmlLocalizedStringWithOptions([data objectForKey:@"placeholder"], [self tr8nPrepareOptions]);
    }
    
    [self addInAppTranslatorGestureRecognizer: textField];
}

- (void) translateBarButtonItem: (UIBarButtonItem *) barButtonItem {
    NSDictionary *data = [self dataForObject:barButtonItem withDefault:^NSDictionary *{
        return @{
                 @"title": barButtonItem.title
        };
    }];
    
    if ([[data objectForKey:@"title"] length] > 0) {
        barButtonItem.title = TmlLocalizedStringWithOptions([data objectForKey:@"title"], [self tr8nPrepareOptions]);
    }
}

- (void) translateNavigationItem: (UINavigationItem *) navigationItem {
    NSDictionary *data = [self dataForObject:navigationItem withDefault:^NSDictionary *{
        return @{
                 @"title": navigationItem.title
        };
    }];
    
    if ([[data objectForKey:@"title"] length] > 0) {
        navigationItem.title = TmlLocalizedStringWithOptions([data objectForKey:@"title"], [self tr8nPrepareOptions]);
    }
}

- (void) translateSearchBar: (UISearchBar *) searchBar {
    NSDictionary *data = [self dataForObject:searchBar withDefault:^NSDictionary *{
        return @{
                 @"text": searchBar.text,
                 @"placeholder": searchBar.placeholder,
                 @"prompt": searchBar.prompt
        };
    }];
    
    if ([[data objectForKey:@"text"] length] > 0) {
        searchBar.text = TmlLocalizedStringWithOptions([data objectForKey:@"text"], [self tr8nPrepareOptions]);
    }
    
    if ([[data objectForKey:@"placeholder"] length] > 0) {
        searchBar.placeholder = TmlLocalizedStringWithOptions([data objectForKey:@"placeholder"], [self tr8nPrepareOptions]);
    }
    
    if ([[data objectForKey:@"prompt"] length] > 0) {
        searchBar.prompt = TmlLocalizedStringWithOptions([data objectForKey:@"prompt"], [self tr8nPrepareOptions]);
    }
}

- (void) translateView: (UIView *) view {
    if (view == nil) return;
    
    // TmlDebug(@"Translating: %@", NSStringFromClass([view class]));

    if ([view isKindOfClass:UILabel.class])
        [self translateLabel:(UILabel *) view];
    else if ([view isKindOfClass:UIButton.class])
        [self translateButton:(UIButton *) view];
    else if ([view isKindOfClass:UITextField.class])
        [self translateTextField:(UITextField *) view];
    else if ([view isKindOfClass:UIBarButtonItem.class])
        [self translateBarButtonItem:(UIBarButtonItem *) view];
    else if ([view isKindOfClass:UINavigationItem.class])
        [self translateNavigationItem:(UINavigationItem *) view];
    else if ([view isKindOfClass:UISearchBar.class])
        [self translateSearchBar:(UISearchBar *) view];
    else if ([view isKindOfClass:UITableView.class]) {
        UITableView *tableView = (UITableView *) view;
        for (int i=0; i<[tableView numberOfSections]; i++) {
            for (int j=0; j<[tableView numberOfRowsInSection:i]; j++) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                for (UIView *view in cell.subviews) {
                    [self translateView:view];
                }
            }
        }
    } else {
        for (UIView *subview in view.subviews) {
            [self translateView:subview];
        }
    }
}

- (void) translateView: (UIView *) view withLabel: (NSString *) label description: (NSString *) description tokens: (NSDictionary *) tokens options: (NSDictionary *) options {

    if (view == nil) return;
    
    // TmlDebug(@"Translating: %@", NSStringFromClass([view class]));

    NSString *text = nil;
    NSAttributedString *attributedText = nil;
    
    [self setTranslationKey:TmlTranslationKey(label, description) forKey:[self viewHashKey:view]];
    
    if ([label rangeOfString:@"["].location != NSNotFound) {
        attributedText = TmlLocalizedAttributedStringWithDescriptionAndTokensAndOptions(label, description, tokens, [self tr8nPrepareOptions:options]);
    } else {
        text = TmlLocalizedStringWithDescriptionAndTokensAndOptions(label, description, tokens, [self tr8nPrepareOptions:options]);
    }
        
    if ([view isKindOfClass:UILabel.class]) {
        UILabel *lbl = (UILabel *) view;
        if (attributedText) lbl.attributedText = attributedText;
        if (text) lbl.text = text;
    } else if ([view isKindOfClass: UIButton.class]) {
        UIButton *btn = (UIButton *) view;
        if (attributedText) [btn setAttributedTitle:attributedText forState:UIControlStateNormal];
        if (text) [btn setTitle:text forState:UIControlStateNormal];
    } else if ([view isKindOfClass: UITextField.class]) {
        UITextField *fld = (UITextField *) view;
        if (attributedText) [fld setAttributedPlaceholder:attributedText];
        if (text) [fld setPlaceholder:text];
    }
    
    [self addInAppTranslatorGestureRecognizer: view];
}

- (void) addInAppTranslatorGestureRecognizer:(UIView *) view {
    for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]])
            [view removeGestureRecognizer:recognizer];
    }
    
    if (![Tml configuration].inContextTranslatorEnabled) return;
    
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePressAndHold:)];
    view.userInteractionEnabled = YES;
    [view addGestureRecognizer:gestureRecognizer];
}

- (void) handlePressAndHold:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSValue *fieldKey = [self viewHashKey:recognizer.view];
        NSDictionary *originalData = [self originalViewValueForKey: fieldKey];
        NSString *translationKey = nil;

        if (!originalData)
            translationKey = [self translationKeyForKey: fieldKey];
        else if ([recognizer.view isKindOfClass: UILabel.class]) {
            translationKey = [TmlTranslationKey generateKeyForLabel:[originalData valueForKey:@"text"]];
        } else if ([recognizer.view isKindOfClass: UIButton.class]) {
            translationKey = [TmlTranslationKey generateKeyForLabel:[originalData valueForKey:@"text_normal"]];
        } else if ([recognizer.view isKindOfClass: UITextField.class]) {
            translationKey = [TmlTranslationKey generateKeyForLabel:[originalData valueForKey:@"placeholder"]];
        }
        
        if (translationKey)
            [TmlTranslatorViewController translateFromController: self withOptions:@{@"translation_key": translationKey}];
    }
}

@end
