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

#import "TMLLanguageContextRule.h"
#import "TMLRulesParser.h"
#import "TMLRulesEvaluator.h"

@implementation TMLLanguageContextRule

@synthesize languageContext, keyword, description, examples, conditions, compiledConditions;

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"language_context"])
        self.languageContext = [attributes objectForKey:@"language_context"];
    
    self.keyword = [attributes objectForKey:@"keyword"];
    self.description = [attributes objectForKey:@"description"];
    self.examples = [attributes objectForKey:@"examples"];
    self.conditions = [attributes objectForKey:@"conditions"];
    self.compiledConditions = [attributes objectForKey:@"conditions_expression"];
}

+ (BOOL) isFallback: (NSString *) keyword {
    return [keyword isEqualToString: @"other"];
}

- (BOOL) isFallback {
    return [self.class isFallback: self.keyword];
}

- (NSArray *) conditionsExpression {
    if (self.compiledConditions == nil) {
        TMLRulesParser *p = [TMLRulesParser parserWithExpression: self.conditions];
        self.compiledConditions = (NSArray *) [p parse];
    }
    return self.compiledConditions;
}

- (NSNumber *) evaluate: (NSDictionary *) vars {
    if ([self isFallback])
        return @YES;
    
    TMLRulesEvaluator *e = [[TMLRulesEvaluator alloc] init];
    
    for (NSString *key in [vars allKeys]) {
        NSObject *value = [vars objectForKey:key];
        [e evaluateExpression:@[@"let", key, value]];
    }

    return (NSNumber *) [e evaluateExpression:[self conditionsExpression]];
}

- (NSString *) description {
    return [NSString stringWithFormat: @"%@: %@", self.keyword, self.conditions];
}

@end
