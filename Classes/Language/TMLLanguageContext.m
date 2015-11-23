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

#import "TML.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLLanguageContext.h"
#import "TMLLanguageContextRule.h"
#import "TMLAPISerializer.h"

@implementation TMLLanguageContext

- (id)copyWithZone:(NSZone *)zone {
    TMLLanguageContext *aCopy = [[TMLLanguageContext alloc] init];
    aCopy.language = [self.language copyWithZone:zone];
    aCopy.keyword = [self.keyword copyWithZone:zone];
    aCopy.contextDescription = [self.contextDescription copyWithZone:zone];
    aCopy.keys = [self.keys copyWithZone:zone];
    aCopy.tokenExpression = [self.tokenExpression copyWithZone:zone];
    aCopy.tokenRegularExpression = [self.tokenRegularExpression copyWithZone:zone];
    aCopy.variableNames = [self.variableNames copyWithZone:zone];
    aCopy.tokenMapping = [self.tokenMapping copyWithZone:zone];
    aCopy.rules = [self.rules copyWithZone:zone];
    aCopy.fallbackRule = [self.fallbackRule copyWithZone:zone];
    return aCopy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToLanguageContext:(TMLLanguageContext *)object];
}

- (BOOL)isEqualToLanguageContext:(TMLLanguageContext *)languageContext {
    return ((self.language == languageContext.language
             || [self.language isEqualToLanguage:languageContext.language] == YES)
            && (self.keyword == languageContext.keyword
                || [self.keyword isEqualToString:languageContext.keyword] == YES)
            && (self.contextDescription == languageContext.contextDescription
                || [self.contextDescription isEqualToString:languageContext.contextDescription] == YES)
            && (self.keys == languageContext.keys
                || [self.keys isEqualToArray:languageContext.keys] == YES)
            && (self.tokenExpression == languageContext.tokenExpression
                || [self.tokenExpression isEqualToString:languageContext.tokenExpression] == YES)
            && (self.variableNames == languageContext.variableNames
                || [self.variableNames isEqualToArray:languageContext.variableNames] == YES)
            && (self.tokenMapping == languageContext.tokenMapping
                || [self.tokenMapping isEqual:languageContext.tokenMapping] == YES)
            && (self.rules == languageContext.rules
                || [self.rules isEqualToDictionary:languageContext.rules] == YES)
            && (self.fallbackRule == languageContext.fallbackRule
                || [self.fallbackRule isEqual:languageContext.fallbackRule] == YES));
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.keyword forKey:@"keyword"];
    [aCoder encodeObject:self.contextDescription forKey:@"description"];
    [aCoder encodeObject:self.keys forKey:@"keys"];
    [aCoder encodeObject:self.defaultKey forKey:@"default_key"];
    [aCoder encodeObject:self.tokenExpression forKey:@"token_expression"];
    [aCoder encodeObject:self.variableNames forKey:@"variables"];
    [aCoder encodeObject:self.tokenMapping forKey:@"token_mapping"];
    [aCoder encodeObject:self.rules forKey:@"rules"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.keyword = [aDecoder decodeObjectForKey:@"keyword"];
    self.contextDescription = [aDecoder decodeObjectForKey:@"description"];
    self.keys = [aDecoder decodeObjectForKey:@"keys"];
    self.defaultKey = [aDecoder decodeObjectForKey:@"default_key"];
    self.tokenExpression = [aDecoder decodeObjectForKey:@"token_expression"];
    self.variableNames = [aDecoder decodeObjectForKey:@"variables"];
    self.tokenMapping = [aDecoder decodeObjectForKey:@"token_mapping"];
    NSDictionary *rules = [aDecoder decodeObjectForKey:@"rules"];
    if (rules.count > 0 && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        NSMutableDictionary *newRules = [NSMutableDictionary dictionary];
        for (NSString *keyword in rules) {
            TMLLanguageContextRule *aRule = [TMLAPISerializer materializeObject:rules[keyword]
                                                                      withClass:[TMLLanguageContextRule class]];
            if (aRule != nil) {
                if (aRule.keyword == nil) {
                    aRule.keyword = keyword;
                }
                newRules[keyword] = aRule;
            }
        }
        rules = [newRules copy];
    }
    self.rules = rules;
}

