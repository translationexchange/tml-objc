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
#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLAPISerializer.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLSource.h"
#import "TMLTranslationKey.h"
#import "TMLApplication.h"

NSString * const TMLAPIOptionsLocale = @"locale";
NSString * const TMLAPIOptionsIncludeAll = @"all";
NSString * const TMLAPIOptionsClientName = @"client";
NSString * const TMLAPIOptionsIncludeDefinition = @"definition";
NSString * const TMLAPIOptionsSourceKeys = @"source_keys";

@interface TMLAPIClient()
@property (readwrite, nonatomic) NSURL *url;
@property (readwrite, nonatomic) NSString *accessToken;
@end

@implementation TMLAPIClient

#pragma mark - Init

- (id) initWithURL:(NSURL *)url accessToken:(NSString *)accessToken {
    if (self == [super init]) {
        self.url = url;
        self.accessToken = accessToken;
    }
    return self;
}

#pragma mark - URL Construction

- (NSURL *) URLForAPIPath: (NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableString *pathString = [NSMutableString stringWithFormat:@"%@/v1/%@", self.url, path];
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
    // TODO - should really use an HTTP header for this
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    parameters[@"access_token"] = self.accessToken;
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
        NSString *paramString = ([paramValue isKindOfClass:[NSString class]] == YES) ? (NSString *)paramValue : [paramValue tmlJSONString];
        NSString *part = [NSString stringWithFormat: @"%@=%@", [self urlEncode: paramKey], [self urlEncode: paramString]];
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
    [[[NSURLSession sharedSession] dataTaskWithRequest: request
                                     completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
                                         dispatch_async(dispatch_get_main_queue(), ^(void){
                                             [self processResponse:response
                                                              data:data
                                                             error:error
                                                   completionBlock:completionBlock];
                                         });
                                     }] resume];
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

- (void)getCurrentApplicationWithOptions:(NSDictionary *)options
                         completionBlock:(void (^)(TMLApplication *, NSError *))completionBlock
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
                if (extensions != nil) {
                    NSDictionary *langExtensions = extensions[@"languages"];
                    NSArray *langs = userInfo[@"languages"];
                    if (langExtensions.count > 0 && langs.count > 0) {
                        NSMutableArray *newLanguages = [NSMutableArray array];
                        for (NSDictionary *lang in langs) {
                            NSString *locale = lang[@"locale"];
                            NSDictionary *langExtension = nil;
                            if (locale != nil) {
                                langExtension = langExtensions[locale];
                            }
                            if (langExtension != nil) {
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
                                                withClass:[TMLApplication class]
                                                 delegate:nil];
            }
            else {
                TMLError(@"Error fetching current project description: %@", error);
            }
            if (completionBlock != nil) {
                completionBlock(app, error);
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
        lang = [TMLAPISerializer materializeObject:apiResponse.userInfo withClass:[TMLLanguage class] delegate:nil];
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

- (void)registerTranslationKeysBySourceKey:(NSDictionary<NSString *, NSSet <TMLTranslationKey *>*> *)keysInfo
                           completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
    NSMutableArray *sourceKeysList = [NSMutableArray array];
    for (NSString *sourceKey in keysInfo) {
        NSSet *keys = keysInfo[sourceKey];
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
