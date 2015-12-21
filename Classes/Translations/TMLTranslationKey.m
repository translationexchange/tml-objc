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

#import "NSString+TML.h"
#import "TML.h"
#import "TMLApplication.h"
#import "TMLAttributedDecorationTokenizer.h"
#import "TMLDataToken.h"
#import "TMLDataTokenizer.h"
#import "TMLDecorationTokenizer.h"
#import "TMLHtmlDecorationTokenizer.h"
#import "TMLLanguage.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"

@implementation TMLTranslationKey

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@%@%i", self.key, self.locale, (int)self.level] hash];
}

# pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    TMLTranslationKey *aCopy = [[TMLTranslationKey alloc] init];
    aCopy.key = [self.key copyWithZone:zone];
    aCopy.label = [self.label copyWithZone:zone];
    aCopy.keyDescription = [self.keyDescription copyWithZone:zone];
    aCopy.locale = [self.locale copyWithZone:zone];
    aCopy.level = self.level;
    aCopy.translations = [self.translations copyWithZone:zone];
    return aCopy;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.label forKey:@"label"];
    [aCoder encodeObject:self.keyDescription forKey:@"description"];
    [aCoder encodeObject:self.locale forKey:@"locale"];
    [aCoder encodeInteger:self.level forKey:@"level"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    NSString *label = [aDecoder decodeObjectForKey:@"label"];
    self.label = label;
    NSString *description = [aDecoder decodeObjectForKey:@"description"];
    self.keyDescription = description;
    NSString *locale = [aDecoder decodeObjectForKey:@"locale"];
    if (locale == nil) {
        locale = [[TML defaultLanguage] locale];
    }
    self.locale = locale;
    self.level = [aDecoder decodeIntegerForKey:@"level"];
    NSString *key = [aDecoder decodeObjectForKey:@"key"];
    if (key == nil || [[NSNull null] isEqual:key] == YES) {
        key = [[self class] generateKeyForLabel:label
                                    description:description];
    }
    self.key = key;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToTranslationKey:(TMLTranslationKey *)object];
}

- (BOOL)isEqualToTranslationKey:(TMLTranslationKey *)translationKey {
    return ((self.key == translationKey.key
                || [self.key isEqualToString:translationKey.key] == YES)
            && (self.label == translationKey.label
                || [self.label isEqualToString:translationKey.label] == YES)
            && (self.keyDescription == translationKey.keyDescription
                || [self.keyDescription isEqualToString:translationKey.keyDescription] == YES)
            && (self.locale == translationKey.locale
                || [self.locale isEqualToString:translationKey.locale] == YES)
            && (self.level == translationKey.level));
}

#pragma mark - Key hash generation

+ (NSString *) generateKeyForLabel:(NSString *)label {
    return [self generateKeyForLabel:label description:nil];
}

+ (NSString *) generateKeyForLabel:(NSString *)label
                       description:(NSString *)description
{
    if (description == nil) description = @"";
    return [[NSString stringWithFormat:@"%@;;;%@", label, description] tmlMD5];
}

- (void) resetKey {
    _key = nil;
}

#pragma mark - Accessors

- (void)setLabel:(NSString *)label {
    if (_label == label
        || [_label isEqualToString:label] == YES) {
        return;
    }
    _label = label;
    [self resetKey];
}

- (NSString *)key {
    if (_key == nil) {
        _key = [[self class] generateKeyForLabel:self.label description:self.keyDescription];
    }
    return _key;
}

- (void)setKeyDescription:(NSString *)keyDescription {
    if (_keyDescription == keyDescription
        || [_keyDescription isEqualToString:keyDescription] == YES) {
        return;
    }
    _keyDescription = keyDescription;
    [self resetKey];
}

- (NSString *) description {
    NSString *shortLabel = self.label;
    NSInteger max = 24;
    if (shortLabel.length > max) {
        shortLabel = [[shortLabel substringToIndex:max-3] stringByAppendingString:@"..."];
    }
    return [NSString stringWithFormat:@"<%@:%@:%@: %p>", [self class], self.locale, shortLabel, self];
}

#pragma mark - Translations

- (BOOL) hasTranslations {
    return [self.translations count] > 0;
}

- (TMLTranslation *) findFirstAcceptableTranslationForTokens:(NSDictionary *)tokens
                                                  inLanguage:(TMLLanguage *)language
{
    // Get out right away
    if ([self.translations count] == 0)
        return nil;

    // Most common and fastest way to get out
    if ([self.translations count] == 1) {
        TMLTranslation *t = (TMLTranslation *) [self.translations objectAtIndex:0];
        if (t.context == nil) return t;
    }
    
    for (TMLTranslation *t in self.translations) {
        if ([t isValidTranslationForTokens:tokens inLanguage:language] == YES) {
            return t;
        }
    }
    
    TMLWarn(@"No acceptable ranslations found for key: %@", self.label);
    return nil;
}

