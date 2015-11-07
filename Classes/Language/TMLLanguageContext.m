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

@implementation TMLLanguageContext

@synthesize language, keyword, description, keys, tokenExpression, variableNames, tokenMapping, rules, fallbackRule;
@synthesize tokenRegularExpression;

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"language"])
        self.language = [attributes valueForKey:@"language"];
    
    self.keyword = [attributes objectForKey:@"keyword"];
    self.description = [attributes objectForKey:@"description"];
    self.keys = [attributes objectForKey:@"keys"];
    self.tokenExpression = [attributes objectForKey:@"token_expression"];
    self.variableNames = [attributes objectForKey:@"variables"];
    self.tokenMapping = [attributes objectForKey:@"token_mapping"];
    
    NSMutableDictionary *contextRules = [NSMutableDictionary dictionary];
    if ([attributes objectForKey:@"rules"]) {
        NSDictionary *rulesHash = (NSDictionary *) [attributes objectForKey:@"rules"];
        for (NSString *key in [rulesHash allKeys]) {
            NSDictionary *ruleData = [rulesHash objectForKey:key];
            TMLLanguageContextRule *rule = [[TMLLanguageContextRule alloc] initWithAttributes:ruleData];
            rule.keyword = key;
            rule.languageContext = self;
            [contextRules setObject:rule forKey:key];
            if ([rule isFallback]) self.fallbackRule = rule;
        }
    }
    self.rules = contextRules;
}

- (NSRegularExpression *) compiledTokenExpression {
    if (self.tokenRegularExpression == nil) {
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

- (NSString *) description {
    return [NSString stringWithFormat:@"%@ (%@)", self.keyword, self.language.locale];
}


@end
