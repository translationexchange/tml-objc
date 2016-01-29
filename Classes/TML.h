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
#import "TMLApplication.h"
#import "TMLBundle.h"

@protocol TMLDelegate <NSObject>
@optional
- (UIGestureRecognizer *)gestureRecognizerForInlineTranslation;
- (UIGestureRecognizer *)gestureRecognizerForTranslationActivation;
@end

@class TMLApplication, TMLBundle, TMLConfiguration, TMLLanguage, TMLSource, TMLAPIClient, TMLTranslationKey;

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

@property(nonatomic, weak) id<TMLDelegate>delegate;

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

+ (NSString *) previousLocale;
- (NSString *) previousLocale;

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
 *  @param options     Optional options
 *
 *  @return Localized string representing the date
 */
+ (NSString *) localizeDate:(NSDate *)date
                 withFormat:(NSString *)format
                description:(NSString *)description
                    options:(NSDictionary *)options;

/**
 *  Returns localized string representation of a date with given format and optional description.
 *  Example of a format string is "MM/dd/yyyy at h:m".
 *  Adding attributes: "[bold: MM/dd/yyyy] at h:m"
 *
 *  @param date        Date to be localized
 *  @param format      Date format (e.g. "MM/dd/yyyy at h:m")
 *  @param description Optional description
 *  @param options     Optional options
 *
 *  @return Localized attributed string representing the date
 */
+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                     withFormat:(NSString *)format
                                    description:(NSString *)description
                                        options:(NSDictionary *)options;

/**
 *  Returns localized string representation of a date with tokenized format, e.g.:
 *  "{months_padded}/{days_padded}/{years} at {hours}:{minutes}"
 *
 *  @param date            Date to be localized
 *  @param tokenizedFormat Tokenized format (e.g. "{months_padded}/{days_padded}/{years} at {hours}:{minutes}")
 *  @param description     Optional description
 *  @param options         Optional options
 *
 *  @return Localized string representation of the date
 */
+ (NSString *) localizeDate:(NSDate *)date
        withTokenizedFormat:(NSString *)tokenizedFormat
                description:(NSString *)description
                    options:(NSDictionary *)options;

/**
 *  Returns localized attributed string of a date with tokenized format, e.g.
 *  "{days} {month_name::gen} at [bold: {hours}:{minutes}] {am_pm}"
 *
 *  @param date            Date to be localized
 *  @param tokenizedFormat Tokenized format (e.g. "{days} {month_name::gen} at [bold: {hours}:{minutes}] {am_pm}")
 *  @param description     Optional description
 *  @param options         Optional options
 *
 *  @return Localized attributed string representation of the date
 */
+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                            withTokenizedFormat:(NSString *)tokenizedFormat
                                    description:(NSString *)description
                                        options:(NSDictionary *)options;

/**
 *  Returns localized string representation of a date using pre-configured format.
 *  The format is obtained from configuration object, using provided format name.
 *
 *  @param date        Date to be localized
 *  @param formatName  Format name as it is defined in the configuration
 *  @param description Optional description
 *  @param options     Optional options
 *
 *  @return Localized string representation of the date
 */
+ (NSString *) localizeDate:(NSDate *)date
             withFormatName:(NSString *)formatName
                description:(NSString *)description
                    options:(NSDictionary *)options;

/**
 *  Returns localized attributed string representation of a date using pre-configured format.
 *  The format is obtained from configuration object, using provided format name.
 *
 *  @param date        Date to be localized
 *  @param formatName  Format name as it is defined in the configuration
 *  @param description Optional description
 *  @param options     Optional options
 *
 *  @return Localized attributed string representation of the date
 */
+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description
                                        options:(NSDictionary *)options;

- (NSArray *) translationsForKey:(NSString *)translationKey
                          locale:(NSString *)locale;

- (NSArray *)translationKeysMatchingString:(NSString *)string
                                    locale:(NSString *)locale;

- (BOOL) isTranslationKeyRegistered:(NSString *)translationKey;

- (void) registerMissingTranslationKey: (TMLTranslationKey *) translationKey;

- (void) registerMissingTranslationKey:(TMLTranslationKey *)translationKey forSourceKey:(NSString *)sourceKey;