- (NSObject *) translateToLanguage:(TMLLanguage *)language {
    return [self translateToLanguage:language tokens:nil];
}

- (NSObject *) translateToLanguage:(TMLLanguage *)language
                            tokens:(NSDictionary *)tokens
{
    return [self translateToLanguage:language
                              tokens:tokens
                             options:nil];
}

- (NSObject *) translateToLanguage:(TMLLanguage *)language
                            tokens:(NSDictionary *)tokens
                           options:(NSDictionary *)options
{
    NSString *ourLocale = self.locale;
    NSString *targetLocale = language.locale;
    NSString *label = self.label;
    
    if ([targetLocale isEqualToString:ourLocale] == NO) {
        TMLTranslation *translation = [self findFirstAcceptableTranslationForTokens:tokens
                                                                         inLanguage:language];
        
        if (translation) {
            label = translation.label;
        }
        else {
            TMLApplication *application = [[TML sharedInstance] application];
            language = (TMLLanguage *)[application languageForLocale:self.locale];
        }
    }
    
    // We may have a label with an implied decorated token,
    // that is, a list of tokens contains an extra decorated token that is not mentioned
    // in the string and that is to be applied to the entire string...
    // In that case we need to make that token explicit prior to making any substitutions
    NSMutableArray *givenTokens = [[tokens allKeys] mutableCopy];
    NSArray *decoratedTokens = [label tmlDecoratedTokens];
    NSArray *dataTokens = [label tmlDataTokens];
    NSMutableArray *tokensInLabel = [NSMutableArray array];
    if (dataTokens.count > 0) {
        [tokensInLabel addObjectsFromArray:dataTokens];
    }
    if (decoratedTokens.count > 0) {
        [tokensInLabel addObjectsFromArray:decoratedTokens];
    }
    for (NSString *token in tokensInLabel) {
        [givenTokens removeObject:token];
    }
    
    if (givenTokens.count > 0) {
        for (NSString *remainingToken in givenTokens) {
            id tokenValue = tokens[remainingToken];
            if ([tokenValue isKindOfClass:[NSDictionary class]] == YES
                && tokenValue[@"attributes"] != nil) {
                label = [TMLDecorationTokenizer applyToken:remainingToken
                                                  toString:label
                                                 withRange:NSMakeRange(0, label.length)];
                break;
            }
        }
    }

    return [self substituteTokensInLabel:label
                                  tokens:tokens
                                language:language
                                 options:options];
}

- (NSArray *) dataTokenNames {
    TMLDataTokenizer *tokenizer = [[TMLDataTokenizer alloc] initWithLabel:self.label];
    return [tokenizer tokenNames];
}

- (NSArray *) decorationTokenNames {
    return [self decorationTokenNamesInLabel:self.label];
}

- (NSArray *) decorationTokenNamesInLabel:(NSString *)label {
    TMLDecorationTokenizer *tokenizer = [[TMLDecorationTokenizer alloc] initWithLabel:label];
    return [tokenizer tokenNames];
}

- (NSObject *) substituteTokensInLabel:(NSString *)translatedLabel
                                tokens:(NSDictionary *)tokens
                              language:(TMLLanguage *)language
                               options:(NSDictionary *)options
{
    if ([translatedLabel tmlContainsDataTokens] == YES) {
        TMLDataTokenizer *tokenizer = [[TMLDataTokenizer alloc] initWithLabel:translatedLabel andAllowedTokenNames:[self dataTokenNames]];
        translatedLabel = [tokenizer substituteTokensInLabelUsingData:tokens language:language];
    }
    
    if ([translatedLabel tmlContainsDecoratedTokens] == YES) {
        NSString *tokenFormat = options[TMLTokenFormatOptionName];
        TMLDecorationTokenizer *tokenizer = nil;
        if ([tokenFormat isEqualToString:TMLAttributedTokenFormatString]) {
            tokenizer = [[TMLAttributedDecorationTokenizer alloc] initWithLabel:translatedLabel
                                                           andAllowedTokenNames:[self decorationTokenNamesInLabel:translatedLabel]];
        }
        else if ([tokenFormat isEqualToString:TMLHTMLTokenFormatString] == YES) {
            tokenizer = [[TMLHtmlDecorationTokenizer alloc] initWithLabel:translatedLabel
                                                     andAllowedTokenNames:[self decorationTokenNamesInLabel:translatedLabel]];
        }
        if (tokenizer != nil) {
            return [tokenizer substituteTokensInLabelUsingData:tokens];
        }
    }

    
    return translatedLabel;
}

@end
