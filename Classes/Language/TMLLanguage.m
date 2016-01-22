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

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLAPISerializer.h"
#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLLanguageCase.h"
#import "TMLLanguageContext.h"
#import "TMLSource.h"
#import "TMLTokenizer.h"
#import "TMLTranslationKey.h"
#import "NSObject+TML.h"

@implementation TMLLanguage

+ (TMLLanguage *) defaultLanguage {
    static TMLLanguage *lang = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *ourBundle = [NSBundle bundleForClass:[TML class]];
        if (ourBundle == nil) {
            ourBundle = [NSBundle mainBundle];
        }
        NSString *jsonPath = [ourBundle pathForResource:@"en" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:jsonPath];
        if (data != nil) {
            lang = [TMLAPISerializer materializeData:data withClass:[TMLLanguage class]];
        }
    });
    return lang;
}

- (id)copyWithZone:(NSZone *)zone {
    TMLLanguage *aCopy = [[TMLLanguage alloc] init];
    aCopy.languageID = self.languageID;
    aCopy.locale = [self.locale copyWithZone:zone];
    aCopy.englishName = [self.englishName copyWithZone:zone];
    aCopy.nativeName = [self.nativeName copyWithZone:zone];
    aCopy.rightToLeft = self.rightToLeft;
    aCopy.flagUrl = [self.flagUrl copyWithZone:zone];
    aCopy.status = [self.status copyWithZone:zone];
    
    aCopy.contexts = [self.contexts copyWithZone:zone];
    aCopy.cases = [self.cases copyWithZone:zone];
    return aCopy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToLanguage:(TMLLanguage *)object];
}

- (BOOL)isEqualToLanguage:(TMLLanguage *)language {
    return (self.languageID == language.languageID
            && (self.locale == language.locale
                || [self.locale isEqualToString:language.locale] == YES)
            && (self.englishName == language.englishName
                || [self.englishName isEqualToString:language.englishName] == YES)
            && (self.nativeName == language.nativeName
                || [self.nativeName isEqualToString:language.nativeName] == YES)
            && (self.rightToLeft == language.rightToLeft)
            && (self.flagUrl == language.flagUrl
                || [self.flagUrl isEqual:language.flagUrl] == YES)
            && (self.status == language.status
                || [self.status isEqualToString:language.status] == YES)
            && (self.contexts == language.contexts
                || [self.contexts isEqualToDictionary:language.contexts] == YES)
            && (self.cases == language.cases
                || [self.cases isEqualToDictionary:language.cases] == YES));
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.languageID forKey:@"id"];
    [aCoder encodeObject:self.locale forKey:@"locale"];
    [aCoder encodeObject:self.englishName forKey:@"english_name"];
    [aCoder encodeObject:self.nativeName forKey:@"native_name"];
    [aCoder encodeBool:self.rightToLeft forKey:@"right_to_left"];
    [aCoder encodeObject:[self.flagUrl absoluteString] forKey:@"flag_url"];
    [aCoder encodeObject:self.status forKey:@"status"];
    [aCoder encodeObject:self.contexts forKey:@"contexts"];
    [aCoder encodeObject:self.cases forKey:@"cases"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.languageID = [aDecoder decodeIntegerForKey:@"id"];
    self.locale = [aDecoder decodeObjectForKey:@"locale"];
    self.englishName = [aDecoder decodeObjectForKey:@"english_name"];
    self.nativeName = [aDecoder decodeObjectForKey:@"native_name"];
    self.rightToLeft = [aDecoder decodeBoolForKey:@"right_to_left"];
    self.flagUrl = [NSURL URLWithString:[aDecoder decodeObjectForKey:@"flag_url"]];
    self.status = [aDecoder decodeObjectForKey:@"status"];
    NSDictionary *contexts = [aDecoder decodeObjectForKey:@"contexts"];
    if (contexts.count > 0 && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        NSMutableDictionary *materializedContexts = [NSMutableDictionary dictionary];
        for (NSString *keyword in contexts) {
            TMLLanguageContext *context = [TMLAPISerializer materializeObject:contexts[keyword]
                                                                    withClass:[TMLLanguageContext class]];
            if (context != nil) {
                context.language = self;
                if (context.keyword == nil) {
                    context.keyword = keyword;
                }
                materializedContexts[keyword] = context;
            }
        }
        contexts = [materializedContexts copy];
    }
    self.contexts = contexts;
    NSDictionary *cases = [aDecoder decodeObjectForKey:@"cases"];
    if (cases.count > 0 && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        NSMutableDictionary *materializedCases = [NSMutableDictionary dictionary];
        for (NSString *keyword in cases) {
            TMLLanguageCase *aCase = [TMLAPISerializer materializeObject:cases[keyword] withClass:[TMLLanguageCase class]];
            if (aCase != nil) {
                aCase.language = self;
                if (aCase.keyword == nil) {
                    aCase.keyword = keyword;
                }
                materializedCases[keyword] = aCase;
            }
        }
        cases = [materializedCases copy];
    }
    self.cases = cases;
}

- (TMLLanguageContext *) contextByKeyword: (NSString *) keyword {
    return [self.contexts objectForKey:keyword];
}

