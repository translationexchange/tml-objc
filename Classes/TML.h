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
#import "TMLLogger.h"
#import "TMLAPIClient.h"

@class TMLConfiguration, TMLLanguage, TMLApplication;

#define TMLLanguageChangedNotification @"TMLLanguageChangedNotification"
#define TMLIsReachableNotification @"TMLIsReachableNotification"
#define TMLIsUnreachableNotification @"TMLIsUnreachableNotification"

@protocol TMLDelegate;

@interface TML : NSObject

// Holds TML configuration settings
@property(nonatomic, strong) TMLConfiguration *configuration;

// Holds the application information
@property(nonatomic, strong) TMLApplication *currentApplication;

// Holds default language of the application
@property(nonatomic, strong) TMLLanguage *defaultLanguage;

// Holds current language, per user selection
@property(nonatomic, strong) TMLLanguage *currentLanguage;

// Holds the current source key
@property(nonatomic, strong) NSString *currentSource;

// Holds the current user object
@property(nonatomic, strong) NSObject *currentUser;

// Holds block options
@property(nonatomic, strong) NSMutableArray *blockOptions;

// TML delegate
@property(nonatomic, assign) id <TMLDelegate> delegate;

+ (TML *) sharedInstance;

+ (TML *) sharedInstanceWithToken: (NSString *) token;

+ (TML *) sharedInstanceWithToken: (NSString *) token launchOptions: (NSDictionary *) launchOptions;

// Configuration methods
+ (void) configure:(void (^)(TMLConfiguration *config)) changes;

// Returns configuration
+ (TMLConfiguration *) configuration;

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

+ (TMLApplication *) currentApplication;

+ (TMLLanguage *) defaultLanguage;

+ (TMLLanguage *) currentLanguage;

+ (void) changeLocale:(NSString *)locale completionBlock:(TMLAPIResponseHandler)completionBlock;

+ (void) reloadTranslations;

@end

/************************************************************************************
 TML Delegate
 ************************************************************************************/

@protocol TMLDelegate <NSObject>

- (void) tmlDidLoadTranslations;

@end

/************************************************************************************
 Default TML Macros
 ************************************************************************************/

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

/************************************************************************************
 Overload the defeault localization macros
 ************************************************************************************/

#undef NSLocalizedString
#define NSLocalizedString(key, comment) \
    [TML translate: key withDescription: comment]

#undef NSLocalizedStringFromTable
#define NSLocalizedStringFromTable(key, tbl, comment) \
    [TML translate: key withDescription: comment]

#undef NSLocalizedStringFromTableInBundle
#define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) \
    [TML translate: key withDescription: comment]

#undef NSLocalizedStringWithDefaultValue
#define NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) \
    [TML translate: key withDescription: comment]

