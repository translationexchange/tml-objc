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

#import "NSAttributedString+TML.h"
#import "TMLDecorationTokenizer.h"

NSString * const TMLAttributedStringStylePrefix = @"style";

@implementation NSAttributedString (TML)
- (NSString *)tmlAttributedString:(NSDictionary **)tokens {
    return [self tmlAttributedString:tokens implicit:YES];
}

- (NSString *)tmlAttributedString:(NSDictionary **)tokens implicit:(BOOL)implicit {
    NSString *ourString = [self string];
    NSMutableDictionary *parts = [NSMutableDictionary dictionary];
    NSCharacterSet *whiteSpaceCharSet = [NSCharacterSet whitespaceCharacterSet];
    NSMutableDictionary *styleTokens = [NSMutableDictionary dictionary];
    __block NSInteger count=0;
    
    [self enumerateAttributesInRange:NSMakeRange(0, self.length)
                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                          usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
                              if (attrs.count == 0) {
                                  return;
                              }
                              NSString *token = nil;
                              if (count == 0) {
                                  token = TMLAttributedStringStylePrefix;
                              }
                              else {
                                  token = [NSString stringWithFormat:@"%@%zd", TMLAttributedStringStylePrefix, count];
                              }
                              count++;
                              
                              NSString *substring = [ourString substringWithRange:range];
                              NSString *trimmedString = [substring stringByTrimmingCharactersInSet:whiteSpaceCharSet];
                              NSRange subRange = [substring rangeOfString:trimmedString];
                              subRange.location += range.location;
                              if (subRange.location == NSNotFound) {
                                  subRange = range;
                              }
                              
                              NSString *tokenizedString = [ourString substringWithRange:subRange];
                              if (implicit == NO
                                  || !(range.location == 0 && range.length == self.length)) {
                                  tokenizedString = [TMLDecorationTokenizer formatString:tokenizedString
                                                                               withToken:token];
                              }
                              NSValue *rangeValue = [NSValue valueWithRange:subRange];
                              parts[rangeValue] = tokenizedString;
                              styleTokens[token] = @{@"attributes": attrs};
                          }];
    
    if (count == 0) {
        return ourString;
    }
    
    NSMutableString *tmlString = [NSMutableString string];
    NSArray *sortedLocations = [[parts allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSValue *rangeA, NSValue *rangeB) {
        NSRange a = [rangeA rangeValue];
        NSRange b = [rangeB rangeValue];
        return [@(a.location) compare:@(b.location)];
    }];
    NSInteger tail = 0;
    for (NSValue *rangeValue in sortedLocations) {
        NSRange range = [rangeValue rangeValue];
        if (range.location > tail) {
            [tmlString appendString:[ourString substringWithRange:NSMakeRange(tail, range.location-tail)]];
        }
        NSString *tokenizedString = parts[rangeValue];
        [tmlString appendString:tokenizedString];
        tail = range.location + range.length;
    }
    if (tmlString.length < ourString.length) {
        [tmlString appendString:[ourString substringWithRange:NSMakeRange(tmlString.length, ourString.length - tmlString.length)]];
    }
    if (tokens != nil) {
        *tokens = styleTokens;
    }
    return tmlString;
}

@end
