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
#import "TMLBasicAPIClient.h"

@class TMLAPIRequest, TMLAPIResponse, TMLSource, TMLApplication, TMLUser, TMLScreenShot;

extern NSString * const TMLAPIOptionsLocale;
extern NSString * const TMLAPIOptionsIncludeAll;
extern NSString * const TMLAPIOptionsClientName;
extern NSString * const TMLAPIOptionsIncludeDefinition;
extern NSString * const TMLAPIOptionsPage;

@interface TMLAPIClient : TMLBasicAPIClient
@property (strong, nonatomic) NSString *accessToken;
@property (readonly, nonatomic) NSString *applicationKey;
- (id) initWithBaseURL:(NSURL *)url
        applicationKey:(NSString *)applicationKey
           accessToken:(NSString *)accessToken;

- (void)reset;

#pragma mark - Methods

/**
 * Fetches user info.
 *
 * @param completionBlock Completion block
 */
- (void) getUserInfo:(void(^)(TMLUser *user, TMLAPIResponse *response, NSError *error))completionBlock;


/**
 * Fetches current translator
 */
- (void) getTranslatorInfo:(void(^)(TMLTranslator *translator, TMLAPIResponse *response, NSError *error))completionBlock;

/**
 *  Fetches list of translations for specified locale. If source is given, 
 *  list will be restricted to that source, otherwise results will be
 *  for the entire project.
 *
 *  @param locale          Locale
 *  @param options         Dictionary of API options, using TMLAPIOptions for keys
 *  @param source          Source, or nil for project-wide translations
 *  @param completionBlock Completion block
 */
- (void) getTranslationsForLocale:(NSString *)locale
                           source:(TMLSource *)source
                          options:(NSDictionary *)options
                  completionBlock:(void(^)(NSDictionary *translations, TMLAPIResponse *response, NSError *error))completionBlock;

/**
 *  Fetches application info.
 *
 *  @param options         Dictionary of options with TMLAPIOptions for keys
 *  @param completionBlock Completion block
 */
- (void) getCurrentApplicationWithOptions:(NSDictionary *)options
                          completionBlock:(void(^)(TMLApplication *application, TMLAPIResponse *response, NSError *error))completionBlock;

/**
 *  Fetches infromation about translation sources
 *
 *  @param options         Dictionary of options with TMLAPIOptions for keys
 *  @param completionBlock Completion block
 */
- (void) getSources:(NSDictionary *)options
    completionBlock:(void(^)(NSArray *sources, TMLAPIResponse *response, NSError *error))completionBlock;

/**
 *  Fetches language info for given locale.
 *
 *  @param locale          Locale for lanuages (i.e. "en")
 *  @param options         Dictionary of options with TMLAPIOptions for keys. For example @{TMLAPIOptionsIncludeDefition: @YES}
 *  @param completionBlock Completion block
 */
- (void) getLanguageForLocale:(NSString *)locale
                      options:(NSDictionary *)options
              completionBlock:(void(^)(TMLLanguage *language, TMLAPIResponse *response, NSError *error))completionBlock;

/**
 *  Fetches list of languages defined in current project
 *
 *  @param options         Dictionary of options with TMLAPIOptions for keys
 *  @param completionBlock Completion block
 */
- (void) getProjectLanguagesWithOptions:(NSDictionary *)options
                        completionBlock:(void(^)(NSArray * languages, TMLAPIResponse *response, NSError *error))completionBlock;

/**
 *  Fetches list of translation keys for current project
 *
 *  @param options         Optional dictionary of options with TMLAPIOptions for keys.
 *  @param completionBlock Completion block;
 */
- (void) getTranslationKeysWithOptions:(NSDictionary *)options
                       completionBlock:(void(^)(NSDictionary *translationKeys, TMLAPIResponse *response, NSError *error))completionBlock;

/**
 *  Register source and translation key associations.
 *  Data passed in sourceKeys parameter will be copied...
 *
 *  @param sourceKeys      Dictionary with keys indicating TMLSource keys, and values containing an NSSet of TMLTranslationKey's
 *  @param completionBlock Completion block, indicating successful submissions
 */
- (void) registerTranslationKeysBySourceKey:(NSDictionary *)sourceKeys
                            completionBlock:(void(^)(BOOL success, NSError *error))completionBlock;


- (void)postScreenShot: (TMLScreenShot *)screenShot
       completionBlock:(void (^)(BOOL, NSError *))completionBlock;

@end
