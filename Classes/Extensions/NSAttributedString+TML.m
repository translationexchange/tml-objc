//
//  NSAttributedString+TML.m
//  TMLKit
//
//  Created by Pasha on 12/6/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "NSAttributedString+TML.h"
#import "TMLDecorationTokenizer.h"

NSString * const TMLAttributedStringStylePrefix = @"style";

@implementation NSAttributedString (TML)

- (NSString *)tmlAttributedString:(NSDictionary **)tokens {
    NSString *ourString = [self string];
    NSMutableDictionary *parts = [NSMutableDictionary dictionary];
    NSCharacterSet *whiteSpaceCharSet = [NSCharacterSet whitespaceCharacterSet];
    NSMutableDictionary *styleTokens = [NSMutableDictionary dictionary];
    __block NSInteger count=0;
    
    [self enumerateAttributesInRange:NSMakeRange(0, self.length)
                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                          usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
                              if (attrs.count == 0) {
                                  return;
                              }
                              NSString *token = [NSString stringWithFormat:@"%@%zd", TMLAttributedStringStylePrefix, ++count];
                              NSString *substring = [ourString substringWithRange:range];
                              NSString *trimmedString = [substring stringByTrimmingCharactersInSet:whiteSpaceCharSet];
                              NSRange subRange = [substring rangeOfString:trimmedString];
                              subRange.location += range.location;
                              
                              NSString *tokenizedString = [TMLDecorationTokenizer formatString:[ourString substringWithRange:subRange]
                                                                                     withToken:token];
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
    if (tokens != nil) {
        *tokens = styleTokens;
    }
    return tmlString;
}

@end
