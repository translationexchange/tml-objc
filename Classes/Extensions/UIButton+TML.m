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

#import "NSAttributedString+TML.h"
#import "NSObject+TML.h"
#import "NSString+TML.h"
#import "TML.h"
#import "UIButton+TML.h"
#import "TMLTranslationKey.h"
#import "TMLBundle.h"

@implementation UIButton (TML)

- (void)localizeWithTML {
    [super localizeWithTML];
    NSArray *states = @[
        @(UIControlStateNormal),
        @(UIControlStateHighlighted),
        @(UIControlStateDisabled),
        @(UIControlStateSelected),
        @(UIControlStateApplication)
    ];
    
    for (NSNumber *state in states) {
        UIControlState controlState = [state integerValue];
        NSAttributedString *attributedTitle = [self attributedTitleForState:controlState];
        NSString *tmlString = nil;
        NSDictionary *tokens = nil;
        id localizedString = nil;
        if (attributedTitle.length > 0) {
            if (controlState == UIControlStateNormal
                || [attributedTitle isEqualToAttributedString:[self attributedTitleForState:UIControlStateNormal]] == NO) {
                tmlString = [attributedTitle tmlAttributedString:&tokens];
                localizedString = TMLLocalizedAttributedString(tmlString, tokens);
                [self setAttributedTitle:(NSAttributedString *)localizedString forState:[state integerValue]];
            }
        }
        else {
            NSString *title = [self titleForState:controlState];
            if (controlState == UIControlStateNormal
                || [title isEqualToString:[self titleForState:UIControlStateNormal]] == NO) {
                tmlString = title;
                localizedString = TMLLocalizedString(tmlString);
                [self setTitle:(NSString *)localizedString forState:[state integerValue]];
            }
        }
        
        TMLTranslationKey *translationKey = nil;
        UILabel *titleLabel = self.titleLabel;
        if (titleLabel != nil && tmlString != nil) {
            translationKey = [[TMLTranslationKey alloc] init];
            translationKey.label = tmlString;
            translationKey.locale = [TML defaultLocale];
            
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            info[TMLTranslationKeyInfoKey] = translationKey;
            if (tokens != nil) {
                info[TMLTokensInfoKey] = tokens;
            }
            if (localizedString != nil) {
                info[TMLLocalizedStringInfoKey] = localizedString;
            }
            
            NSString *reuseIdentifier = (attributedTitle.length > 0) ? @"attributedText" : @"text";
            reuseIdentifier = [NSString stringWithFormat:@"%@-%@", reuseIdentifier, state];
            [titleLabel registerTMLInfo:info forReuseIdentifier:reuseIdentifier];
        }
    }
}

#pragma mark - TMLReusableLocalization

- (void)updateTMLLocalizedStringWithInfo:(NSDictionary *)info
                   forReuseIdentifier:(NSString *)reuseIdentifier
{
    NSString *keyPath = nil;
    id newString = nil;
    NSInteger state = 0;
    if ([reuseIdentifier hasPrefix:@"attributedText-"] == YES
        || [reuseIdentifier hasPrefix:@"text-"] == YES) {
        NSArray *parts = [reuseIdentifier componentsSeparatedByString:@"-"];
        keyPath = [parts objectAtIndex:0];
        state = [[parts objectAtIndex:1] integerValue];
        newString = info[TMLLocalizedStringInfoKey];
    }
    if (keyPath != nil
        && newString != nil) {
        if ([keyPath isEqualToString:@"attributedText"] == YES) {
            [self setAttributedTitle:newString forState:state];
        }
        else {
            [self setTitle:newString forState:state];
        }
    }
    else {
        [super updateTMLLocalizedStringWithInfo:info
                             forReuseIdentifier:reuseIdentifier];
    }
}

@end
