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

#import "NSObject+TMLJSON.h"
#import "NSString+TML.h"
#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLAPISerializer.h"
#import "TMLApplication.h"
#import "TMLLanguage.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"

NSString * const TMLAPIOptionsLocale = @"locale";
NSString * const TMLAPIOptionsIncludeAll = @"all";
NSString * const TMLAPIOptionsClientName = @"client";
NSString * const TMLAPIOptionsIncludeDefinition = @"definition";
NSString * const TMLAPIOptionsSourceKeys = @"source_keys";
NSString * const TMLAPIOptionsPage = @"page";

@interface TMLAPIClient()
@property (readwrite, nonatomic) NSString *accessToken;
@end

@implementation TMLAPIClient

#pragma mark - Init

- (id) initWithBaseURL:(NSURL *)baseURL accessToken:(NSString *)accessToken {
    if (self = [super initWithBaseURL:baseURL]) {
        self.accessToken = accessToken;
    }
    return self;
}

#pragma mark - URL Construction

- (NSDictionary *) prepareAPIParameters:(NSDictionary *)params {
    // TODO - should really use an HTTP header for this
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    parameters[@"access_token"] = self.accessToken;
    return parameters;
}

#pragma mark - Making Requests
- (void) get:(NSString *)path
  parameters:(NSDictionary *)parameters
 cachePolicy:(NSURLRequestCachePolicy)cachePolicy
completionBlock:(TMLAPIResponseHandler)completionBlock
{
    BOOL includeAllResults = [parameters[TMLAPIOptionsIncludeAll] boolValue];
    NSDictionary *requestParameters = [self prepareAPIParameters:parameters];
    [super get:path
    parameters:requestParameters
   cachePolicy:cachePolicy
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    if (includeAllResults == YES
        && error == nil
        && apiResponse.paginated == YES
        && apiResponse.currentPage < apiResponse.totalPages) {
        NSMutableDictionary *newParams = [parameters mutableCopy];
        newParams[TMLAPIOptionsPage] = @(apiResponse.currentPage + 1);
        newParams[TMLAPIOptionsIncludeAll] = @(YES);
        __block TMLAPIResponse *runningResponse = apiResponse;
        [self get:path parameters:[newParams copy] cachePolicy:cachePolicy completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
            runningResponse = [runningResponse responseByMergingWithResponse:apiResponse];
            if (completionBlock != nil) {
                completionBlock(runningResponse, response, error);
            }
        }];
    }
    else if (completionBlock != nil) {
        completionBlock(apiResponse, response, error);
    }
}];
}

- (void) post:(NSString *)path
   parameters:(NSDictionary *)parameters
  cachePolicy:(NSURLRequestCachePolicy)cachePolicy
completionBlock:(TMLAPIResponseHandler)completionBlock
{
    NSDictionary *requestParameters = [self prepareAPIParameters:parameters];
    [super post:path
     parameters:requestParameters
    cachePolicy:cachePolicy
completionBlock:completionBlock];
}

#pragma mark - Methods

- (void) getTranslationsForLocale:(NSString *)locale
                           source:(TMLSource *)source
                          options:(NSDictionary *)options
                  completionBlock:(void(^)(NSDictionary *translations, TMLAPIResponse *response, NSError *error))completionBlock
{
    NSString *path = nil;
    NSString *sourceKey = source.key;
    if (sourceKey != nil) {
        path = [NSString stringWithFormat: @"sources/%@/translations", [sourceKey tmlMD5]];
    }
    else {
        path = [NSString stringWithFormat:@"projects/current/translations"];
    }
    
    NSMutableDictionary *params = nil;
    if (options != nil) {
        params = [options mutableCopy];
    }
    else {
        params = [NSMutableDictionary dictionaryWithDictionary:@{TMLAPIOptionsIncludeAll: @YES}];
    }
    params[TMLAPIOptionsLocale] = locale;
    
    [self get:path
   parameters:params
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    NSDictionary *translations = nil;
    if ([apiResponse isSuccessfulResponse] == YES) {
        translations = [apiResponse resultsAsTranslations];
        NSArray *translationObjects = [[translations allValues] valueForKeyPath:@"@unionOfArrays.self"];
        for (TMLTranslation *translation in translationObjects) {
            translation.locale = locale;
        }
    }
    else {
        TMLError(@"Error fetching translations for locale: %@; source: %@. Error: %@", locale, source, error);
    }
    if (completionBlock != nil) {
        completionBlock(translations, apiResponse, error);
    }
}
     
     ];
}

