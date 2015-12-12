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
#import "UILabel+TML.h"
#import "UIResponder+TML.h"
#import "TMLTranslationKey.h"

@interface UILabel()
@end

@implementation UILabel (TML)

- (NSArray *)tmlTranslationKeys {
    NSString *property = nil;
    if (self.attributedText.length > 0) {
        property = @"attributedText";
    }
    else if (self.text.length > 0) {
        property = @"text";
    }
    
    NSMutableArray *translationKeys = [NSMutableArray array];
    if (property != nil) {
        // first lookup the key in the registry
        NSDictionary *registry = [self tmlRegistry];
        NSDictionary *payload = registry[property];
        TMLTranslationKey *translationKey = payload[TMLRegistryTranslationKeyName];
        if (translationKey != nil) {
            [translationKeys addObject:translationKey.key];
        }
        // if nothing in the registry, lookup translation key by localized string
        else {
            NSMutableArray *labelsToMatch = [NSMutableArray array];
            id label = [self valueForKey:property];
            if ([label isKindOfClass:[NSAttributedString class]] == YES) {
                [labelsToMatch addObject:[label tmlAttributedString:nil]];
                [labelsToMatch addObject:[(NSAttributedString *)label string]];
            }
            else if ([label isKindOfClass:[NSString class]] == YES) {
                [labelsToMatch addObject:label];
            }
            
            NSMutableArray *localesToCheck = [NSMutableArray array];
            NSString *currentLocale = [TML currentLocale];
            if (currentLocale != nil) {
                [localesToCheck addObject:currentLocale];
            }
            NSString *defaultLocale = [TML defaultLocale];
            if (defaultLocale != nil && [defaultLocale isEqualToString:currentLocale] == NO) {
                [localesToCheck addObject:defaultLocale];
            }
            
            NSArray *matchingKeys = nil;
            for (NSString *searchLabel in labelsToMatch) {
                for (NSString *locale in localesToCheck) {
                    matchingKeys = [[TML sharedInstance] translationKeysForString:searchLabel
                                                                           locale:locale];
                    if (matchingKeys.count > 0) {
                        break;
                    }
                }
            }
            
            if (matchingKeys.count > 0) {
                [translationKeys addObjectsFromArray:matchingKeys];
            }
        }
    }
    return [translationKeys copy];
}

- (void)localizeWithTML {
    [super localizeWithTML];
    NSDictionary *tokens = nil;
    NSString *tmlAttributedString = [self.attributedText tmlAttributedString:&tokens];
    if ([tmlAttributedString tmlContainsDecoratedTokens] == YES) {
        self.attributedText = TMLLocalizedAttributedString(tmlAttributedString, tokens, @"attributedText");
    }
    else {
        self.text = TMLLocalizedString(self.text, @"text");
    }
}

@end