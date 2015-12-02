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

@protocol TMLDelegate;

@interface TML : NSObject

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

#pragma mark - Sources

/**
 *  Holds the current source key
 */
@property(nonatomic, strong) NSString *currentSource;

+ (NSString *) currentSource;

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

#pragma mark - Localizing

/**
 *  Localizes string with description and optional tokens
 *
 *  @param string      String to localize
 *  @param description Optional description
 *  @param tokens      Optional tokens
 *  @param options     Optional options
 *
 *  @return Localized strings
 */
+ (NSString *) localizeString:(NSString *)string
                  description:(NSString *)description
                       tokens:(NSDictionary *)tokens
                      options:(NSDictionary *)options;

/**
 *  Attributed String Translation Methods
 *
 *  @param attributedString Attributed string to localize
 *  @param description      Optional description
 *  @param tokens           Optional token
 *  @param options          Optional options
 *
 *  @return Localized attributed string
 */
+ (NSAttributedString *) localizeAttributedString:(NSString *)attributedString
                                      description:(NSString *)description
                                           tokens:(NSDictionary *)tokens
                                          options:(NSDictionary *)options;

/**
 *  Returns localized string representation of a date with given format and optional description.
 *  Example of a format string is "MM/dd/yyyy at h:m"
 *
 *  @param date        Date to be localized
 *  @param format      Date format (e.g. "MM/dd/yyyy at h:m")
 *  @param description Optional description
 *
 *  @return Localized string representing the date
 */
+ (NSString *) localizeDate:(NSDate *)date
                 withFormat:(NSString *)format
                description:(NSString *)description;

/**
 *  Returns localized string representation of a date with given format and optional description.
 *  Example of a format string is "MM/dd/yyyy at h:m".
 *  Adding attributes: "[bold: MM/dd/yyyy] at h:m"
 *
 *  @param date        Date to be localized
 *  @param format      Date format (e.g. "MM/dd/yyyy at h:m")
 *  @param description Optional description
 *
 *  @return Localized attributed string representing the date
 */
+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                     withFormat:(NSString *)format
                                    description:(NSString *)description;

/**
 *  Returns localized string representation of a date with tokenized format, e.g.:
 *  "{months_padded}/{days_padded}/{years} at {hours}:{minutes}"
 *
 *  @param date            Date to be localized
 *  @param tokenizedFormat Tokenized format (e.g. "{months_padded}/{days_padded}/{years} at {hours}:{minutes}")
 *  @param description     Optional description
 *
 *  @return Localized string representation of the date
 */
+ (NSString *) localizeDate:(NSDate *)date
        withTokenizedFormat:(NSString *)tokenizedFormat
                description:(NSString *)description;

/**
 *  Returns localized attributed string of a date with tokenized format, e.g.
 *  "{days} {month_name::gen} at [bold: {hours}:{minutes}] {am_pm}"
 *
 *  @param date            Date to be localized
 *  @param tokenizedFormat Tokenized format (e.g. "{days} {month_name::gen} at [bold: {hours}:{minutes}] {am_pm}")
 *  @param description     Optional description
 *
 *  @return Localized attributed string representation of the date
 */
+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                            withTokenizedFormat:(NSString *)tokenizedFormat
                                    description:(NSString *)description;

/**
 *  Returns localized string representation of a date using pre-configured format.
 *  The format is obtained from configuration object, using provided format name.
 *
 *  @param date        Date to be localized
 *  @param formatName  Format name as it is defined in the configuration
 *  @param description Optional description
 *
 *  @return Localized string representation of the date
 */
+ (NSString *) localizeDate:(NSDate *)date
             withFormatName:(NSString *)formatName
                description:(NSString *)description;

/**
 *  Returns localized attributed string representation of a date using pre-configured format.
 *  The format is obtained from configuration object, using provided format name.
 *
 *  @param date        Date to be localized
 *  @param formatName  Format name as it is defined in the configuration
 *  @param description Optional description
 *
 *  @return Localized attributed string representation of the date
 */
+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description;

- (NSArray *) translationsForKey:(NSString *)translationKey
                          locale:(NSString *)locale;

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


#define TMLTranslationKeyMake(label, desc)\
    [TMLTranslationKey generateKeyForLabel:label description:desc]

#define TMLLocalizedString(label) \
    [TML localizeString:label description:nil tokens:nil options:nil]

#define TMLLocalizedStringWithDescription(label, desc) \
    [TML localizeString:label description:desc tokens:nil options:nil]

#define TMLLocalizedStringWithDescriptionAndTokens(label, desc, tkns) \
    [TML localizeString:label description:desc tokens:tkns options:nil]

#define TMLLocalizedStringWithDescriptionAndTokensAndOptions(label, desc, tkns, opts) \
    [TML localizeString:label description:desc tokens:tkns options:opts]

#define TMLLocalizedStringWithTokens(label, tkns) \
    [TML localizeString:label description:nil tokens:tkns options:nil]

#define TMLLocalizedStringWithTokensAndOptions(label, tkns, opts) \
    [TML localizeString:label description:nil tokens:tkns options:opts]

#define TMLLocalizedStringWithOptions(label, opts) \
    [TML localizeString:label description:nil tokens:nil options:opts]

#define TMLLocalizedStringWithDescriptionAndOptions(label, desc, opts) \
    [TML localizeString:label description:desc tokens:nil options:opts]

#define TMLLocalizedAttributedString(label) \
    [TML localizeAttributedString: label description:nil tokens:nil options:nil]

#define TMLLocalizedAttributedStringWithDescription(label, desc) \
    [TML localizeAttributedString: label description:desc tokens:nil options:nil]

#define TMLLocalizedAttributedStringWithDescriptionAndTokens(label, desc, tkns) \
    [TML localizeAttributedString: label description:desc tokens:tkns options:nil]

#define TMLLocalizedAttributedStringWithDescriptionAndTokensAndOptions(label, desc, tkns, opts) \
    [TML localizeAttributedString: label description:desc tokens:tkns options:opts]

#define TMLLocalizedAttributedStringWithTokens(label, tkns) \
    [TML localizeAttributedString: label description:nil tokens:tkns options:nil]

#define TMLLocalizedAttributedStringWithTokensAndOptions(label, tkns, opts) \
    [TML localizeAttributedString: label description:nil tokens:tkns options:opts]

#define TMLLocalizedAttributedStringWithOptions(label, opts) \
    [TML localizeAttributedString: label description:nil tokens:nil options:opts]

#define TMLBeginSource(name) \
    [TML beginBlockWithOptions: @{TMLSourceOptionName: name}];

#define TMLEndSource \
    [TML endBlockWithOptions];

#define TMLBeginBlockWithOptions(opts) \
    [TML beginBlockWithOptions:opts];

#define TMLEndBlockWithopts \
    [TML endBlockWithopts];

#define TMLLocalizedDateWithFormat(date, format) \
    [TML localizeDate: date withFormat: format andDescription: nil];

#define TMLLocalizedDateWithFormatAndDescription(date, format, desc) \
[TML localizeDate: date withFormat: format andDescription: description];

#define TMLLocalizedDateWithFormatKey(date, formatKey) \
    [TML localizeDate: date withFormatKey: formatKey andDescription: nil];

#define TMLLocalizedDateWithFormatKeyAndDescription(date, formatKey, desc) \
    [TML localizeDate: date withFormatKey: formatKey andDescription: description];