- (void)getCurrentApplicationWithOptions:(NSDictionary *)options
                         completionBlock:(void (^)(TMLApplication *, TMLAPIResponse *response, NSError *))completionBlock
{
    NSMutableDictionary *params = nil;
    if (options != nil) {
        params = [options mutableCopy];
    }
    else {
        params = [NSMutableDictionary dictionary];
    }
    params[TMLAPIOptionsClientName] = @"ios";
    
    NSString *path = @"projects/current";
    if ([params[TMLAPIOptionsIncludeDefinition] boolValue] == YES) {
        path = [NSString stringWithFormat:@"%@/definition", path];
        [params removeObjectForKey:TMLAPIOptionsIncludeDefinition];
    }
    
    [self get:path
             parameters:params
        completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
            TMLApplication *app = nil;
            if ([apiResponse isSuccessfulResponse] == YES) {
                NSMutableDictionary *userInfo = [apiResponse.userInfo mutableCopy];
                NSDictionary *extensions = userInfo[@"extensions"];
                if (TMLIsNilNull(extensions) == NO) {
                    NSDictionary *langExtensions = extensions[@"languages"];
                    NSArray *langs = userInfo[@"languages"];
                    if (langExtensions.count > 0 && langs.count > 0) {
                        NSMutableArray *newLanguages = [NSMutableArray array];
                        for (NSDictionary *lang in langs) {
                            NSString *locale = lang[@"locale"];
                            NSDictionary *langExtension = nil;
                            if (TMLIsNilNull(locale) == NO) {
                                langExtension = langExtensions[locale];
                            }
                            if (TMLIsNilNull(langExtension) == NO) {
                                NSMutableDictionary *newLang = [lang mutableCopy];
                                newLang[@"cases"] = langExtension[@"cases"];
                                newLang[@"contexts"] = langExtension[@"contexts"];
                                [newLanguages addObject:[newLang copy]];
                            }
                            else {
                                [newLanguages addObject:lang];
                            }
                        }
                        userInfo[@"languages"] = [newLanguages copy];
                    }
                }
                app = [TMLAPISerializer materializeObject:[userInfo copy]
                                                withClass:[TMLApplication class]];
            }
            else {
                TMLError(@"Error fetching current project description: %@", error);
            }
            if (completionBlock != nil) {
                completionBlock(app, apiResponse, error);
            }
        }
     ];
}

- (void)getSources:(NSDictionary *)options
   completionBlock:(void (^)(NSArray *, TMLAPIResponse *response, NSError *))completionBlock
{
    [self get:@"projects/current/sources"
   parameters:options
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    NSArray *sources = nil;
    if (apiResponse.successfulResponse == YES) {
        sources = [TMLAPISerializer materializeObject:apiResponse.results
                                            withClass:[TMLSource class]];
    }
    TMLDebug(@"Got %i total sources via API", sources.count);
    if (completionBlock != nil) {
        completionBlock(sources, apiResponse, error);
    }
}];
}

- (void)getLanguageForLocale:(NSString *)locale
                     options:(NSDictionary *)options
             completionBlock:(void (^)(TMLLanguage *, TMLAPIResponse *response, NSError *))completionBlock
{
    [self get: [NSString stringWithFormat: @"languages/%@", locale]
   parameters:options
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    TMLLanguage *lang = nil;
    if ([apiResponse isSuccessfulResponse] == YES) {
        lang = [TMLAPISerializer materializeObject:apiResponse.userInfo
                                         withClass:[TMLLanguage class]];
    }
    else {
        TMLError(@"Error fetching languages description for locale: %@. Error: %@", locale, error);
    }
    if (completionBlock != nil) {
        completionBlock(lang, apiResponse, error);
    }
}
     ];
}

- (void)getProjectLanguagesWithOptions:(NSDictionary *)options
                       completionBlock:(void (^)(NSArray*, TMLAPIResponse *response, NSError *))completionBlock
{
    [self get:@"projects/current/languages"
   parameters:options
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    NSArray *languages = nil;
    if ([apiResponse isSuccessfulResponse] == YES) {
        languages = [apiResponse resultsAsLanguages];
    }
    else {
        TMLError(@"Error fetching descriptions of all languages for current project: %@", error);
    }
    if (completionBlock != nil) {
        completionBlock(languages, apiResponse, error);
    }
}];
}

- (void)getTranslationKeysWithOptions:(NSDictionary *)options
                      completionBlock:(void (^)(NSArray *, TMLAPIResponse *, NSError *))completionBlock
{
    NSMutableDictionary *params = [options mutableCopy];
    if (params == nil) {
        params = [NSMutableDictionary dictionary];
    }
    params[TMLAPIOptionsIncludeAll] = @YES;
    
    [self get:@"projects/current/translation_keys"
   parameters:params
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    NSArray *translationKeys = nil;
    if ([apiResponse isSuccessfulResponse] == YES) {
        translationKeys = [apiResponse resultsAsTranslationKeys];
    }
    else {
        TMLError(@"Error fetching translation keys for current project: %@", error);
    }
    if (completionBlock != nil) {
        completionBlock(translationKeys, apiResponse, error);
    }
}];
}

- (void)registerTranslationKeysBySourceKey:(NSDictionary *)keysInfo
                           completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
    NSMutableArray *sourceKeysList = [NSMutableArray array];
    NSDictionary *info = [[NSDictionary alloc] initWithDictionary:keysInfo copyItems:YES];
    for (NSString *sourceKey in info) {
        NSSet *keys = info[sourceKey];
        NSMutableArray *keysPayload = [NSMutableArray array];
        for (TMLTranslationKey *key in keys) {
            NSData *serialized = [TMLAPISerializer serializeObject:key];
            [keysPayload addObject:[serialized tmlJSONObject]];
        }
        [sourceKeysList addObject:@{@"source": sourceKey, @"keys": keysPayload}];
    }
    
    [self post:@"sources/register_keys"
    parameters:@{TMLAPIOptionsSourceKeys: sourceKeysList}
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    BOOL success = [apiResponse isSuccessfulResponse];
    if (success == NO) {
        TMLError(@"Error submitting translation keys by source: %@", error);
    }
    if (completionBlock != nil) {
        completionBlock(success, error);
    }
}];
}

@end
