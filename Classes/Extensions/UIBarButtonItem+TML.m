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

#import "NSObject+TML.h"
#import "TML.h"
#import "UIBarButtonItem+TML.h"

NSString * const TMLPossibleTitleKeyPrefix = @"possibleTitleAtIndex";

@implementation UIBarButtonItem (TML)

- (id)tmlValueForKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:TMLPossibleTitleKeyPrefix] == YES) {
        NSUInteger index = [[keyPath stringByReplacingOccurrencesOfString:TMLPossibleTitleKeyPrefix withString:@""] integerValue];
        NSUInteger count = 0;
        for (NSString *title in self.possibleTitles) {
            if (count == index) {
                return title;
            }
            count++;
        }
    }
    return [super tmlValueForKeyPath:keyPath];
}

- (void)tmlSetValue:(id)value forKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:TMLPossibleTitleKeyPrefix] == YES) {
        NSMutableSet *newSet = [NSMutableSet set];
        NSUInteger index = [[keyPath stringByReplacingOccurrencesOfString:TMLPossibleTitleKeyPrefix withString:@""] integerValue];
        NSUInteger count = 0;
        for (NSString *title in self.possibleTitles) {
            if (count == index) {
                [newSet addObject:value];
            }
            else {
                [newSet addObject:title];
            }
            count++;
        }
        [self setPossibleTitles:newSet];
    }
    return [super tmlSetValue:value forKeyPath:keyPath];
}

- (void)localizeWithTML {
    [super localizeWithTML];
    NSSet *possibleTitles = self.possibleTitles;
    NSUInteger count = 0;
    NSMutableSet *newSet = [NSMutableSet set];
    for (NSString *possibleTitle in possibleTitles) {
        NSString *key = [NSString stringWithFormat:@"%@%lu", TMLPossibleTitleKeyPrefix, count];
        [newSet addObject:TMLLocalizedString(possibleTitle, key)];
        count++;
    }
}

@end
