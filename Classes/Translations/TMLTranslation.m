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

#import "TMLAPISerializer.h"
#import "TMLDataToken.h"
#import "TMLLanguage.h"
#import "TMLLanguageContext.h"
#import "TMLLanguageContextRule.h"
#import "TMLModel.h"
#import "TMLTranslation.h"

@implementation TMLTranslation

+ (instancetype)translationWithKey:(NSString *)translationKey
                            locale:(NSString *)locale
                             label:(NSString *)label
{
    TMLTranslation *instance = [[TMLTranslation alloc] init];
    instance.translationKey = translationKey;
    instance.locale = locale;
    instance.label = label;
    return instance;
}

- (id)copyWithZone:(NSZone *)zone {
    TMLTranslation *aCopy = [[TMLTranslation alloc] init];
    aCopy.label = [self.label copyWithZone:zone];
    aCopy.locked = self.locked;
    aCopy.context = [self.context copyWithZone:zone];
    aCopy.translationKey = [self.translationKey copyWithZone:zone];
    return aCopy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToTranslation:(TMLTranslation *)object];
}

- (BOOL)isEqualToTranslation:(TMLTranslation *)translation {
    return ((self.label == translation.label
             || [self.label isEqual:translation.label] == YES)
            && self.locked == translation.locked
            && (self.context == translation.context
                || [self.context isEqualToDictionary:translation.context] == YES)
            && (self.translationKey == translation.translationKey
                || [self.translationKey isEqualToString:translation.translationKey] == YES));
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.label forKey:@"label"];
    [aCoder encodeBool:self.locked forKey:@"locked"];
    [aCoder encodeObject:self.context forKey:@"context"];
    [aCoder encodeObject:self.translationKey forKey:@"translation_key"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.label = [aDecoder decodeObjectForKey:@"label"];
    self.locked = [aDecoder decodeBoolForKey:@"locked"];
    self.context = [aDecoder decodeObjectForKey:@"context"];
    self.translationKey = [aDecoder decodeObjectForKey:@"translation_key"];
}

- (BOOL) hasContextRules {
    if (self.context == nil || [[self.context allKeys] count] == 0)
        return NO;
    return YES;
}

- (BOOL) isValidTranslationForTokens:(NSDictionary *)tokens
                          inLanguage:(TMLLanguage *)language
{
    if ([self.locale isEqualToString:language.locale] == NO) {
        return NO;
    }
    
    if ([self hasContextRules] == NO) {
        return YES;
    }
    
    for (NSString *tokenName in [self.context allKeys]) {
        NSDictionary *rules = [self.context objectForKey:tokenName];
        
        NSObject *tokenObject = [TMLDataToken tokenObjectForName: tokenName fromTokens: tokens];
        
        if (tokenObject == nil)
            return NO;

        for (NSString *contextKey in [rules allKeys]) {
            NSString *ruleKey = [rules objectForKey:contextKey];
            
            if ([TMLLanguageContextRule isFallback: ruleKey])
                continue;
            
            TMLLanguageContext *languageContext = (TMLLanguageContext *) [language contextByKeyword:contextKey];
            if (languageContext == nil)
                return NO;
                
            TMLLanguageContextRule *rule = (TMLLanguageContextRule *) [languageContext findMatchingRule:tokenObject];
            if (rule == nil || ![rule.keyword isEqualToString:ruleKey])
                return NO;
        }
    }
    
    return YES;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"<%@:%@: %@>", [self class], self.locale, self.label];
}

@end
