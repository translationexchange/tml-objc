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

@interface TMLApplication() {
    NSTimer *_timer;
}

@end

@implementation TMLApplication

- (id) initWithToken: (NSString *) token host: (NSString *) appHost {
    if (self = [super init]) {
        self.host = appHost;
        self.accessToken = token;
        self.apiClient = [[TMLAPIClient alloc] initWithApplication:self];
        self.postOffice = [[TMLPostOffice alloc] initWithApplication:self];
        
        [self updateAttributes:@{@"name": @"Loading...",
                                 @"default_locale": @"en-US",
                                 @"treshold": [NSNumber numberWithInt:0]}];
        
        [self load];
    }
    return self;
}

- (void)dealloc {
    [self stopSubmissionTimerIfNecessary];
}

- (id)copyWithZone:(NSZone *)zone {
    TMLApplication *aCopy = [[TMLApplication alloc] init];
    aCopy.host = [_host copyWithZone:zone];
    aCopy.key = [_key copyWithZone:zone];
    aCopy.secret = [_secret copyWithZone:zone];
    aCopy.accessToken = [_accessToken copyWithZone:zone];
    aCopy.apiClient = _apiClient;
    aCopy.postOffice = _postOffice;
    aCopy.name = [_name copyWithZone:zone];
    aCopy.defaultLocale = [_defaultLocale copyWithZone:zone];
    aCopy.threshold = [_threshold copyWithZone:zone];
    aCopy.features = [_features copyWithZone:zone];
    aCopy.tools = [_tools copyWithZone:zone];
    aCopy.languagesByLocales = [_languagesByLocales copyWithZone:zone];
    aCopy.sourcesByKeys = [_sourcesByKeys copyWithZone:zone];
    aCopy.translations = [_translations copyWithZone:zone];
    aCopy.missingTranslationKeysBySources = [_missingTranslationKeysBySources copyWithZone:zone];
    return aCopy;
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
    return ([self.host isEqualToString:application.host] == YES
            && [self.key isEqualToString:application.key] == YES
            && [self.secret isEqualToString:application.secret] == YES
            && [self.accessToken isEqualToString:application.accessToken] == YES);
}

- (void) updateAttributes: (NSDictionary *) attributes {
    self.key = [attributes objectForKey:@"key"];
    self.name = [attributes objectForKey:@"name"];
    self.defaultLocale = [attributes objectForKey:@"default_locale"];
    self.threshold = [attributes objectForKey:@"threshold"];
    self.features = [attributes objectForKey:@"features"];
    self.tools = [attributes objectForKey:@"tools"];

    self.translations = [NSMutableDictionary dictionary];
    self.languagesByLocales = [NSMutableDictionary dictionary];
    self.sourcesByKeys = [NSMutableDictionary dictionary];
    self.missingTranslationKeysBySources = [NSMutableDictionary dictionary];
}

- (void) load {
    [self.apiClient getProjectInfoWithOptions:@{TMLAPIOptionsIncludeDefinition: @YES}
                              completionBlock:^(NSDictionary *projectInfo, NSError *error) {
                                  if (projectInfo != nil) {
                                      [self updateAttributes:projectInfo];
                                  }
                              }];
}

- (BOOL) isTranslationCacheEmpty {
    return (self.translations == nil || [self.translations allKeys].count == 0);
}

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

- (BOOL) isTranslationKeyRegistered: (NSString *) translationKey {
    return self.translations[translationKey] != nil;
}

- (NSArray *) translationsForKey:(NSString *) translationKey inLanguage: (NSString *) locale {
    if (!self.translations && ![self.translations objectForKey:locale]) return nil;
    return [[self.translations objectForKey:locale] objectForKey:translationKey];
}

- (void) resetTranslations {
    self.translations = [NSMutableDictionary dictionary];
    self.sourcesByKeys = [NSMutableDictionary dictionary];
}

- (TMLLanguage *) languageForLocale: (NSString *) locale {
    TMLLanguage *lang = (self.languagesByLocales == nil) ? nil : self.languagesByLocales[locale];
    if (lang != nil) {
        return lang;
    }
    
    __block TMLLanguage *language = [[TMLLanguage alloc] initWithAttributes:@{@"locale": locale, @"application": self}];
    [self.apiClient getLanguageForLocale:locale
                                 options:nil
                         completionBlock:^(TMLLanguage *newLanguage, NSError *error) {
                             language = newLanguage;
                         }];
    [self.languagesByLocales setObject:language forKey:locale];
    
    TMLDebug(@"Language: %@", [language description]);
    
    return language;
}

- (TMLSource *) sourceForKey: (NSString *) sourceKey andLocale: (NSString *) locale {
    if (sourceKey == nil)
        return nil;
    
    if ([self.sourcesByKeys objectForKey:sourceKey] != nil) {
        return [self.sourcesByKeys objectForKey:sourceKey];
    }
    
    TMLSource *source = [[TMLSource alloc] initWithAttributes:@{@"key": sourceKey, @"application": self}];
    [source loadTranslationsForLocale:locale completionBlock:nil];
    [self.sourcesByKeys setObject:source forKey:sourceKey];
    
    return source;
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
                                           if (success == YES) {
                                               NSMutableDictionary *existingSources = self.sourcesByKeys;
                                               for (TMLSource *source in missingTranslations) {
                                                   [existingSources removeObjectForKey:source.key];
                                               }
                                           }
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
