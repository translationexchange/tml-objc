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

#import "TmlDecorationTokenizer.h"

@interface TmlDecorationTokenizer ()


@end

@implementation TmlDecorationTokenizer

@synthesize tokenNames, fragments, tokensData, label, expression, allowedTokenNames, options;

- (id) initWithLabel: (NSString *) newLabel {
    return [self initWithLabel:newLabel andAllowedTokenNames:nil];
}

- (id) initWithLabel: (NSString *) newLabel andAllowedTokenNames: (NSArray *) newAllowedTokenNames {
    if (self = [super init]) {
        self.label = [NSString stringWithFormat:@"[%@]%@[/%@]", TR8N_RESERVED_TOKEN, newLabel, TR8N_RESERVED_TOKEN];
        self.tokenNames = [NSMutableArray array];
        self.allowedTokenNames = newAllowedTokenNames;
        [self fragmentize];
        self.expression = [self parse];
    }
    
    return self;
}

- (void) fragmentize {
    NSArray *elements = @[TR8N_RE_SHORT_TOKEN_START,
                          TR8N_RE_SHORT_TOKEN_END,
                          TR8N_RE_LONG_TOKEN_START,
                          TR8N_RE_LONG_TOKEN_END,
                          TR8N_RE_TEXT];
    NSString *pattern = [elements componentsJoinedByString:@"|"];

    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern: pattern
                                  options: NSRegularExpressionCaseInsensitive
                                  error: &error];
    // TODO: check for errors
    NSArray *matches = [regex matchesInString: self.label options: 0 range: NSMakeRange(0, [self.label length])];
    self.elements = [NSMutableArray array];
    for (NSTextCheckingResult *match in matches) {
        NSString *str = [self.label substringWithRange:[match range]];
        [self.elements addObject:str];
    }
    // keep a copy for reference
    self.fragments = [NSArray arrayWithArray:self.elements];
}

- (BOOL) isEmpty {
    return ([self.elements count] == 0);
}

- (NSString *) peek {
    if ([self isEmpty]) return nil;
    return (NSString *) [self.elements objectAtIndex:0];
}

- (NSString *) pop {
    NSString *obj = [self peek];
    if (obj == nil) return nil;
    [self.elements removeObjectAtIndex:0];
    return obj;
}

- (BOOL) token: (NSString *) token matchesExpression: (NSString *) re {
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:re options:0 error:&error];
    // TODO: check for errors
    NSRange firstMatch = [regex rangeOfFirstMatchInString:token options:0 range:NSMakeRange(0, [token length])];
    return (firstMatch.location != NSNotFound);
}

- (NSString *)stringByTrimmingLeadingCharactersOfString: (NSString *) string inSet:(NSCharacterSet *)characterSet {
    NSUInteger location = 0;
    NSUInteger length = [string length];
    unichar charBuffer[length];
    [string getCharacters:charBuffer];
    
    for (location = 0; location < length; location++) {
        if (![characterSet characterIsMember:charBuffer[location]]) {
            break;
        }
    }
    
    return [string substringWithRange:NSMakeRange(location, length - location)];
}

- (NSString *)stringByTrimmingTrailingCharactersOfString: (NSString *) string inSet:(NSCharacterSet *)characterSet {
    NSUInteger location = 0;
    NSUInteger length = [string length];
    unichar charBuffer[length];
    [string getCharacters:charBuffer];
    
    for (length = [string length]; length > 0; length--) {
        if (![characterSet characterIsMember:charBuffer[length - 1]]) {
            break;
        }
    }
    
    return [string substringWithRange:NSMakeRange(location, length - location)];
}

- (NSObject *) parse {
    NSString *token = [self pop];
    
    if ([self token:token matchesExpression:TR8N_RE_SHORT_TOKEN_START]) {
        token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[:"]];
        return [self parseTree: token type: TR8N_TOKEN_TYPE_SHORT];
    }

    if ([self token:token matchesExpression:TR8N_RE_LONG_TOKEN_START]) {
        token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
        return [self parseTree: token type: TR8N_TOKEN_TYPE_LONG];
    }
    
    return token;
}

- (NSObject *) parseTree: (NSString *) name type: (NSString *) type {
    NSMutableArray *tree = [NSMutableArray array];
    [tree addObject:name];
    
    if (![self.tokenNames containsObject:name] && ![name isEqualToString:TR8N_RESERVED_TOKEN]) {
        [self.tokenNames addObject:name];
    }

    if ([type isEqualToString:TR8N_TOKEN_TYPE_SHORT]) {
        BOOL first = YES;
        while ([self peek] != nil && ![self token:[self peek] matchesExpression:TR8N_RE_SHORT_TOKEN_END]) {
            NSObject *value = [self parse];
            if (first && [value isKindOfClass:NSString.class]) {
                NSString *str = (NSString *) value;
                value = [self stringByTrimmingLeadingCharactersOfString: str inSet:[NSCharacterSet whitespaceCharacterSet]];
                first = NO;
            }
            [tree addObject:value];
        }
    } else if ([type isEqualToString:TR8N_TOKEN_TYPE_LONG]) {
        while ([self peek] != nil && ![self token:[self peek] matchesExpression:TR8N_RE_LONG_TOKEN_END]) {
            [tree addObject:[self parse]];
        }
    }
    
    [self pop];
    return tree;
}

- (BOOL) isTokenAllowed: (NSString *) token {
    if (self.allowedTokenNames == nil)
        return YES;
    
    return [self.allowedTokenNames containsObject:token];
}

- (NSString *) applyToken: (NSString *) token toValue: (NSString *) value {
    return value;
}

- (NSString *) evaluate: (NSObject *) expr {
    if (![expr isKindOfClass:NSArray.class])
        return (NSString *) expr;
    
    NSMutableArray *args = [NSMutableArray arrayWithArray:(NSArray *) expr];
    NSString *token = (NSString *) [args objectAtIndex:0];
    [args removeObjectAtIndex:0];
    
    NSMutableArray *processedValues = [NSMutableArray array];
    for (NSObject *arg in args) {
        [processedValues addObject:[self evaluate:arg]];
    }
    
    NSString *value = [processedValues componentsJoinedByString:@""];
    return [self applyToken:token toValue:value];
}

- (NSObject *) substituteTokensInLabelUsingData: (NSDictionary *) newTokensData {
    return [self substituteTokensInLabelUsingData:newTokensData withOptions:@{}];
}

- (NSObject *) substituteTokensInLabelUsingData: (NSDictionary *) newTokensData withOptions: (NSDictionary *) newOptions {
    self.tokensData = newTokensData;
    self.options = newOptions;
    return [self evaluate: self.expression];
}

@end
