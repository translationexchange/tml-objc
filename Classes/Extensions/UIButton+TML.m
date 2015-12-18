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
#import <objc/runtime.h>

@implementation UIButton (TML)

- (id)tmlValueForKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:@"attributedTitleForState"] == YES
        || [keyPath hasPrefix:@"titleForState"] == YES) {
        NSArray *parts = [keyPath componentsSeparatedByString:@"ForState"];
        NSString *prop = [parts firstObject];
        UIControlState state = [[parts lastObject] integerValue];
        if ([@"title" isEqualToString:prop] == YES) {
            return [self titleForState:state];
        }
        else if ([@"attributedTitle" isEqualToString:prop] == YES) {
            return [self attributedTitleForState:state];
        }
    }
    return [super tmlValueForKeyPath:keyPath];
}

- (void)tmlSetValue:(id)value forKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:@"attributedTitleForState"] == YES
        || [keyPath hasPrefix:@"titleForState"] == YES) {
        NSArray *parts = [keyPath componentsSeparatedByString:@"ForState"];
        NSString *prop = [parts firstObject];
        UIControlState state = [[parts lastObject] integerValue];
        if ([@"title" isEqualToString:prop] == YES) {
            [self setTitle:value forState:state];
            return;
        }
        else if ([@"attributedTitle" isEqualToString:prop] == YES) {
            [self setAttributedTitle:value forState:state];
            return;
        }
    }
    [super tmlSetValue:value forKeyPath:keyPath];
}

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
        NSDictionary *tokens = nil;
        NSString *tmlAttributedString = [[self attributedTitleForState:[state integerValue]] tmlAttributedString:&tokens];
        if ([tmlAttributedString tmlContainsDecoratedTokens] == YES) {
            NSString *key = [NSString stringWithFormat:@"attributedTitleForState%@", state];
            [self setAttributedTitle:TMLLocalizedAttributedString(tmlAttributedString, tokens, key) forState:[state integerValue]];
        }
        else {
            NSString *key = [NSString stringWithFormat:@"titleForState%@", state];
            [self setTitle:TMLLocalizedString(tmlAttributedString, key) forState:[state integerValue]];
        }
    }
}


@end
