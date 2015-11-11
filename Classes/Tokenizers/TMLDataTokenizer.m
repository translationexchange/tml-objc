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

#import "TMLDataTokenizer.h"
#import "TMLDataToken.h"
#import "TMLPipedToken.h"
#import "TMLMethodToken.h"
#import "TMLLanguage.h"

@implementation TMLDataTokenizer

- (id) initWithLabel: (NSString *) newLabel {
    return [self initWithLabel:newLabel andAllowedTokenNames:nil];
}

- (id) initWithLabel: (NSString *) newLabel andAllowedTokenNames: (NSArray *) newAllowedTokenNames {
    if (self = [super init]) {
        self.label = newLabel;
        self.allowedTokenNames = newAllowedTokenNames;
        [self tokenize];
    }
    return self;
}

- (void) tokenize {
    self.tokens = [NSMutableArray array];
    // TODO: optimize this code to do it in one pass
    NSArray *matches = [[TMLDataToken expression] matchesInString: self.label options: 0 range: NSMakeRange(0, [self.label length])];
    for (NSTextCheckingResult *match in matches) {
        TMLDataToken *token = [[TMLDataToken alloc] initWithName:[self.label substringWithRange:[match range]]];
        if ([self isTokenAllowed:token])
            [self.tokens addObject:token];
    }
    matches = [[TMLPipedToken expression] matchesInString: self.label options: 0 range: NSMakeRange(0, [self.label length])];
    for (NSTextCheckingResult *match in matches) {
        TMLPipedToken *token = [[TMLPipedToken alloc] initWithName:[self.label substringWithRange:[match range]]];
        if ([self isTokenAllowed:token])
            [self.tokens addObject:token];
    }
    matches = [[TMLMethodToken expression] matchesInString: self.label options: 0 range: NSMakeRange(0, [self.label length])];
    for (NSTextCheckingResult *match in matches) {
        TMLMethodToken *token =[[TMLMethodToken alloc] initWithName:[self.label substringWithRange:[match range]]];
        if ([self isTokenAllowed:token])
            [self.tokens addObject:token];
    }
}

- (NSArray *) tokenNames {
    NSMutableArray *tokenNames = [NSMutableArray array];
    for (TMLDataToken *token in self.tokens) {
        [tokenNames addObject:token.shortName];
    }
    return tokenNames;
}

- (BOOL) isTokenAllowed: (TMLDataToken *) token {
    if (self.allowedTokenNames == nil)
        return YES;
    
    return [self.allowedTokenNames containsObject:token.shortName];
}

- (NSString *) substituteTokensInLabelUsingData: (NSDictionary *) tokensData forLanguage:(TMLLanguage *) language {
    return [self substituteTokensInLabelUsingData:tokensData forLanguage:language];
}

- (NSString *) substituteTokensInLabelUsingData: (NSDictionary *) tokensData forLanguage:(TMLLanguage *) language withOptions: (NSDictionary *) options {

    NSString *translatedLabel = [NSString stringWithString:self.label];
    for (TMLDataToken *token in self.tokens) {
        translatedLabel = [token substituteInLabel:translatedLabel usingTokens:tokensData forLanguage:language withOptions:options];
    }
    return translatedLabel;
}

@end
