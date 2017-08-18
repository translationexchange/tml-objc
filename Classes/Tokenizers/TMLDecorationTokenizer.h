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


/**
    Decoration Token Forms:

        [strong: click here]
        [strong] click here [/strong]
        [strong] click [italic: here] [/strong]

    Decoration Tokens Allow Nesting:

        [strong: {count||message}]
        [strong: {count||person, people}]
        [strong: {user.name}]
*/

#import <Foundation/Foundation.h>
#import "TMLTokenizer.h"

#ifndef TML_RESERVED_TOKEN
    #define TML_RESERVED_TOKEN             @"tml"
    #define TML_RE_SHORT_TOKEN_START       @"\\[[\\w]*:"
    #define TML_RE_SHORT_TOKEN_END         @"\\]"

    #define TML_RE_LONG_TOKEN_START        @"\\[[\\w]*\\]"
    #define TML_RE_LONG_TOKEN_END          @"\\[\\/[\\w]*\\]"

    #define TML_RE_HTML_TOKEN_START        @"<[^\\>]*>"
    #define TML_RE_HTML_TOKEN_END          @"<\\/[^\\>]*>"

    #define TML_RE_TEXT                    @"[^\\[\\]<>]+"

    #define TML_TOKEN_TYPE_SHORT           @"short"
    #define TML_TOKEN_TYPE_LONG            @"long"
    #define TML_TOKEN_TYPE_HTML            @"html"
    #define TML_PLACEHOLDER                @"{$0}"
#endif

@interface TMLDecorationTokenizer : TMLTokenizer

@property(nonatomic, strong) NSMutableArray *tokenNames;

@property(nonatomic, strong) NSObject *expression;

@property(nonatomic, strong) NSArray *fragments;

@property(nonatomic, strong) NSMutableArray *elements;

@property(nonatomic, strong) NSDictionary *tokensData;

@property(nonatomic, strong) NSString *label;

// List of allowed token names from the original label
@property(nonatomic, strong) NSArray *allowedTokenNames;

+ (NSString *)formatString:(NSString *)string withToken:(NSString *)token;

+ (NSString *)applyToken:(NSString *)token toString:(NSString *)string withRange:(NSRange)range;

- (id) initWithLabel: (NSString *) newLabel;

- (id) initWithLabel: (NSString *) newLabel andAllowedTokenNames: (NSArray *) newAllowedTokenNames;

- (NSString *) peek;

- (NSString *) pop;

- (NSString *)stringByTrimmingLeadingCharactersOfString: (NSString *) string inSet:(NSCharacterSet *)characterSet;

- (BOOL) isTokenAllowed: (NSString *) token;

- (BOOL)token:(NSString *)token matchesExpression:(NSRegularExpression *)regex;

- (NSObject *) substituteTokensInLabelUsingData: (NSDictionary *) newTokensData;

@end

