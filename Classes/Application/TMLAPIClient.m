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

#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLSource.h"

NSString * const TMLAPIOptionsLocale = @"locale";
NSString * const TMLAPIOptionsIncludeAll = @"all";
NSString * const TMLAPIOptionsClientName = @"client";
NSString * const TMLAPIOptionsIncludeDefinition = @"definition";
NSString * const TMLAPIOptionsSourceKeys = @"source_keys";

@implementation TMLAPIClient

#pragma mark - Init

- (id) initWithApplication: (TMLApplication *) owner {
    if (self == [super init]) {
        self.application = owner;
    }
    return self;
}

#pragma mark - URL Construction

- (NSURL *) URLForAPIPath: (NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableString *pathString = [NSMutableString stringWithFormat:@"%@/v1/%@", self.application.host, path];
    [pathString appendString:@"?"];
    NSDictionary *requestParameters = [self prepareAPIParameters:parameters];
    for (NSString *key in requestParameters) {
        id value = [requestParameters objectForKey:key];
        NSString *valueClass = NSStringFromClass([value class]);
        if ([valueClass rangeOfString:@"Boolean"].location != NSNotFound) {
            value = ([value boolValue] == YES) ? @"true" : @"false";
        }
        [pathString appendFormat:@"%@%@=%@", @"&", [self urlEncode:key], [self urlEncode:value]];
    }
    return [NSURL URLWithString:pathString];
}

- (NSDictionary *) prepareAPIParameters:(NSDictionary *)params {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    parameters[@"access_token"] = self.application.accessToken;
    return parameters;
}

