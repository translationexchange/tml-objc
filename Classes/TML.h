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
#import <UIKit/UIKit.h>

#import "TMLApplication.h"
#import "TMLBundle.h"
#import "TMLConfiguration.h"
#import "TMLTranslator.h"

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
 *
 *  Conversely, setting this to NO would utilize published translations and 
 *  disallow makging translation changes from within the app.
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

/**
 *  Returns shared TML instance. This is the main interface with TMLKit.
 *
 *  Note: TML must first be configured via +[TML sharedInstanceWithConfiguration:]
 *  or +[TML sharedInstanceWithApplicationKey:]. This call is mostly
 *  used when interfacing with TML. For common interactions there exist a number of
 *  C macros, as defined in TML.h.
 *
 *  @return Shared TML instance
 */
+ (TML *) sharedInstance;

/**
 *  Initializes TML and configures it with default configuration, using given
 *  application key.
 *
 *  See dashboard.translationexchange.com for Integration API keys.
 *
 *  Application key is a required parameter. Configuration is considered invalid
 *  if this key is empty or nil.
 *
 *  @param applicationKey Application key
 *
 *  @return Shared TML instance
 */
+ (TML *) sharedInstanceWithApplicationKey:(NSString *)applicationKey;

/**
 *  Initializes TML and configures it with given configuration object.
 *  It is a good idea to check configuration via -[TMLConfiguration isValidConfiguration].
 *
 *  See dashboard.translationexchange.com for Integration API keys.
 *
 *  Application key is a required parameter. Configuration is considered invalid
 *  if this key is empty or nil.
 *
 *  @param configuration Configuration
 *
 *  @return Shared TML instance
 */
+ (TML *) sharedInstanceWithConfiguration:(TMLConfiguration *)configuration;

+ (BOOL)isConfigured;

/**
 *  Current application/project
 */
@property(nonatomic, readonly) TMLApplication *application;

/**
 *  Holds TML configuration settings
 */
@property(nonatomic, readonly) TMLConfiguration *configuration;

@property(nonatomic, readonly) TMLTranslator *translator;

/**
 *  Holds the current source key
 */
@property(nonatomic, strong) NSString *currentSource;

#pragma mark - Languages and Locales

/**
 *  TMLLanguage corresponding to the default locale.
 *
 *  @see -[TML defaultLocale]
 *
 *  @return TMLLanguage corresponding to default locale.
 */
@property (readonly, nonatomic, strong) TMLLanguage *defaultLanguage;

/**
 *  TMLLanguage corresponding to current locale.
 *
 *  @see -[TML currentLocale]
 *
 *  @return TMLLanguage corresponding to current locale.
 */
@property (readonly, nonatomic, strong) TMLLanguage *currentLanguage;

/**
 *  TMLLanguage corresponding to given locale
 *
 *  @param locale Locale (such as "en", "ru", etc)
 *
 *  @return TMLLanguage corresponding to locale
 */
- (TMLLanguage *)languageForLocale:(NSString *)locale;

/**
 *  Default TML locale.
 *
 *  @return Default locale string
 */
@property (readonly, nonatomic, strong) NSString *defaultLocale;

/**
 *  Current locale. This is the locale that TML is currently utilizing.
 *
 *  If translation data is not available locally - and it is possible
 *  to retrieve it from CDN or via API, when using in-app translation,
 *  it will be downloaded asynchronous. You can use -[TML changeLocale:completionBlock:]
 *  method if you need to do something after the locale has actually changed.
 */
@property (nonatomic, strong) NSString *currentLocale;

/**
 *  Previous locale.
 *
 *  Current locale is captured in this property prior to changing to another locale.
 *
 *  @return Previous locale string.
 */
@property (readonly, nonatomic, strong) NSString *previousLocale;

/**
 *  Instructs TML to change current locale.
 *
 *  If translation data for the new locale is not available locally - an attempt will be made
 *  to download it (via published release, or, if using in-app translation - via API). 
 *  Upon completion completionBlock is called, if given.
 *
 *  @param locale          New locale
 *  @param completionBlock Completion block
 */
- (void) changeLocale:(NSString *)locale completionBlock:(void(^)(BOOL success))completionBlock;

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
- (NSString *) localizeString:(NSString *)string
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
- (NSAttributedString *) localizeAttributedString:(NSString *)attributedString
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
- (NSString *) localizeDate:(NSDate *)date
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
- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
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
- (NSString *) localizeDate:(NSDate *)date
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
- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
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
- (NSString *) localizeDate:(NSDate *)date
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
- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description
                                        options:(NSDictionary *)options;

/**
 *  Returns array of TMLTranslation objects for a given translation key (hash)
 *  in a given locale.
 *
 *  @param translationKey Translation key
 *  @param locale         Locale
 *
 *  @return Array of TMLTranslation objects
 */
- (NSArray *) translationsForKey:(NSString *)translationKey
                          locale:(NSString *)locale;

/**
 *  Returns array of known TMLTranslationKey objects matching given string in given locale.
 *
 *  @param string String to match
 *  @param locale Locale
 *
 *  @return Array of TMLTranslationKey objects
 */
- (NSArray *)translationKeysMatchingString:(NSString *)string
                                    locale:(NSString *)locale;

/**
 *  Checks if translation key (hash) has been registered with Translation Exchange service.
 *
 *  @param translationKey Translation key (hash)
 *
 *  @return YES if translation key corresponding to given hash has been registered with Translation Exchange service.
 */
- (BOOL)isTranslationKeyRegistered:(NSString *)translationKey;

