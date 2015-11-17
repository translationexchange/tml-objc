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

#import <Foundation/Foundation.h>
#import "TMLBase.h"
#import "TMLAPIClient.h"

@class TMLPostOffice, TMLLanguage, TMLSource, TMLTranslation, TMLDecorationTokenizer, TMLConfiguration;

@interface TMLApplication : TMLBase

// Application identifier
@property (nonatomic, assign) NSInteger applicationID;

// Application key - must always be specified
@property(nonatomic, strong) NSString *key;

// Application secret - only necessary for submitting keys
@property(nonatomic, strong) NSString *secret;

// Application access token
@property(nonatomic, strong) NSString *accessToken;

// Application name
@property(nonatomic, strong) NSString *name;

// Application default locale
@property(nonatomic, strong) NSString *defaultLocale;

// Application threshold
@property(nonatomic, assign) NSInteger threshold;

// Application features
@property(nonatomic, strong) NSDictionary *features;

// Application tools url
@property(nonatomic, strong) NSDictionary *tools;

// Languages
@property(nonatomic, strong) NSArray <TMLLanguage *>*languages;

// Sources by keys
@property(nonatomic, strong) NSArray <TMLSource *>*sources;

/**
 *  Translations organized by location, then by translation key (@see TMLTranslationKey)
 */
@property(nonatomic, strong) NSDictionary *translations;

#pragma mark - Internal Use
@property(nonatomic, readonly) TMLConfiguration *configuration;
@property(nonatomic, strong) NSMutableDictionary <NSString *, NSMutableSet *>*missingTranslationKeysBySources;
@property(nonatomic, strong) TMLAPIClient *apiClient;
@property(nonatomic, strong) TMLPostOffice *postOffice;

- (id) initWithAccessToken:(NSString *)accessToken configuration:(TMLConfiguration *)configuration;

- (BOOL) isEqualToApplication:(TMLApplication *)application;

- (void) loadTranslationsForLocale: (NSString *) locale
                   completionBlock:(void(^)(BOOL success))completionBlock;

- (void) resetTranslations;

- (TMLLanguage *) languageForLocale:(NSString *)locale;

- (TMLSource *) sourceForKey:(NSString *)sourceKey;

- (NSArray *) translationsForKey:(NSString *)translationKey locale:(NSString *)locale;

- (BOOL) isTranslationKeyRegistered:(NSString *)translationKey;

- (void) registerMissingTranslationKey: (TMLTranslationKey *) translationKey;

- (void) registerMissingTranslationKey:(TMLTranslationKey *)translationKey forSourceKey:(NSString *)sourceKey;

- (void) submitMissingTranslationKeys;

@end

