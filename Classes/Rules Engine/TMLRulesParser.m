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

#import "TMLRulesParser.h"

@interface TMLRulesParser (Private)

+ (NSRegularExpression *) tokensRegularExpression;

- (BOOL) isEmpty;
- (NSString *) peek;
- (NSString *) pop;
- (BOOL) token: (NSString *) token startWith: (NSArray *) arr;
- (NSObject *) parseList;

@end

@implementation TMLRulesParser

+ (NSRegularExpression *) tokensRegularExpression {
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"[()]|\\w+|@\\w+|[\\+\\-\\!\\|\\=>&<\\*\\/%]+|\".*?\"|'.*?'";
        NSError *error = NULL;
        regex = [NSRegularExpression
                 regularExpressionWithPattern: pattern
                 options: NSRegularExpressionCaseInsensitive
                 error: &error];
        if (error != nil) {
            TMLError(@"Error constructing regex: %@", error);
        }
    });
    return regex;
}

+ (TMLRulesParser *) parserWithExpression: (NSString *)expression {
    return [[TMLRulesParser alloc] initWithExpression:expression];
}

- (id) initWithExpression: (NSString *)expression {
    if (self = [super init]) {
        NSRegularExpression *regex = [self.class tokensRegularExpression];
        NSArray *matches = [regex matchesInString: expression
                                      options: 0
                                        range: NSMakeRange(0, [expression length])];
    
        self.tokens = [NSMutableArray array];
        for (NSTextCheckingResult *match in matches) {
            NSString *str = [expression substringWithRange:[match range]];
            [_tokens addObject:str];
        }
    }

    return self;
}

- (BOOL) isEmpty {
    return ([self.tokens count] == 0);
}

- (NSString *) peek {
    if ([self isEmpty]) return nil;
    return (NSString *) [self.tokens objectAtIndex:0];
}

- (NSString *) pop {
    NSString *obj = [self peek];
    if (obj == nil) return nil;
    [self.tokens removeObjectAtIndex:0];
    return obj;
}

- (BOOL) token: (NSString *) token startWith: (NSArray *) arr {
    for(NSString *str in arr) {
       if ([[token substringToIndex:[str length]] isEqualToString:str])
           return YES;
    }
    return NO;
}

- (NSObject *) parse {
    if ([self isEmpty])
        return self.expression;
    
    NSString *token = [self pop];
    
    if (token == nil) return nil;
    
    if ([token isEqualToString:@"("]) {
        return [self parseList];
    }
    
    if ([self token:token startWith: @[@"\"", @"'"]]) {
        return [token substringWithRange:NSMakeRange(1, [token length]-2)];
    }
    
    return token;
}

- (NSObject *) parseList {
    NSMutableArray *elements = [NSMutableArray array];
    
    NSString *token = [self peek];
    while (![self isEmpty] && ![token isEqualToString:@")"]) {
        [elements addObject:[self parse]];
        if ([self.tokens count] > 0) {
            token = [self peek];
        }
    }
    [self pop];
    return elements;
}

@end