- (BOOL) hasLocalTranslationsForLocale:(NSString *)locale;

- (void)registerObjectWithLocalizedStrings:(id)object;

- (void)registerObjectWithReusableLocalizedStrings:(id)object;

@property(nonatomic, readonly, getter=isInlineTranslationsEnabled) BOOL inlineTranslationsEnabled;

- (void) removeLocalizationData;

#pragma mark - Block options

+ (void) beginBlockWithOptions:(NSDictionary *)options;

+ (NSObject *) blockOptionForKey:(NSString *)key;

+ (void) endBlockWithOptions;

#pragma mark - Presenting View Controllers

+ (void)presentLanguageSelectorController;

+ (void)presentTranslatorViewControllerWithTranslationKey:(NSString *)translationKey;

@end


#pragma mark - 
#pragma mark Default TML Macros

id TMLLocalize(NSDictionary *options, NSString *string, ...);
id TMLLocalizeDate(NSDictionary *options, NSDate *date, NSString *format, ...);

#define TMLLanguages()\
[[[TML sharedInstance] application] languages]

#define TMLLocales()\
[[[[TML sharedInstance] application] languages] valueForKeyPath:@"locale"]

#define TMLAvailableLocales()\
[[[TML sharedInstance] currentBundle] availableLocales]

#define TMLCurrentLanguage()\
[[TML sharedInstance] currentLanguage]

#define TMLCurrentLocale()\
[[TML sharedInstance] currentLocale]

#define TMLLocalizedString(string,...)\
(NSString *)TMLLocalize(@{TMLSenderOptionName: self}, string, ##__VA_ARGS__, NULL)

#define TMLLocalizedStringWithReuseIdenitifer(string, reuseIdentifier, ...)\
(NSString *)TMLLocalize(@{TMLSenderOptionName: self, TMLReuseIdentifierOptionName: reuseIdentifier}, string, ##__VA_ARGS__, NULL)

#define TMLLocalizedAttributedString(string,...)\
(NSAttributedString *)TMLLocalize(@{TMLSenderOptionName: self, TMLTokenFormatOptionName: TMLAttributedTokenFormatString}, string, ##__VA_ARGS__, NULL)

#define TMLLocalizedAttributedStringWithReuseIdenitifer(string, reuseIdentifier, ...)\
(NSAttributedString *)TMLLocalize(@{TMLSenderOptionName: self, TMLReuseIdentifierOptionName: reuseIdentifier, TMLTokenFormatOptionName: TMLAttributedTokenFormatString}, string, ##__VA_ARGS__, NULL)

#define TMLLocalizedDate(date, format, ...) \
(NSString *)TMLLocalizeDate(@{TMLSenderOptionName: self}, date, format, ##__VA_ARGS__, NULL)

#define TMLLocalizedDateWithReuseIdenitifer(date, format, reuseIdentifier, ...) \
(NSString *)TMLLocalizeDate(@{TMLSenderOptionName: self, TMLReuseIdentifierOptionName: reuseIdentifier}, date, format, ##__VA_ARGS__, NULL)

#define TMLLocalizedAttributedDate(date, format, ...) \
(NSString *)TMLLocalizeDate(@{TMLSenderOptionName: self, TMLTokenFormatOptionName: TMLAttributedTokenFormatString}, date, format, ##__VA_ARGS__, NULL)

#define TMLLocalizedAttributedDateWithReuseIdenitifer(date, format, reuseIdentifier, ...) \
(NSString *)TMLLocalizeDate(@{TMLSenderOptionName: self, TMLReuseIdentifierOptionName: reuseIdentifier, TMLTokenFormatOptionName: TMLAttributedTokenFormatString}, date, format, ##__VA_ARGS__, NULL)

#define TMLBeginSource(name) \
    [TML beginBlockWithOptions: @{TMLSourceOptionName: name}]

#define TMLEndSource() \
    [TML endBlockWithOptions]

#define TMLBeginBlockWithOptions(opts) \
    [[TML sharedInstance] beginBlockWithOptions:opts]

#define TMLEndBlockWithOptions() \
    [[TML sharedInstance] endBlockWithOptions];

#define TMLPresentLanguagePicker() \
[[TML sharedInstance] presentLanguageSelectorController]