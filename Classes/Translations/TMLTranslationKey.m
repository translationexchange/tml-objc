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
#import "TMLApplication.h"
#import "TMLAttributedDecorationTokenizer.h"
#import "TMLConfiguration.h"
#import "TMLDataToken.h"
#import "TMLDataTokenizer.h"
#import "TMLDecorationTokenizer.h"
#import "TMLHtmlDecorationTokenizer.h"
#import "TMLLanguage.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"

@implementation TMLTranslationKey

# pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    TMLTranslationKey *aCopy = [[TMLTranslationKey alloc] init];
    aCopy.key = [self.key copyWithZone:zone];
    aCopy.label = [self.label copyWithZone:zone];
    aCopy.keyDescription = [self.keyDescription copyWithZone:zone];
    aCopy.locale = [self.locale copyWithZone:zone];
    aCopy.level = [self.level copyWithZone:zone];
    aCopy.translations = [self.translations copyWithZone:zone];
    return aCopy;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.label forKey:@"label"];
    [aCoder encodeObject:self.keyDescription forKey:@"description"];
    [aCoder encodeObject:self.locale forKey:@"locale"];
    [aCoder encodeObject:self.level forKey:@"level"];
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
    self.level = [aDecoder decodeObjectForKey:@"level"];
    NSString *key = [aDecoder decodeObjectForKey:@"key"];
    if (key == nil || [[NSNull null] isEqual:key] == YES) {
        key = [[self class] generateKeyForLabel:label andDescription:description];
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
            && (self.level == translationKey.level
                || [self.level isEqualToNumber:translationKey.level] == YES));
}

#pragma mark -

+ (NSString *) generateKeyForLabel: (NSString *) label {
    return [self generateKeyForLabel:label andDescription:@""];
}

+ (NSString *) generateKeyForLabel: (NSString *) label andDescription: (NSString *) description {
    if (description == nil) description = @"";
    return [TMLConfiguration md5:[NSString stringWithFormat:@"%@;;;%@", label, description]];
}

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"application"])
        self.application = [attributes objectForKey:@"application"];

    self.label = [attributes objectForKey:@"label"];
    self.keyDescription = [attributes objectForKey:@"keyDescription"];
    
    if ([attributes objectForKey:@"key"]) {
        self.key = [attributes objectForKey:@"key"];
    } else {
        self.key = [self.class generateKeyForLabel:self.label andDescription:self.description];
    }
    
    self.locale = [attributes objectForKey:@"locale"];
    if (self.locale == nil)
        self.locale = [[[TML sharedInstance] defaultLanguage] locale];
    
    self.level = [attributes objectForKey:@"level"];
    self.translations = @[];
}

- (BOOL) hasTranslations {
    return [self.translations count] > 0;
}

- (TMLTranslation *) findFirstAcceptableTranslationForTokens: (NSDictionary *) tokens {
    // Get out right away
    if ([self.translations count] == 0)
        return nil;

    // Most common and fastest way to get out
    if ([self.translations count] == 1) {
        TMLTranslation *t = (TMLTranslation *) [self.translations objectAtIndex:0];
        if (t.context == nil) return t;
    }
    
    for (TMLTranslation *t in self.translations) {
        if ([t isValidTranslationForTokens:tokens])
            return t;
    }
    
    TMLWarn(@"No acceptable ranslations found for key: %@", self.label);
    return nil;
}

- (NSObject *) translateToLanguage: (TMLLanguage *) language {
    return [self translateToLanguage:language withTokens:@{}];
}

- (NSObject *) translateToLanguage: (TMLLanguage *) language withTokens: (NSDictionary *) tokens {
    return [self translateToLanguage:language withTokens:tokens andOptions:@{}];
}

- (NSObject *) translateToLanguage: (TMLLanguage *) language withTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    if ([language.locale isEqualToString:self.locale]) {
        return [self substituteTokensInLabel:self.label withTokens:tokens forLanguage:language andOptions:options];
    }
    
    TMLTranslation *translation = [self findFirstAcceptableTranslationForTokens: tokens];
    
    if (translation) {
        return [self substituteTokensInLabel:translation.label withTokens:tokens forLanguage:language andOptions:options];
    }
    
    // TODO: This should be done by TMLApplication
    TMLApplication *application = [[TML sharedInstance] currentApplication];
    language = (TMLLanguage *)[application languageForLocale:self.locale];
    return [self substituteTokensInLabel:self.label withTokens:tokens forLanguage:language andOptions:options];
}

- (NSArray *) dataTokenNames {
    TMLDataTokenizer *tokenizer = [[TMLDataTokenizer alloc] initWithLabel:self.label];
    return [tokenizer tokenNames];
}

- (NSArray *) decorationTokenNames {
    TMLDecorationTokenizer *tokenizer = [[TMLDecorationTokenizer alloc] initWithLabel:self.label];
    return [tokenizer tokenNames];
}

- (NSObject *) substituteTokensInLabel: (NSString *) translatedLabel withTokens: (NSDictionary *) tokens forLanguage: (TMLLanguage *) language andOptions: (NSDictionary *) options {
    if ([translatedLabel rangeOfString:@"{"].length > 0) {
        TMLDataTokenizer *tokenizer = [[TMLDataTokenizer alloc] initWithLabel:translatedLabel andAllowedTokenNames:[self dataTokenNames]];
        translatedLabel = [tokenizer substituteTokensInLabelUsingData:tokens forLanguage:language withOptions:options];
    }

    if ([[options objectForKey:@"tokenizer"] isEqual: @"attributed"]) {
        if ([translatedLabel rangeOfString:@"["].length > 0) {
            TMLDecorationTokenizer *tokenizer = [[TMLAttributedDecorationTokenizer alloc] initWithLabel:translatedLabel andAllowedTokenNames:[self decorationTokenNames]];
            return [tokenizer substituteTokensInLabelUsingData:tokens withOptions:options];
        }
        return [[NSAttributedString alloc] initWithString:translatedLabel];
    }
    
    if ([translatedLabel rangeOfString:@"["].length > 0) {
        TMLDecorationTokenizer *tokenizer = [[TMLHtmlDecorationTokenizer alloc] initWithLabel:translatedLabel andAllowedTokenNames:[self decorationTokenNames]];
        return [tokenizer substituteTokensInLabelUsingData:tokens withOptions:options];
    }
    
    return translatedLabel;
}

- (NSString *)keyDescription {
    if (_keyDescription == nil) {
        return self.label;
    }
    return _keyDescription;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"TranslationKey: %@", self.label];
}

@end
