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
#import "TmlApplication.h"
#import "TmlLanguage.h"
#import "TmlSource.h"
#import "TmlConfiguration.h"
#import "TmlCache.h"
#import "TmlLogger.h"

#define TmlLanguageChangedNotification @"TmlLanguageChangedNotification"
#define TmlIsReachableNotification @"TmlIsReachableNotification"
#define TmlIsUnreachableNotification @"TmlIsUnreachableNotification"

@protocol TmlDelegate;

@interface Tml : NSObject

// Holds Tml configuration settings
@property(nonatomic, strong) TmlConfiguration *configuration;

// Holds reference to the cache object
@property(nonatomic, strong) TmlCache *cache;

// Holds the application information
@property(nonatomic, strong) TmlApplication *currentApplication;

// Holds default language of the application
@property(nonatomic, strong) TmlLanguage *defaultLanguage;

// Holds current language, per user selection
@property(nonatomic, strong) TmlLanguage *currentLanguage;

// Holds the current source key
@property(nonatomic, strong) NSString *currentSource;

// Holds the current user object
@property(nonatomic, strong) NSObject *currentUser;

// Holds block options
@property(nonatomic, strong) NSMutableArray *blockOptions;

// Tml delegate
@property(nonatomic, assign) id <TmlDelegate> delegate;

+ (Tml *) sharedInstance;

+ (Tml *) sharedInstanceWithToken: (NSString *) token;

+ (Tml *) sharedInstanceWithToken: (NSString *) token launchOptions: (NSDictionary *) launchOptions;

// Configuration methods
+ (void) configure:(void (^)(TmlConfiguration *config)) changes;

// Returns configuration
+ (TmlConfiguration *) configuration;

// Returns cache
+ (TmlCache *) cache;

// HTML Translation Methods
+ (NSString *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options;

// Attributed String Translation Methods
+ (NSAttributedString *) translateAttributedString:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options;

// Date localization methods
+ (NSString *) localizeDate:(NSDate *) date withFormat:(NSString *) format andDescription: (NSString *) description;

/************************************************************************************
 ** Block Options
 ************************************************************************************/

+ (void) beginBlockWithOptions:(NSDictionary *) options;

+ (NSObject *) blockOptionForKey: (NSString *) key;

+ (void) endBlockWithOptions;

/************************************************************************************
 Class Methods
 ************************************************************************************/

+ (TmlApplication *) currentApplication;

+ (TmlLanguage *) defaultLanguage;

+ (TmlLanguage *) currentLanguage;

+ (void) changeLocale: (NSString *) locale success: (void (^)()) success failure: (void (^)(NSError *error)) failure;

+ (void) reloadTranslations;

@end

/************************************************************************************
 Tml Delegate
 ************************************************************************************/

@protocol TmlDelegate <NSObject>

- (void) tr8nDidLoadTranslations;

@end

/************************************************************************************
 Default Tml Macros
 ************************************************************************************/

#define TmlTranslationKey(label, description) \
    [TmlTranslationKey generateKeyForLabel: label andDescription: description]

#define TmlLocalizedString(label) \
    [Tml translate: label withDescription: nil andTokens: @{} andOptions: @{}]

#define TmlLocalizedStringWithDescription(label, description) \
    [Tml translate: label withDescription: description andTokens: @{} andOptions: @{}]

#define TmlLocalizedStringWithDescriptionAndTokens(label, description, tokens) \
    [Tml translate: label withDescription: description andTokens: tokens andOptions: @{}]

#define TmlLocalizedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options) \
    [Tml translate: label withDescription: description andTokens: tokens andOptions: options]

#define TmlLocalizedStringWithTokens(label, tokens) \
    [Tml translate: label withDescription: nil andTokens: tokens andOptions: nil]

#define TmlLocalizedStringWithTokensAndOptions(label, tokens, options) \
    [Tml translate: label withDescription: nil andTokens: tokens andOptions: options]

#define TmlLocalizedStringWithOptions(label, options) \
    [Tml translate: label withDescription: nil andTokens: @{} andOptions: options]

#define TmlLocalizedStringWithDescriptionAndOptions(label, description, options) \
    [Tml translate: label withDescription: description andTokens: @{} andOptions: options]

#define TmlLocalizedAttributedString(label) \
    [Tml translateAttributedString: label withDescription: nil andTokens: @{} andOptions: @{}]

#define TmlLocalizedAttributedStringWithDescription(label, description) \
    [Tml translateAttributedString: label withDescription: description andTokens: @{} andOptions: @{}]

#define TmlLocalizedAttributedStringWithDescriptionAndTokens(label, description, tokens) \
    [Tml translateAttributedString: label withDescription: description andTokens: tokens andOptions: @{}]

#define TmlLocalizedAttributedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options) \
    [Tml translateAttributedString: label withDescription: description andTokens: tokens andOptions: options]

#define TmlLocalizedAttributedStringWithTokens(label, tokens) \
    [Tml translateAttributedString: label withDescription: nil andTokens: tokens andOptions: nil]

#define TmlLocalizedAttributedStringWithTokensAndOptions(label, tokens, options) \
    [Tml translateAttributedString: label withDescription: nil andTokens: tokens andOptions: options]

#define TmlLocalizedAttributedStringWithOptions(label, options) \
    [Tml translateAttributedString: label withDescription: nil andTokens: @{} andOptions: options]

#define TmlBeginSource(name) \
    [Tml beginBlockWithOptions: @{@"source": name}];

#define TmlEndSource \
    [Tml endBlockWithOptions];

#define TmlBeginBlockWithOptions(options) \
    [Tml beginBlockWithOptions:options];

#define TmlEndBlockWithOptions \
    [Tml endBlockWithOptions];

#define TmlLocalizedDateWithFormat(date, format) \
    [Tml localizeDate: date withFormat: format andDescription: nil];

#define TmlLocalizedDateWithFormatAndDescription(date, format, description) \
[Tml localizeDate: date withFormat: format andDescription: description];

#define TmlLocalizedDateWithFormatKey(date, formatKey) \
    [Tml localizeDate: date withFormatKey: formatKey andDescription: nil];

#define TmlLocalizedDateWithFormatKeyAndDescription(date, formatKey, description) \
    [Tml localizeDate: date withFormatKey: formatKey andDescription: description];

/************************************************************************************
 Overload the defeault localization macros
 ************************************************************************************/

#undef NSLocalizedString
#define NSLocalizedString(key, comment) \
    [Tml translate: key withDescription: comment]

#undef NSLocalizedStringFromTable
#define NSLocalizedStringFromTable(key, tbl, comment) \
    [Tml translate: key withDescription: comment]

#undef NSLocalizedStringFromTableInBundle
#define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) \
    [Tml translate: key withDescription: comment]

#undef NSLocalizedStringWithDefaultValue
#define NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) \
    [Tml translate: key withDescription: comment]

