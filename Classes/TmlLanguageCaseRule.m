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

#import "TmlLanguageCaseRule.h"
#import "TmlRulesParser.h"
#import "TmlRulesEvaluator.h"
#import "TmlLanguageContext.h"

@implementation TmlLanguageCaseRule

@synthesize languageCase, description, examples, conditions, compiledConditions, operations, compiledOperations;

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"language_case"])
        self.languageCase = [attributes objectForKey:@"language_case"];

    self.description = [attributes objectForKey:@"description"];
    self.examples = [attributes objectForKey:@"examples"];
    self.conditions = [attributes objectForKey:@"conditions"];
    self.compiledConditions = [attributes objectForKey:@"conditions_expression"];
    self.operations = [attributes objectForKey:@"operations"];
    self.compiledOperations = [attributes objectForKey:@"operations_expression"];
}

- (NSArray *) conditionsExpression {
    if (self.compiledConditions == nil) {
        TmlRulesParser *p = [TmlRulesParser parserWithExpression: self.conditions];
        self.compiledConditions = (NSArray *) [p parse];
    }
    return self.compiledConditions;
    
}

- (NSArray *) operationsExpression {
    if (self.compiledOperations == nil) {
        TmlRulesParser *p = [TmlRulesParser parserWithExpression: self.operations];
        self.compiledOperations = (NSArray *) [p parse];
    }
    return self.compiledOperations;
    
}

// Extracts gender value from the object
- (NSDictionary *) genderVariables: (NSObject *) object {
    if ([self.conditions rangeOfString:@"@gender"].location == NSNotFound) {
        return @{};
    }
    
    if (object == nil) {
        return @{@"@gender": @"unknown"};
    }
    
    TmlLanguageContext *context = (TmlLanguageContext *) [self.languageCase.language contextByKeyword: @"gender"];
    
    if (context == nil)
        return @{@"@gender": @"unknown"};
    
    return [context vars:object];
}

- (NSNumber *) evaluate: (NSString *) value {
    return [self evaluate:value forObject:nil];
}

- (NSNumber *) evaluate: (NSString *) value forObject: (NSObject *) object {
    if (self.conditions == nil)
        return @NO;
    
    TmlRulesEvaluator *p = [[TmlRulesEvaluator alloc] init];
    [p evaluateExpression:@[@"let", @"@value", value]];
    
    if (object) {
        NSDictionary *vars = [self genderVariables:object];
        for (NSString *key in [vars allKeys]) {
            NSObject *value = [vars objectForKey:key];
            [p evaluateExpression:@[@"let", key, value]];
        }
    }
    
    return (NSNumber *) [p evaluateExpression:[self conditionsExpression]];
}

- (NSString *) apply: (NSString *) value {
    if (self.operations == nil)
        return value;
    
    TmlRulesEvaluator *p = [[TmlRulesEvaluator alloc] init];
    [p evaluateExpression:@[@"let", @"@value", value]];
    
    return (NSString *) [p evaluateExpression:[self operationsExpression]];
}

- (NSString *) description {
    return self.conditions;
}

@end