- (NSString *) urlEncode: (id) object {
    NSString *string = [NSString stringWithFormat: @"%@", object];
    return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

- (NSString*) urlEncodedStringFromParameters:(NSDictionary *)parameters {
    NSMutableArray *parts = [NSMutableArray array];
    for (id paramKey in parameters) {
        id paramValue = [parameters objectForKey: paramKey];
        NSString *part = [NSString stringWithFormat: @"%@=%@", [self urlEncode: paramKey], [self urlEncode: paramValue]];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

#pragma mark - Response Handling

- (void) processResponse:(NSURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *)error
         completionBlock:(TMLAPIResponseHandler)completionBlock
{
    if (error != nil) {
        TMLError(@"Request Error: %@", error);
    }
    
    if (completionBlock == nil) {
        return;
    }
    
    TMLAPIResponse *apiResponse = [[TMLAPIResponse alloc] initWithData:data];
    NSError *relevantError = nil;
    if (error != nil) {
        relevantError = error;
    }
    if (apiResponse != nil && relevantError == nil) {
        relevantError = apiResponse.error;
    }
    if (apiResponse == nil && relevantError == nil) {
        TMLWarn(@"Unrecognized response object");
        relevantError = [NSError errorWithDomain:@"Unrecognized response"
                                            code:0
                                        userInfo:nil];
    }
    
    completionBlock(apiResponse, response, relevantError);
}

#pragma mark - Requests

- (void) request: (NSURLRequest *) request
     cachePolicy:(NSURLRequestCachePolicy)cachePolicy
 completionBlock:(TMLAPIResponseHandler)completionBlock
{
    if (NSClassFromString(@"NSURLSession") != nil) {
        [[[NSURLSession sharedSession] dataTaskWithRequest: request
                                         completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
                                             dispatch_async(dispatch_get_main_queue(), ^(void){
                                                 [self processResponse:response
                                                                  data:data
                                                                 error:error
                                                       completionBlock:completionBlock];
                                             });
                                         }] resume];
        
    } else {
        [NSURLConnection sendAsynchronousRequest: request
                                           queue: [NSOperationQueue mainQueue]
                               completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
                                   dispatch_async(dispatch_get_main_queue(), ^(void){
                                       [self processResponse:response
                                                        data:data
                                                       error:error
                                             completionBlock:completionBlock];
                                   });
                               }];
    }
}

- (void) get:(NSString *)path
  parameters:(NSDictionary *)parameters
completionBlock:(TMLAPIResponseHandler)completionBlock
{
    [self get:path
   parameters:parameters
  cachePolicy:NSURLRequestUseProtocolCachePolicy
completionBlock:completionBlock];
}

- (void) post:(NSString *)path
   parameters:(NSDictionary *)parameters
completionBlock:(TMLAPIResponseHandler)completionBlock
{
    [self post:path
    parameters:parameters
   cachePolicy:NSURLRequestUseProtocolCachePolicy
completionBlock:completionBlock];
}

- (void) get:(NSString *)path
  parameters:(NSDictionary *)parameters
 cachePolicy:(NSURLRequestCachePolicy)cachePolicy
completionBlock:(TMLAPIResponseHandler)completionBlock
{
    NSURL *url = [self URLForAPIPath:path parameters:parameters];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    TMLDebug(@"GET %@", url);
    [self request:request
      cachePolicy:cachePolicy
  completionBlock:completionBlock];
}

- (void) post:(NSString *)path
   parameters:(NSDictionary *)parameters
  cachePolicy:(NSURLRequestCachePolicy)cachePolicy
completionBlock:(TMLAPIResponseHandler)completionBlock
{
    NSURL *url = [self URLForAPIPath:path parameters:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[self urlEncodedStringFromParameters: [self prepareAPIParameters: parameters]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    TMLDebug(@"POST %@", url);
    [self request:request
      cachePolicy:cachePolicy
  completionBlock:completionBlock];
}

#pragma mark - Methods

- (void) getTranslationsForLocale:(NSString *)locale
                           source:(TMLSource *)source
                          options:(NSDictionary *)options
                  completionBlock:(void(^)(NSDictionary <NSString *,TMLTranslation *>*translations, NSError *error))completionBlock
{
    NSString *path = nil;
    NSString *sourceKey = source.key;
    if (sourceKey != nil) {
        path = [NSString stringWithFormat: @"sources/%@/translations", [TMLConfiguration md5:sourceKey]];
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
    NSDictionary <NSString *, TMLTranslation *>*translations = nil;
    if ([apiResponse isSuccessfulResponse] == YES) {
        translations = [apiResponse resultsAsTranslations];
    }
    else {
        TMLError(@"Error fetching translations for locale: %@; source: %@. Error: %@", locale, source, error);
    }
    if (completionBlock != nil) {
        completionBlock(translations, error);
    }
}
     
     ];
}

- (void)getProjectInfoWithOptions:(NSDictionary *)options
                  completionBlock:(void (^)(NSDictionary *, NSError *))completionBlock
{
    NSMutableDictionary *params = nil;
    if (options != nil) {
        params = [options mutableCopy];
    }
    else {
        params = [NSMutableDictionary dictionary];
    }
    params[TMLAPIOptionsClientName] = @"ios";
    
    [self get:@"projects/current"
             parameters:params
        completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
            NSMutableDictionary *projectInfo = nil;
            if ([apiResponse isSuccessfulResponse] == YES) {
                projectInfo = [apiResponse.userInfo mutableCopy];
                
                // marshal languages; application info response will include languages structs
                // directly under "languages" key the top-level object, as opposed to "results"
                NSArray *langs = [apiResponse resultsAsLanguages];
                if (langs != nil) {
                    projectInfo[TMLAPIResponseResultsLanguagesKey] = langs;
                }
            }
            else {
                TMLError(@"Error fetching current project description: %@", error);
            }
            if (completionBlock != nil) {
                completionBlock((NSDictionary *)projectInfo, error);
            }
        }
     ];
}

- (void)getLanguageForLocale:(NSString *)locale
                     options:(NSDictionary *)options
             completionBlock:(void (^)(TMLLanguage *, NSError *))completionBlock
{
    [self get: [NSString stringWithFormat: @"languages/%@", locale]
   parameters:options
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    TMLLanguage *lang = nil;
    if ([apiResponse isSuccessfulResponse] == YES) {
        lang = [[TMLLanguage alloc] initWithAttributes:apiResponse.userInfo];
    }
    else {
        TMLError(@"Error fetching languages description for locale: %@. Error: %@", locale, error);
    }
    if (completionBlock != nil) {
        completionBlock(lang, error);
    }
}
     ];
}

- (void)getProjectLanguagesWithOptions:(NSDictionary *)options
                       completionBlock:(void (^)(NSArray<TMLLanguage *> *, NSError *))completionBlock
{
    [self get:@"projects/current/languages"
   parameters:options
completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
    NSArray <TMLLanguage *>*languages = nil;
    if ([apiResponse isSuccessfulResponse] == YES) {
        languages = [apiResponse resultsAsLanguages];
    }
    else {
        TMLError(@"Error fetching descriptions of all languages for current project: %@", error);
    }
    if (completionBlock != nil) {
        completionBlock(languages, error);
    }
}];
}

- (void)registerTranslationKeysBySource:(NSDictionary<TMLSource *,TMLTranslationKey *> *)sourceKeys
                        completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
    NSMutableArray *sourceKeysList = [NSMutableArray array];
    for (TMLSource *source in sourceKeys) {
        [sourceKeysList addObject:@{@"source": [source key], @"keys": sourceKeys[source]}];
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