/**
 *  Registers given TMLTranslationKey object with Translation Exchange service.
 *  This operation is asynchronous and can be delayed...
 *
 *  @param translationKey TMLTranslationKey object to register
 */
- (void)registerMissingTranslationKey:(TMLTranslationKey *)translationKey;

/**
 *  Registers given TMLTranslationKey object with Translation Exchange service and associates
 *  it with a source identifiable by given Source key.
 *
 *  @see TMLSource
 *
 *  @param translationKey TMLTranslationKey object to register
 *  @param sourceKey      Associated Source key
 */
- (void)registerMissingTranslationKey:(TMLTranslationKey *)translationKey forSourceKey:(NSString *)sourceKey;

/**
 *  Checks if translations for given locale are available locally.
 * 
 *  Translation data gets pulled down from CDN (or via API) on demand - so it may not always be available locally.
 *  It is possible, however, to include an archive with all of the translation data with the build.
 *  Simply include a zip archive, or a tarball (gz/bzip allowed), in the build. You can retrieve such archive
 *  from dashboard.translationexchange.com, by publishing a Release and then downloading it.
 *
 *  @param locale Locale
 *
 *  @return YES if translation data for given locale is available locally
 */
- (BOOL)hasLocalTranslationsForLocale:(NSString *)locale;

/**
 *  Registers given object that utilizes localized strings.
 * 
 *  When using TMLLocalizedString macros, the calling object is automatically registered via this method.
 *  This information is used by TML's inline translation feature.
 *
 *  @param object Any object that utilizes localized string (such as UIViewController and UIView)
 */
- (void)registerObjectWithLocalizedStrings:(id)object;

/**
 *  Registers given object that utilizes re-usable localized strings.
 *
 *  This is similar to registerObjectWithLocalizedStrings: except to support dynamic re-localization of
 *  previously localized strings. This happens when changing current locale; when localization data
 *  has changed due to import of a newer translation bundle from CDN or an update via API.
 *
 *  @param object Any object that utilizes re-usable localized strings.
 */
- (void)registerObjectWithReusableLocalizedStrings:(id)object;

/**
 *  Readonly property indicating whether currently associated Translation Exchange Project 
 *  allows translation of strings from within the app.
 */
@property(nonatomic, readonly, getter=isInlineTranslationsEnabled) BOOL inlineTranslationsEnabled;

/**
 *  Removes all stored translation data.
 *
 *  That includes all of the translation bundles whether they were retrieved from an archive
 *  distributed with the build (though archive files themselves are preserved);
 *  bundles downloaded from CDN, or any data obtained via the API.
 */
- (void)removeLocalizationData;

- (void)reloadLocalizationData;

#pragma mark - Block options

/**
 *  Marks beginning of a TML block with given options.
 *
 *  Any localization calls such as those made by TMLLocalizedString macros, will inherit these options.
 *  To end a block, call -[TML endBlockWithOptions].
 *
 *  @param options Dictionary of TML options
 */
- (void)beginBlockWithOptions:(NSDictionary *)options;

/**
 *  Returns option value corresponding to the given key in the current 
 *  effective set of block options set via -[TML beginBlockWithOptions:].
 *
 *  @param key Key
 *
 *  @return Option value
 */
- (NSObject *)blockOptionForKey:(NSString *)key;

/**
 *  Marks the end of a TML block last set via -[TML beginBlockWithOptions:].
 */
- (void) endBlockWithOptions;

#pragma mark - Presenting View Controllers

/**
 *  Presents default language picker.
 */
- (void)presentLanguageSelectorController;

/**
 *  Presents translator controller for given translation key (hash).
 *
 *  This is used during in-app traslation.
 *
 *  @param translationKey Translation key.
 */
- (void)presentTranslatorViewControllerWithTranslationKey:(NSString *)translationKey;

@end


#pragma mark - 
#pragma mark Default TML Macros

id TMLLocalize(NSDictionary *options, NSString *string, ...);
id TMLLocalizeDate(NSDictionary *options, NSDate *date, NSString *format, ...);

#define TMLApplicationKey()\
    [[[TML sharedInstance] configuration] applicationKey]

#define TMLSharedApplication()\
    [[TML sharedInstance] application]

#define TMLSharedConfiguration()\
    [[TML sharedInstance] configuration]

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

#define TMLDefaultLanguage()\
    [[TML sharedInstance] defaultLanguage]

#define TMLDefaultLocale()\
    [[TML sharedInstance] defaultLocale]

#define TMLCurrentSource()\
    [[TML sharedInstance] currentSource]

#define TMLHasLocalTranslationsForLocale(locale) \
    [[TML sharedInstance] hasLocalTranslationsForLocale:locale]

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
    [[TML sharedInstance] beginBlockWithOptions: @{TMLSourceOptionName: name}]

#define TMLEndSource() \
    [[TML sharedInstance] endBlockWithOptions]

#define TMLBeginBlockWithOptions(opts) \
    [[TML sharedInstance] beginBlockWithOptions:opts]

#define TMLEndBlockWithOptions() \
    [[TML sharedInstance] endBlockWithOptions]

#define TMLSetTranslationEnabled(translationEnabled)\
    [[TML sharedInstance] setTranslationEnabled:translationEnabled]

#define TMLPresentLanguagePicker() \
    [[TML sharedInstance] presentLanguageSelectorController]

#define TMLChangeLocale(aLocale) \
    [[TML sharedInstance] changeLocale:aLocale completionBlock:nil]

#define TMLPresentTranslatorForKey(translationKeyHash)\
    [[TML sharedInstance] presentTranslatorViewControllerWithTranslationKey:translationKeyHash]
