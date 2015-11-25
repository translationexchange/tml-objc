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
#import "TMLAPIResponse.h"

extern NSString * const TMLAPIOptionsLocale;
extern NSString * const TMLAPIOptionsIncludeAll;
extern NSString * const TMLAPIOptionsClientName;
extern NSString * const TMLAPIOptionsIncludeDefinition;

/**
 *  Handler for TML's API responses. A successful response would normally 
 *  be indicated by a non-nil apiResponse parameter and a nil error parameter.
 *  An error parameter would indicate either an error with response or an erroneous response.
 *  The former are typically related to bad requests or network problems. The latter are
 *  errors returned by the API, and as such, would also be indicated in apiResponse.error.
 *
 *  @param apiResponse API Response object
 *  @param response    NSURLResponse object from which apiResponse is derived
 *  @param error       Error indicating either an error with response or an erroneous response.
 */
typedef void (^TMLAPIResponseHandler)(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error);

@class TMLSource, TMLTranslation, TMLTranslationKey, TMLApplication;


@interface TMLAPIClient : NSObject
@property (readonly, nonatomic) NSURL *url;
@property (readonly, nonatomic) NSString *accessToken;
- (id) initWithURL:(NSURL *)url accessToken:(NSString *)accessToken;

/**
 *  Convinience method for get:parameters:cachePolicy:completionBlock:
 *  Using default protocol cache policy...
 *
 *  @see get:parameters:cachePolicy:completionBlock:
 *
 *  @param path            API Path
 *  @param parameters      NSDictionary of API parameters
 *  @param completionBlock Completion block
 */
- (void) get:(NSString *)path
  parameters:(NSDictionary *)parameters
completionBlock:(TMLAPIResponseHandler)completionBlock;

/**
 *  Convinience method for post:parameters:cachePolicy:completionBlock:
 *  Using default protocol cache policy...
 *
 *  @see get:parameters:cachePolicy:completionBlock:
 *
 *  @param path            API Path
 *  @param parameters      NSDictionary of API parameters
 *  @param completionBlock Completion block
 */
- (void) post:(NSString *)path
   parameters:(NSDictionary *)parameters
completionBlock:(TMLAPIResponseHandler)completionBlock;

/**
 *  Performs API request, using GET HTTP method and specified cache policy,
 *  to the specified path within the API, with specified parameters.
 *  Completion block is called when the requests finishes or fails, passing it
 *  the resuling response object, NSURLResponse object and NSError if applicable.
 *  Successful response should not have an error and should contain a response object.
 *
 *  @param path            API Path
 *  @param parameters      NSDictionary of API parameters
 *  @param cachePolicy     NSURLRequestCachePolicy to use for request (or 0 to use NSURLRequestUseProtocolCachePolicy)
 *  @param completionBlock Completion block
 */
- (void) get:(NSString *)path
  parameters:(NSDictionary *)parameters
 cachePolicy:(NSURLRequestCachePolicy)cachePolicy
completionBlock:(TMLAPIResponseHandler)completionBlock;

/**
 *  Performs API request, using GET POST method and specified cache policy,
 *  to the specified path within the API, with specified parameters.
 *  Completion block is called when the requests finishes or fails, passing it
 *  the resuling response object, NSURLResponse object and NSError if applicable.
 *  Successful response should not have an error and should contain a response object.
 *
 *  @param path            API Path
 *  @param parameters      NSDictionary of API parameters
 *  @param cachePolicy     NSURLRequestCachePolicy to use for request (or 0 to use NSURLRequestUseProtocolCachePolicy)
 *  @param completionBlock Completion block
 */
- (void) post:(NSString *)path
   parameters:(NSDictionary *)parameters
  cachePolicy:(NSURLRequestCachePolicy)cachePolicy
completionBlock:(TMLAPIResponseHandler)completionBlock;

#pragma mark - Methods

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
                        completionBlock:(void(^)(NSArray <TMLLanguage *>* languages, TMLAPIResponse *response, NSError *error))completionBlock;

/**
 *  Register source and translation key associations.
 *  Data passed in sourceKeys parameter will be copied...
 *
 *  @param sourceKeys      Dictionary with keys indicating TMLSource keys, and values containing an NSSet of TMLTranslationKey's
 *  @param completionBlock Completion block, indicating successful submissions
 */
- (void) registerTranslationKeysBySourceKey:(NSDictionary <NSString *, NSSet <TMLTranslationKey *>*>*)sourceKeys
                            completionBlock:(void(^)(BOOL success, NSError *error))completionBlock;

@end
