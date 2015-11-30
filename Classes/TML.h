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

#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLLogger.h"
#import <Foundation/Foundation.h>

@class TMLAPIClient, TMLPostOffice, TMLTranslationKey, TMLBundle;

#pragma mark - Notifications
extern NSString * const TMLLanguageChangedNotification;
extern NSString * const TMLLocalizationDataChangedNotification;
extern NSString * const TMLDidStartSyncNotification;
extern NSString * const TMLDidFinishSyncNotification;
extern NSString * const TMLLocalizationUpdatesInstalledNotification;

#pragma mark - UserInfo Keys
extern NSString * const TMLLanguagePreviousLocaleUserInfoKey;

@protocol TMLDelegate;

@interface TML : NSObject

/**
 *  Holds the current source key
 */
@property(nonatomic, strong) NSString *currentSource;

/**
 *  Currently utilized localization bundle
 */
@property(nonatomic, readonly) TMLBundle *currentBundle;

/**
 *  Indicates whether in-app translation mode is enabled.
 *  Setting this to YES will utilize translations from the API server
 *  And would allow making translation changes from within the app.
 *  Setting this to NO would utilize published translations and not
 *  allow and translation changes.
 */
@property(nonatomic, assign) BOOL translationEnabled;

/**
 *  Holds the current user object
 */
@property(nonatomic, strong) NSObject *currentUser;

/**
 *  Holds block options
 */
@property(nonatomic, strong) NSMutableArray *blockOptions;

/**
 *  Instance of an API Client configured for current project
 */
@property(nonatomic, readonly) TMLAPIClient *apiClient;

/**
 *  Instance of PostOffice configuted for current project
 */
@property(nonatomic, readonly) TMLPostOffice *postOffice;

/**
 *  TML delegate
 */
@property(nonatomic, assign) id <TMLDelegate> delegate;

#pragma mark - Instance creation

+ (TML *) sharedInstance;

+ (TML *) sharedInstanceWithApplicationKey:(NSString *)applicationKey
                               accessToken:(NSString *)token;

+ (TML *) sharedInstanceWithConfiguration:(TMLConfiguration *)configuration;

#pragma mark - Application

/**
 *  Current application/project
 */
@property(nonatomic, readonly) TMLApplication *application;

/**
 *  Currently configured application/project
 *
 *  @return Instance of currently configured application or nil, of no application/project data has been loaded yet
 */
+ (TMLApplication *) application;

/**
 *  Application key used to configure TML upon initialization
 *
 *  @return Application key
 */
+ (NSString *) applicationKey;

#pragma mark - Configuration

/**
 *  Holds TML configuration settings
 */
@property(nonatomic, readonly) TMLConfiguration *configuration;

/**
 *  Modifies current configuration
 *
 *  @param changes Performs configuration changes within this block
 */
+ (void) configure:(void (^)(TMLConfiguration *config)) changes;

/**
 *  Current configuration object
 *
 *  @return Current configuration object
 */
+ (TMLConfiguration *) configuration;

#pragma mark - Languages and Locales

+ (NSString *) defaultLocale;
- (NSString *) defaultLocale;

+ (TMLLanguage *) defaultLanguage;
- (TMLLanguage *) defaultLanguage;

+ (NSString *) currentLocale;
- (NSString *) currentLocale;

+ (TMLLanguage *) currentLanguage;
- (TMLLanguage *) currentLanguage;

+ (void) changeLocale:(NSString *)locale completionBlock:(void(^)(BOOL success))completionBlock;
- (void) changeLocale:(NSString *)locale completionBlock:(void(^)(BOOL success))completionBlock;

+ (void) reloadTranslations;
- (void) reloadTranslations;

#pragma mark - Translating

/**
 *  HTML Translation
 *
 *  @param label       String to be translated
 *  @param description Optional description for the label
 *  @param tokens      Optional dictionary of translation tokens
 *  @param options     Optional dictionary of options
 *
 *  @return Translated string
 */
+ (NSString *) translate:(NSString *)label
         withDescription:(NSString *)description
               andTokens:(NSDictionary *)tokens
              andOptions:(NSDictionary *)options;

/**
 *  Attributed String Translation Methods
 *
 *  @param label       String to be translated
 *  @param description Optional description for the label
 *  @param tokens      Optional dictionary of translation tokens
 *  @param options     Optional dictionary of options
 *
 *  @return Translated string
 */
+ (NSAttributedString *) translateAttributedString:(NSString *)label
                                   withDescription:(NSString *)description
                                         andTokens:(NSDictionary *)tokens
                                        andOptions:(NSDictionary *)options;