- (TMLLanguageContext *) contextByTokenName: (NSString *) tokenName {
    for (TMLLanguageContext *context in [self.contexts allValues]) {
        if ([context isApplicableToTokenName:tokenName]) {
            return context;
        }
    }
    return nil;
}

- (TMLLanguageCase *) languageCaseByKeyword: (NSString *) keyword {
    return [self.cases objectForKey:keyword];
}

- (BOOL) hasDefinitionData {
    if ([[self.contexts allValues] count] > 0)
        return YES;
    return NO;
}

- (BOOL) isDefault {
    if (self.application == nil)
        return YES;
    if ([self.application.defaultLocale isEqual: self.locale])
        return YES;
    return NO;
}

- (NSString *) htmlDirection {
    if (self.rightToLeft == YES)
        return @"rtl";
    return @"ltr";
}

- (NSString *) htmlAlignmentWithLtrDefault: (NSString *) defaultAlignment {
    if (self.rightToLeft == YES)
        return defaultAlignment;
    if ([defaultAlignment isEqual: @"right"])
        return @"left";
    return @"right";
}

- (NSString *) name {
    return self.englishName;
}

- (NSString *) fullName {
    if (self.nativeName == nil || [self.englishName isEqualToString:self.nativeName]) {
        return self.englishName;
    }
    return [NSString stringWithFormat:@"%@ - %@", self.englishName, self.nativeName];
}

- (id) translate:(NSString *)label
     description:(NSString *)description
          tokens:(NSDictionary *)tokens
         options:(NSDictionary *)options
{
    TMLTranslationKey *translationKey = [[TMLTranslationKey alloc] init];
    translationKey.label = label;
    translationKey.keyDescription = description;
    
    NSString *keyLocale = options[TMLLocaleOptionName];
    if (keyLocale == nil) {
        keyLocale = [TML defaultLocale];
    }
    translationKey.locale = keyLocale;
    
    NSNumber *keyLevel = options[TMLLevelOptionName];
    if (keyLevel != nil) {
        translationKey.level = [keyLevel integerValue];
    }
    
    TMLSource *source = nil;
    NSString *sourceKey = options[TMLSourceOptionName];
    if (sourceKey != nil) {
        [[TML sharedInstance] currentSource];
    }
    if (sourceKey) {
        source = (TMLSource *) [self.application sourceForKey:sourceKey];
    }
    
    return [self translateKey:translationKey
                       source:source
                       tokens:tokens
                      options:options];
}

- (id) translateKey:(TMLTranslationKey *)translationKey
             source:(TMLSource *)source
             tokens:(NSDictionary *)tokens
            options:(NSDictionary *)options
{
    id sender = options[TMLSenderOptionName];
    NSString *reuseIdentifier = options[TMLReuseIdentifierOptionName];
    NSMutableDictionary *reuseInfo = nil;
    if (sender != nil && reuseIdentifier != nil) {
        reuseInfo = [NSMutableDictionary dictionary];
        if (translationKey != nil) {
            reuseInfo[TMLTranslationKeyInfoKey] = translationKey;
        }
        if (source != nil) {
            reuseInfo[TMLSourceInfoKey] = source;
        }
        if (tokens != nil) {
            reuseInfo[TMLTokensInfoKey] = tokens;
        }
        if (options != nil) {
            reuseInfo[TMLOptionsInfoKey] = options;
        }
        [sender registerTMLInfo:reuseInfo forReuseIdentifier:reuseIdentifier];
    }
    
    NSMutableDictionary *ourTokens = [NSMutableDictionary dictionary];
    if (tokens != nil) {
        [ourTokens addEntriesFromDictionary:tokens];
    }
    
    id viewingUser = ourTokens[TMLViewingUserTokenName];
    if (viewingUser == nil) {
        viewingUser = [[TML configuration] defaultTokenValueForName:TMLViewingUserTokenName];
    }
    if (viewingUser != nil) {
        ourTokens[TMLViewingUserTokenName] = viewingUser;
    }
    
    
    void(^registerResultBlock)(id result) = ^(id result){
        if (sender != nil && result != nil) {
            [sender registerTMLTranslationKey:translationKey forLocalizedString:result];
        }
    };
    
    id result = nil;
    if (source != nil) {
        NSArray *translations = [source translationsForKey:translationKey.key inLanguage:self.locale];
        if (translations != nil) {
            [translationKey setTranslations:translations];
            result = [translationKey translateToLanguage:self
                                                tokens:ourTokens
                                               options:options];
            registerResultBlock(result);
            return result;
        }
        [[TML sharedInstance] registerMissingTranslationKey:translationKey forSourceKey:source.key];
    }
    
    TML *tml = [TML sharedInstance];
    NSArray *matchedTranslations = [tml translationsForKey:translationKey.key locale:self.locale];
    if (matchedTranslations != nil) {
        [translationKey setTranslations:matchedTranslations];
        result = [translationKey translateToLanguage:self
                                              tokens:ourTokens
                                             options:options];
        registerResultBlock(result);
        return result;
    }
    
    if (![tml isTranslationKeyRegistered:translationKey.key]) {
        [tml registerMissingTranslationKey:translationKey];
    }
    
    result = [translationKey translateToLanguage:self
                                          tokens:ourTokens
                                         options:options];
    
    registerResultBlock(result);
    
    return result;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"<%@:%@: %p>", [self class], self.locale, self];
}

@end
