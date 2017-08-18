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

#import "TMLLanguage.h"
#import "TMLLanguageCase.h"
#import "TMLLanguageCaseRule.h"
#import "TMLLanguageContext.h"
#import "TMLRulesEvaluator.h"
#import "TMLRulesParser.h"

@implementation TMLLanguageCaseRule

- (id)copyWithZone:(NSZone *)zone {
    TMLLanguageCaseRule *aCopy = [[TMLLanguageCaseRule alloc] init];
    aCopy.languageCase = [self.languageCase copyWithZone:zone];
    aCopy.ruleDescription = [self.ruleDescription copyWithZone:zone];
    aCopy.examples = [self.examples copyWithZone:zone];
    aCopy.conditions = [self.conditions copyWithZone:zone];
    aCopy.compiledConditions = [self.compiledConditions copyWithZone:zone];
    aCopy.operations = [self.operations copyWithZone:zone];
    aCopy.compiledOperations = [self.compiledOperations copyWithZone:zone];
    return aCopy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.ruleDescription forKey:@"description"];
    [aCoder encodeObject:self.examples forKey:@"examples"];
    [aCoder encodeObject:self.conditions forKey:@"conditions"];
    [aCoder encodeObject:self.operations forKey:@"operations"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.ruleDescription = [aDecoder decodeObjectForKey:@"description"];
    self.examples = [aDecoder decodeObjectForKey:@"examples"];
    self.conditions = [aDecoder decodeObjectForKey:@"conditions"];
    self.operations = [aDecoder decodeObjectForKey:@"operations"];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToLanguageCaseRule:(TMLLanguageCaseRule *)object];
}

- (BOOL)isEqualToLanguageCaseRule:(TMLLanguageCaseRule *)languageCaseRule {
    return ((self.ruleDescription == languageCaseRule.ruleDescription
             || [self.ruleDescription isEqualToString:languageCaseRule.ruleDescription] == YES)
            && (self.examples == languageCaseRule.examples
                || [self.examples isEqualToString:languageCaseRule.examples] == YES)
            && (self.conditions == languageCaseRule.conditions
                || [self.conditions isEqualToString:languageCaseRule.conditions] == YES)
            && (self.operations == languageCaseRule.operations
                || [self.operations isEqualToString:languageCaseRule.conditions] == YES));
}

- (NSArray *) conditionsExpression {
    if (self.compiledConditions == nil) {
        TMLRulesParser *p = [TMLRulesParser parserWithExpression: self.conditions];
        self.compiledConditions = (NSArray *) [p parse];
    }
    return self.compiledConditions;
    
}

- (NSArray *) operationsExpression {
    if (self.compiledOperations == nil) {
        TMLRulesParser *p = [TMLRulesParser parserWithExpression: self.operations];
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
    
    TMLLanguageContext *context = (TMLLanguageContext *) [self.languageCase.language contextByKeyword: @"gender"];
    
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
    
    TMLRulesEvaluator *p = [[TMLRulesEvaluator alloc] init];
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
    
    TMLRulesEvaluator *p = [[TMLRulesEvaluator alloc] init];
    [p evaluateExpression:@[@"let", @"@value", value]];
    
    return (NSString *) [p evaluateExpression:[self operationsExpression]];
}

- (NSString *) ruleDescription {
    if (_ruleDescription == nil) {
        return self.conditions;
    }
    return _ruleDescription;
}

@end