- (NSRegularExpression *) compiledTokenExpression {
    if (self.tokenRegularExpression == nil
        && self.tokenExpression.length > 0) {
        NSError *error = NULL;
        NSString *adjustedExpression = [self.tokenExpression stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        self.tokenRegularExpression = [NSRegularExpression
                                       regularExpressionWithPattern: adjustedExpression
                                       options: NSRegularExpressionCaseInsensitive error: &error];
    }
    
    return self.tokenRegularExpression;
}

- (BOOL) isApplicableToTokenName: (NSString *) tokenName {
    NSRange firstMatch = [[self compiledTokenExpression] rangeOfFirstMatchInString:tokenName options:0 range: NSMakeRange(0, [tokenName length])];
    return (firstMatch.length > 0);
}

- (NSDictionary *) vars: (NSObject *) object {
    NSMutableDictionary *vars = [NSMutableDictionary dictionary];
    
    for (NSString *varName in self.variableNames) {
        id method = [[TML sharedInstance].configuration variableMethodForContext:self.keyword andVariableName:varName];

        if (method==nil) {
            [vars setObject:object forKey:varName];
            continue;
        }

        if ([method isKindOfClass:NSClassFromString(@"NSBlock")]) {
            NSString *(^fn)(NSObject *) = method;
            NSObject *objectValue = fn(object);
            [vars setObject:objectValue forKey:varName];
            continue;
        }
        
        if ([method isKindOfClass: NSString.class]) {
            NSString *objectMethod = (NSString *) method;

            if ([object isKindOfClass: NSDictionary.class]) {
                NSDictionary *hash = (NSDictionary *) object;
                if ([hash objectForKey:@"object"])
                    hash = [hash objectForKey:@"object"];
                
                objectMethod = [objectMethod stringByReplacingOccurrencesOfString:@"@" withString:@""];
                [vars setObject:[hash objectForKey:objectMethod] forKey:varName];
                continue;
            }
            
            if ([objectMethod isEqualToString:@"@@self"]) {
                [vars setObject:object forKey:varName];
                continue;
            }
            
            if ([objectMethod hasPrefix:@"@@"]) {
                objectMethod = [objectMethod stringByReplacingOccurrencesOfString:@"@@" withString:@""];
                SEL selector = NSSelectorFromString(objectMethod);

                // make sure the object responds to the selector
                if (![object respondsToSelector:selector])
                    continue;
                
                IMP imp = [object methodForSelector:selector];
                NSString *(*func)(id, SEL) = (void *)imp;
                NSObject *objectValue = func(object, selector);
                
                [vars setObject:objectValue forKey:varName];
                continue;
            }
            
            if ([objectMethod hasPrefix:@"@"]) {
                objectMethod = [objectMethod stringByReplacingOccurrencesOfString:@"@" withString:@""];
                
                // make sure the object contains the property
                if (![object respondsToSelector:NSSelectorFromString(objectMethod)])
                    continue;

                NSObject *objectValue = [object valueForKey:objectMethod];
                [vars setObject:objectValue forKey:varName];
                continue;
            }
            
            [vars setObject:objectMethod forKey:varName];
            continue;
        }
    }

    return vars;
}

- (NSObject *) findMatchingRule: (NSObject *) object {
    NSDictionary *tokenVars = [self vars:object];
    
    for (TMLLanguageContextRule *rule in [self.rules allValues]) {
        if ([rule isFallback])
            continue;
        
        if ([[rule evaluate:tokenVars] isEqual:@YES])
            return rule;
    }
    
    return self.fallbackRule;
}

- (NSString *) contextDescription {
    if (_contextDescription == nil) {
        return [NSString stringWithFormat:@"%@ (%@)", self.keyword, self.language.locale];
    }
    return _contextDescription;
}


@end
