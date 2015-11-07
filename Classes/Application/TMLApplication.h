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
#import "TMLApiClient.h"

@class TMLPostOffice, TMLLanguage, TMLSource;

@interface TMLApplication : TMLBase

// Application host - points to the TMLHub server
@property(nonatomic, strong) NSString *host;

// Application key - must always be specified
@property(nonatomic, strong) NSString *key;

// Application secret - only necessary for submitting keys
@property(nonatomic, strong) NSString *secret;

// Application access token
@property(nonatomic, strong) NSString *accessToken;

// API Client
@property(nonatomic, strong) TMLApiClient *apiClient;

// PostOffice Client
@property(nonatomic, strong) TMLPostOffice *postOffice;

// Holds scheduler for background tasks
@property(nonatomic, strong) NSTimer *scheduler;

// Application name
@property(nonatomic, strong) NSString *name;

// Application default locale
@property(nonatomic, strong) NSString *defaultLocale;

// Application threshold
@property(nonatomic, strong) NSNumber *threshold;

// Application features
@property(nonatomic, strong) NSDictionary *features;

// Application tools url
@property(nonatomic, strong) NSDictionary *tools;

// Languages by locale
@property(nonatomic, strong) NSMutableDictionary *languagesByLocales;

// Sources by keys
@property(nonatomic, strong) NSMutableDictionary *sourcesByKeys;

// Translations by keys
@property(nonatomic, strong) NSDictionary *translations;

// Missing translation keys
@property(nonatomic, strong) NSMutableDictionary *missingTranslationKeysBySources;

- (id) initWithToken: (NSString *) token host: (NSString *) appHost;

- (void) loadTranslationsForLocale: (NSString *) locale
                   completionBlock:(TMLAPIResponseHandler)completionBlock;

- (void) resetTranslations;

- (TMLLanguage *) languageForLocale: (NSString *) locale;

- (TMLSource *) sourceForKey: (NSString *) sourceKey andLocale: (NSString *) locale;

- (BOOL) isTranslationCacheEmpty;

- (NSArray *) translationsForKey:(NSString *) translationKey inLanguage: (NSString *) locale;

- (BOOL) isTranslationKeyRegistered: (NSString *) translationKey;

- (void) registerMissingTranslationKey: (NSObject *) translationKey;

- (void) registerMissingTranslationKey: (NSObject *) translationKey forSource: (NSObject *) source;

- (void) submitMissingTranslationKeys;

- (void) log;

@end

