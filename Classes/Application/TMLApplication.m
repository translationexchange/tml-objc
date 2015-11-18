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
#import "TMLAPIClient.h"
#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLPostOffice.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"
#import "NSString+TmlAdditions.h"
#import "TMLDataTokenizer.h"
#import "TMLAttributedDecorationTokenizer.h"

@interface TMLApplication() {
    NSTimer *_timer;
}
@property(nonatomic, readwrite) TMLConfiguration *configuration;

@end

@implementation TMLApplication

- (id) initWithAccessToken:(NSString *)accessToken configuration:(TMLConfiguration *)configuration
{
    if (self = [super init]) {
        self.accessToken = accessToken;
        if (configuration == nil) {
            configuration = [[TMLConfiguration alloc] init];
        }
        self.configuration = configuration;
        self.apiClient = [[TMLAPIClient alloc] initWithURL:configuration.apiURL
                                               accessToken:accessToken];
        self.postOffice = [[TMLPostOffice alloc] initWithApplication:self];
        [self load];
    }
    return self;
}

- (void)dealloc {
    [self stopSubmissionTimerIfNecessary];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.applicationID forKey:@"id"];
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.secret forKey:@"secret"];
    [aCoder encodeObject:self.accessToken forKey:@"access_token"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.defaultLocale forKey:@"defaultLocale"];
    [aCoder encodeInteger:self.threshold forKey:@"threshold"];
    [aCoder encodeObject:self.features forKey:@"features"];
    [aCoder encodeObject:self.tools forKey:@"tools"];
    [aCoder encodeObject:self.languages forKey:@"languages"];
    [aCoder encodeObject:self.translations forKey:@"translations"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.applicationID = [aDecoder decodeIntegerForKey:@"id"];
    self.key = [aDecoder decodeObjectForKey:@"key"];
    self.secret = [aDecoder decodeObjectForKey:@"secret"];
    self.accessToken = [aDecoder decodeObjectForKey:@"access_token"];
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.defaultLocale = [aDecoder decodeObjectForKey:@"defaultLocale"];
    self.threshold = [aDecoder decodeIntegerForKey:@"threshold"];
    self.features = [aDecoder decodeObjectForKey:@"features"];
    self.languages = [aDecoder decodeObjectForKey:@"languages"];
    self.translations = [aDecoder decodeObjectForKey:@"translations"];
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
    return self.applicationID == application.applicationID;
}

#pragma mark - Loading

- (void) load {
    [self.apiClient getProjectInfoWithOptions:@{TMLAPIOptionsIncludeDefinition: @YES}
                              completionBlock:^(NSDictionary *projectInfo, NSError *error) {
                                  if (projectInfo != nil) {
//                                      [self updateAttributes:projectInfo];
                                  }
                              }];
}

#pragma mark - Translations

- (void) updateTranslations:(NSDictionary *)translationInfo forLocale:(NSString *)locale {
    NSMutableDictionary *newTranslations = [self.translations mutableCopy];
    newTranslations[locale] = translationInfo;
    self.translations = newTranslations;
}

- (void) loadTranslationsForLocale: (NSString *) locale
                   completionBlock:(void(^)(BOOL success))completionBlock
{
    [self.apiClient getTranslationsForLocale:locale
                                      source:nil
                                     options:@{TMLAPIOptionsIncludeAll: @YES}
                             completionBlock:^(NSDictionary <NSString *,TMLTranslation *> *newTranslations, NSError *error) {
                                 BOOL success = NO;
                                 if (newTranslations != nil) {
                                     success = YES;
                                     [self updateTranslations:newTranslations forLocale:locale];
                                     [[NSNotificationCenter defaultCenter] postNotificationName:TMLLanguageChangedNotification
                                                                                         object: locale];
                                 }
                                 if (completionBlock != nil) {
                                     completionBlock(success);
                                 }
                             }];
}

- (NSArray *) translationsForKey:(NSString *)translationKey locale:(NSString *)locale {
    NSDictionary *translations = self.translations;
    if (translations.count == 0) {
        return nil;
    }
    NSDictionary *localeTranslations = translations[locale];
    return localeTranslations[translationKey];
}

- (void) resetTranslations {
    self.translations = [NSDictionary dictionary];
    self.sources= [NSArray array];
}

- (BOOL)isTranslationKeyRegistered:(NSString *)translationKey {
    NSDictionary *translations = self.translations;
    NSArray *results = [[translations allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key == %@", translationKey]];
    return results.count > 0;
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

- (void) registerMissingTranslationKey: (TMLTranslationKey *) translationKey {
    [self registerMissingTranslationKey:translationKey forSourceKey:nil];
}

- (void) registerMissingTranslationKey:(TMLTranslationKey *)translationKey
                          forSourceKey:(NSString *)sourceKey
{
    if (translationKey.label.length == 0) {
        TMLWarn(@"Tried to register missing translation for translationKey with empty label");
        return;
    }
    
    NSMutableDictionary *missingTranslations = self.missingTranslationKeysBySources;
    if (missingTranslations == nil) {
        missingTranslations = [NSMutableDictionary dictionary];
    }
    
    NSString *effectiveSourceKey = sourceKey;
    if (effectiveSourceKey == nil) {
        effectiveSourceKey = TMLSourceDefaultKey;
    }

    NSMutableSet *sourceKeys = [missingTranslations objectForKey:effectiveSourceKey];
    if (sourceKeys == nil) {
        sourceKeys = [NSMutableSet set];
    }
    
    [sourceKeys addObject:translationKey];
    missingTranslations[effectiveSourceKey] = sourceKeys;
    self.missingTranslationKeysBySources = missingTranslations;
 
    if ([missingTranslations count] > 0) {
        [self startSubmissionTimerIfNecessary];
    }
    else {
        [self stopSubmissionTimerIfNecessary];
    }
}

- (void) submitMissingTranslationKeys {
    if (self.missingTranslationKeysBySources == nil
        || [self.missingTranslationKeysBySources count] == 0) {
        [self stopSubmissionTimerIfNecessary];
        return;
    }

    TMLInfo(@"Submitting missing translations...");
    
    NSMutableDictionary *missingTranslations = self.missingTranslationKeysBySources;
    [self.apiClient registerTranslationKeysBySourceKey:missingTranslations
                                       completionBlock:^(BOOL success, NSError *error) {
//                                           if (success == YES && missingTranslations.count > 0) {
//                                               NSMutableDictionary *existingSources = [NSMutableDictionary dictionary];
//                                               for (TMLSource *source in existingSources) {
//                                                   existingSources[source.key] = source;
//                                               }
//                                               for (NSString *sourceKey in missingTranslations) {
//                                                   [existingSources removeObjectForKey:sourceKey];
//                                               }
//                                               self.sources = [existingSources allValues];
//                                           }
                                       }];
    
    [missingTranslations removeAllObjects];
}

#pragma mark - Timer
- (void)startSubmissionTimerIfNecessary {
    if (_timer != nil) {
        return;
    }
    _timer = [NSTimer timerWithTimeInterval:3.
                                     target:self
                                   selector:@selector(submitMissingTranslationKeys)
                                   userInfo:nil
                                    repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (void)stopSubmissionTimerIfNecessary {
    if (_timer != nil) {
        [_timer invalidate];
        _timer = nil;
    }
}

@end
