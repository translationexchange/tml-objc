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
#import "TMLAPIClient.h"
#import "TMLAPISerializer.h"
#import "TMLApplication.h"
#import "TMLAttributedDecorationTokenizer.h"
#import "TMLDataTokenizer.h"
#import "TMLLanguage.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"

NSString * const TMLApplicationInlineTranslationFeatureKey = @"inline_translations";

@interface TMLApplication() {
    TMLLanguage *_defaultLanguage;
}

@end

@implementation TMLApplication

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.applicationID forKey:@"id"];
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.secret forKey:@"secret"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.defaultLocale forKey:@"default_locale"];
    [aCoder encodeInteger:self.threshold forKey:@"threshold"];
    [aCoder encodeObject:self.features forKey:@"features"];
    [aCoder encodeObject:self.tools forKey:@"tools"];
    [aCoder encodeObject:self.languages forKey:@"languages"];
    [aCoder encodeObject:self.sources forKey:@"sources"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.applicationID = [aDecoder decodeIntegerForKey:@"id"];
    self.key = [aDecoder decodeObjectForKey:@"key"];
    self.secret = [aDecoder decodeObjectForKey:@"secret"];
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.defaultLocale = [aDecoder decodeObjectForKey:@"default_locale"];
    self.threshold = [aDecoder decodeIntegerForKey:@"threshold"];
    self.features = [aDecoder decodeObjectForKey:@"features"];
    NSArray *languages = [aDecoder decodeObjectForKey:@"languages"];
    if (languages != nil && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        languages = [TMLAPISerializer materializeObject:languages
                                              withClass:[TMLLanguage class]];
    }
    self.languages = languages;
    
    NSArray *sources = [aDecoder decodeObjectForKey:@"sources"];
    if (sources.count > 0 && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        sources = [TMLAPISerializer materializeObject:sources
                                            withClass:[TMLSource class]];
    }
    self.sources = sources;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToApplication:(TMLApplication *)object];
}

- (BOOL)isEqualToApplication:(TMLApplication *)application {
    return (self.applicationID == application.applicationID
            && (self.key == application.key
                || [self.key isEqualToString:application.key] == YES)
            && (self.secret == application.secret
                || [self.secret isEqualToString:application.secret] == YES)
            && (self.name == application.name
                || [self.name isEqualToString:application.name] == YES)
            && (self.defaultLocale == application.defaultLocale
                || [self.defaultLocale isEqualToString:application.defaultLocale] == YES)
            && (self.threshold == application.threshold)
            && (self.features == application.features
                || [self.features isEqualToDictionary:application.features] == YES)
            && (self.tools == application.tools
                || [self.tools isEqualToDictionary:application.tools] == YES)
            && (self.languages == application.languages
                || [self.languages isEqualToArray:application.languages] == YES)
            && (self.sources == application.sources
                || [self.sources isEqualToArray:application.sources] == YES)
            && (self.defaultLanguage == application.defaultLanguage
                || [self.defaultLanguage isEqualToLanguage:application.defaultLanguage] == YES));
}

#pragma mark - Languages

- (TMLLanguage *) languageForLocale:(NSString *)locale {
    TMLLanguage *result = nil;
    for (TMLLanguage *lang in self.languages) {
        if ([lang.locale isEqualToString:locale] == YES) {
            result = lang;
            break;
        }
    }
    return result;
}

- (TMLLanguage *)defaultLanguage {
    if (_defaultLanguage == nil) {
        NSString *defaultLocale = self.defaultLocale;
        for (TMLLanguage *lang in self.languages) {
            if ([lang.locale isEqualToString:defaultLocale] == YES) {
                _defaultLanguage = lang;
                break;
            }
        }
    }
    return _defaultLanguage;
}

- (void)setLanguages:(NSArray<TMLLanguage *> *)languages {
    if (languages == _languages
        || ([_languages isEqualToArray:languages]) == YES) {
        return;
    }
    
    _languages = languages;
    // We'll reconstruct default language
    _defaultLanguage = nil;
}

- (void)setDefaultLocale:(NSString *)defaultLocale {
    if (_defaultLocale == defaultLocale
        || ([_defaultLocale isEqualToString:defaultLocale]) == YES) {
        return;
    }
    _defaultLocale = defaultLocale;
    // We'll reconstruct default language
    _defaultLanguage = nil;
}

#pragma mark - Sources

- (TMLSource *) sourceForKey:(NSString *)sourceKey {
    if (sourceKey == nil)
        return nil;
    
    TMLSource *result = nil;
    for (TMLSource *source in self.sources) {
        if ([source.key isEqualToString:sourceKey] == YES) {
            result = source;
        }
    }
    
    return result;
}

#pragma mark - Features

- (BOOL)isInlineTranslationsEnabled {
    return [_features[TMLApplicationInlineTranslationFeatureKey] boolValue];
}

@end