/**
 *  Date localization methods
 *
 *  @param date        Date to be translated
 *  @param format      Date format
 *  @param description Optional description
 *
 *  @return Localized string representing the date
 */
+ (NSString *) localizeDate:(NSDate *)date
                 withFormat:(NSString *)format
             andDescription:(NSString *)description;

- (NSArray *) translationsForKey:(NSString *)translationKey locale:(NSString *)locale;

- (BOOL) isTranslationKeyRegistered:(NSString *)translationKey;

- (void) registerMissingTranslationKey: (TMLTranslationKey *) translationKey;

- (void) registerMissingTranslationKey:(TMLTranslationKey *)translationKey forSourceKey:(NSString *)sourceKey;

- (void) submitMissingTranslationKeys;

- (BOOL) hasLocalTranslationsForLocale:(NSString *)locale;

- (BOOL) isInlineTranslationsEnabled;

#pragma mark - Block options

+ (void) beginBlockWithOptions:(NSDictionary *)options;

+ (NSObject *) blockOptionForKey:(NSString *)key;

+ (void) endBlockWithOptions;

@end

#pragma mark - TML Delegate

@protocol TMLDelegate <NSObject>

- (void) tmlDidLoadTranslations;

@end


#pragma mark - 
#pragma mark Default TML Macros


#define TMLTranslationKey(label, description) \
    [TMLTranslationKey generateKeyForLabel: label andDescription: description]

#define TMLLocalizedString(label) \
    [TML translate: label withDescription: nil andTokens: @{} andOptions: @{}]

#define TMLLocalizedStringWithDescription(label, description) \
    [TML translate: label withDescription: description andTokens: @{} andOptions: @{}]

#define TMLLocalizedStringWithDescriptionAndTokens(label, description, tokens) \
    [TML translate: label withDescription: description andTokens: tokens andOptions: @{}]

#define TMLLocalizedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options) \
    [TML translate: label withDescription: description andTokens: tokens andOptions: options]

#define TMLLocalizedStringWithTokens(label, tokens) \
    [TML translate: label withDescription: nil andTokens: tokens andOptions: nil]

#define TMLLocalizedStringWithTokensAndOptions(label, tokens, options) \
    [TML translate: label withDescription: nil andTokens: tokens andOptions: options]

#define TMLLocalizedStringWithOptions(label, options) \
    [TML translate: label withDescription: nil andTokens: @{} andOptions: options]

#define TMLLocalizedStringWithDescriptionAndOptions(label, description, options) \
    [TML translate: label withDescription: description andTokens: @{} andOptions: options]

#define TMLLocalizedAttributedString(label) \
    [TML translateAttributedString: label withDescription: nil andTokens: @{} andOptions: @{}]

#define TMLLocalizedAttributedStringWithDescription(label, description) \
    [TML translateAttributedString: label withDescription: description andTokens: @{} andOptions: @{}]

#define TMLLocalizedAttributedStringWithDescriptionAndTokens(label, description, tokens) \
    [TML translateAttributedString: label withDescription: description andTokens: tokens andOptions: @{}]

#define TMLLocalizedAttributedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options) \
    [TML translateAttributedString: label withDescription: description andTokens: tokens andOptions: options]

#define TMLLocalizedAttributedStringWithTokens(label, tokens) \
    [TML translateAttributedString: label withDescription: nil andTokens: tokens andOptions: nil]

#define TMLLocalizedAttributedStringWithTokensAndOptions(label, tokens, options) \
    [TML translateAttributedString: label withDescription: nil andTokens: tokens andOptions: options]

#define TMLLocalizedAttributedStringWithOptions(label, options) \
    [TML translateAttributedString: label withDescription: nil andTokens: @{} andOptions: options]

#define TMLBeginSource(name) \
    [TML beginBlockWithOptions: @{@"source": name}];

#define TMLEndSource \
    [TML endBlockWithOptions];

#define TMLBeginBlockWithOptions(options) \
    [TML beginBlockWithOptions:options];

#define TMLEndBlockWithOptions \
    [TML endBlockWithOptions];

#define TMLLocalizedDateWithFormat(date, format) \
    [TML localizeDate: date withFormat: format andDescription: nil];

#define TMLLocalizedDateWithFormatAndDescription(date, format, description) \
[TML localizeDate: date withFormat: format andDescription: description];

#define TMLLocalizedDateWithFormatKey(date, formatKey) \
    [TML localizeDate: date withFormatKey: formatKey andDescription: nil];

#define TMLLocalizedDateWithFormatKeyAndDescription(date, formatKey, description) \
    [TML localizeDate: date withFormatKey: formatKey andDescription: description];
