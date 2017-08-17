/*
 *  Copyright (c) 2017 Translation Exchange, Inc. All rights reserved.
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

extern NSString * const TMLBundleVersionFilename;
extern NSString * const TMLBundleApplicationFilename;
extern NSString * const TMLBundleSourcesFilename;
extern NSString * const TMLBundleTranslationsFilename;
extern NSString * const TMLBundleTranslationKeysFilename;
extern NSString * const TMLBundleLanguageFilename;
extern NSString * const TMLBundleSourcesRelativePath;

extern NSString * const TMLBundleVersionKey;
extern NSString * const TMLBundleURLKey;

extern NSString * const TMLBundleErrorDomain;
extern NSString * const TMLBundleErrorResourcePathKey;
extern NSString * const TMLBundleErrorsKey;

typedef NS_ENUM(NSInteger, TMLBundleErrorCode) {
    TMLBundleInvalidResourcePath,
    TMLBundleMissingResources
};

@class TMLApplication, TMLTranslation;

@interface TMLBundle : NSObject

- (instancetype)initWithContentsOfDirectory:(NSString *)path;

- (BOOL)isEqualToBundle:(TMLBundle *)bundle;

/**
 *  Bundle version
 */
@property (readonly, nonatomic) NSString *version;

/**
 *  Absolute path to the bundle on disk
 */
@property (readonly, nonatomic) NSString *path;

/**
 *  Array of languages contained in the bundle
 */
@property (readonly, nonatomic) NSArray *languages;

/**
 *  Array of locales for which there are locally stored translations
 */
@property (readonly, nonatomic) NSArray *availableLocales;

/**
 *  Array of locales supported by the bundle
 */
@property (readonly, nonatomic) NSArray *locales;

/**
 *  List of TMLSource names used in the bundle
 */
@property (readonly, nonatomic) NSArray *sources;

/**
 *  Dictionary of translation keys. These may not be available, as archived bundles do not include them
 */
@property (readonly, nonatomic) NSDictionary *translationKeys;

/**
 *  Application info included in the bundle
 */
@property (readonly, nonatomic) TMLApplication *application;

/**
 *  Source URL from which this bundle was derrived - typically an archive on CDN
 */
@property (readonly, nonatomic) NSURL *sourceURL;

/**
 * Base URL indicates location from which the bundle can replenish missing localization data.
 * This is used for incremental loading of resources...
 */
@property (readonly, nonnull) NSURL *baseURL;

@property (readonly, nonatomic) BOOL isMutable;

#pragma mark -
@property (readonly, nonatomic, getter=isValid) BOOL valid;

#pragma mark - Languages & Locales

- (TMLLanguage *)languageForLocale:(NSString *)locale;

- (NSString *)matchLocale:(NSString *)locale;

#pragma mark - Translations

- (BOOL)hasLocaleTranslationsForLocale:(NSString *)locale;

/**
 *  Returns dictionary of TMLTranslation objects, keyed by translation key, for the given locale
 *
 *  @param locale Locale used to search translations
 *
 *  @return Dictionary of TMLTranslation objects, keyed by translation key.
 */
- (NSDictionary *)translationsForLocale:(NSString *)locale;

/**
 *  Loads translations for given locale. This will first check for translation data stored locally.
 *  If that fails, translation data will be loaded from a remote host (CDN or via API).
 *
 *  Upon loading translation data, completion block is called. Error argument passed to that completion block
 *  woudl indicate whether operation was successful or not. If successul, you'll find translations
 *  accessible via @selector(translationsForLocale:) method.
 *
 *  @param aLocale    Locale for translations
 *  @param completion Completion block
 */
- (void)loadTranslationsForLocale:(NSString *)aLocale
                       completion:(void(^)(NSError *error))completion;

#pragma mark - Translation Keys
/**
 *  Returns list of translation keys for translations whose label matches given string in the given locale.
 *
 *  @param string String to match
 *  @param locale Locale for translations
 *
 *  @return List of translation keys
 */
- (NSArray *)translationKeysMatchingString:(NSString *)string
                                    locale:(NSString *)locale;

/**
 * Manually adds translation to the interally managed translation table.
 * 
 * This functionality exists to allow atomic updates to the localization data,
 * which happens with inline translation, and this only works for mutable bundles.
 *
 * Please be mindful when using this function, as the translation can and will be
 * overwritten next time the data is loaded.
 */
- (void)addTranslation:(TMLTranslation *)translation
                locale:(NSString *)locale;

#pragma mark - Notifications
- (void) notifyBundleMutation:(NSString *)mutationType
                       errors:(NSArray *)errors;

@end
