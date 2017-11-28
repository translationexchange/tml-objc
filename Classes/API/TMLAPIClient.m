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
#import "TMLUser.h"
#import "TMLTranslator.h"
#import "TMLScreenShot.h"
#import "TMLAuthorizationViewController.h"
#import <AFNetworking/AFNetworking.h>

NSString * const TMLAPIOptionsLocale = @"locale";
NSString * const TMLAPIOptionsIncludeAll = @"all";
NSString * const TMLAPIOptionsClientName = @"client";
NSString * const TMLAPIOptionsIncludeDefinition = @"definition";
NSString * const TMLAPIOptionsSourceKeys = @"source_keys";
NSString * const TMLAPIOptionsBase64 = @"base64";
NSString * const TMLAPIOptionsApplicationId = @"app_id";
NSString * const TMLAPIOptionsPage = @"page";

typedef void (^TMLAPIRequestRetryCompletion)(BOOL shouldRetry);
typedef void (^AccessTokenRefreshCompletion)(BOOL succeeded, NSString *accessToken);

@interface TML(Private)
- (void)showError:(NSError *)error;
@end

@interface TMLBasicAPIClient (Private)
- (NSURL *) URLForAPIPath: (NSString *)path parameters:(NSDictionary *)parameters;
@end

@interface TMLAPIClient()
@property (readwrite, nonatomic) NSString *applicationKey;
@property (strong, nonatomic) NSMutableArray<TMLAPIRequestRetryCompletion> *requestsToRetry;
@property (nonatomic) BOOL isRefreshingAccessToken;
@property (strong, nonatomic) NSLock *lock;
@end

@implementation TMLAPIClient

#pragma mark - Init

- (id) initWithBaseURL:(NSURL *)baseURL
        applicationKey:(NSString *)applicationKey
           accessToken:(NSString *)accessToken {
    if (self = [super initWithBaseURL:baseURL]) {
        self.applicationKey = applicationKey;
        self.accessToken = accessToken;
        
        [self reset];
    }
    return self;
}

- (void)reset {
    self.isRefreshingAccessToken = NO;
    self.requestsToRetry = [@[] mutableCopy];
    self.lock = [[NSLock alloc] init];
}

#pragma mark - URL Construction

- (NSDictionary *) prepareAPIParameters:(NSDictionary *)params {
    // TODO - should really use an HTTP header for this
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    parameters[@"access_token"] = self.accessToken;
    return parameters;
}

#pragma mark - Making Requests

- (void)shouldRetryRequest:(TMLAPIRequest *)request completionBlock:(TMLAPIRequestRetryCompletion)completionBlock {
    [self.lock lock];
    
    if ([request.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)request.response;
        
        if (httpResponse.statusCode == 403) {
            [self.requestsToRetry addObject:completionBlock];
            
            if (!self.isRefreshingAccessToken) {
                __weak typeof(self)weakSelf = self;
                
                [weakSelf refreshAccessToken:^(BOOL succeeded, NSString *accessToken) {
                    __strong typeof(self)strongSelf = weakSelf;
                    
                    [strongSelf.lock lock];
                    
                    strongSelf.accessToken = accessToken;
                    
                    for (TMLAPIRequestRetryCompletion completion in strongSelf.requestsToRetry) {
                        completion(succeeded);
                    }
                    
                    [strongSelf.requestsToRetry removeAllObjects];
                    
                    [strongSelf.lock unlock];
                }];
            }
        } else {
            completionBlock(false);
        }
    } else {
        completionBlock(false);
    }
    
    [self.lock unlock];
}

- (void)refreshAccessToken:(AccessTokenRefreshCompletion)completionBlock {
    if (self.isRefreshingAccessToken) {
        return;
    }
    
    self.isRefreshingAccessToken = YES;
    
    TMLAuthorizationViewController *authController = [[TML sharedInstance] presentAuthorizationControllerForTokenRefresh];
    authController.completion = ^(BOOL succeeded, NSString *accessToken) {
        completionBlock(succeeded, accessToken);
        
        self.isRefreshingAccessToken = NO;
    };
}

- (void)send:(TMLAPIRequest *)request completionBlock:(TMLAPIResponseHandler)completionBlock {
    if ([request.method isEqualToString:@"GET"]) {
        [super get:request.path parameters:[self prepareAPIParameters:request.parameters] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
            [self handleResponse:apiResponse response:response error:error request:request completionBlock:completionBlock];
        }];
    } else if ([request.method isEqualToString:@"POST"]) {
        [super post:request.path parameters:[self prepareAPIParameters:request.parameters] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
            [self handleResponse:apiResponse response:response error:error request:request completionBlock:completionBlock];
        }];
    }
}

- (void)handleResponse:(TMLAPIResponse *)apiResponse response:(NSURLResponse *)response error:(NSError *)error request:(TMLAPIRequest *)request completionBlock:(TMLAPIResponseHandler)completionBlock {
    request.response = response;
    
    __weak typeof(self)weakSelf = self;
    
    [weakSelf shouldRetryRequest:request completionBlock:^(BOOL shouldRetry) {
        __strong typeof(self)strongSelf = weakSelf;
        
        if (!shouldRetry) {
            completionBlock(apiResponse, response, error);
            
            return;
        }
        
        [strongSelf send:request completionBlock:completionBlock];
    }];
}

#pragma mark - Methods

- (void)getUserInfo:(void (^)(TMLUser *, TMLAPIResponse *, NSError *))completionBlock {
    NSString *path = @"users/me";
    [self send:[TMLAPIRequest requestWithMethod:@"GET" path:path parameters:nil] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
        if (completionBlock != nil) {
            TMLUser *user = nil;
            if (apiResponse != nil) {
                NSDictionary *info = apiResponse.userInfo;
                if (info != nil) {
                    user = [TMLAPISerializer materializeObject:info withClass:[TMLUser class]];
                }
            }
            completionBlock(user, apiResponse, error);
        }
    }];
}

- (void)getTranslatorInfo:(void (^)(TMLTranslator *, TMLAPIResponse *, NSError *))completionBlock {
    NSString *path = [NSString stringWithFormat:@"%@/translators/me", [self applicationProjectPath]];
    [self send:[TMLAPIRequest requestWithMethod:@"GET" path:path parameters:nil] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
        if (completionBlock != nil) {
            TMLTranslator *translator = nil;
            if (apiResponse != nil) {
                NSDictionary *info = apiResponse.userInfo;
                if (info != nil) {
                    translator = [TMLAPISerializer materializeObject:[info objectForKey:@"translator"] withClass:[TMLTranslator class]];
                    if (![translator isKindOfClass:[NSNull class]]) {
                        translator.role = [info objectForKey:@"role"];
                    }
                }
            }
            completionBlock(translator, apiResponse, error);
        }
    }];
}

- (NSString *)applicationProjectPath {
    return [NSString stringWithFormat:@"projects/%@", self.applicationKey];
}

- (void) getTranslationsForLocale:(NSString *)locale
                           source:(TMLSource *)source
                          options:(NSDictionary *)options
                  completionBlock:(void(^)(NSDictionary *translations, TMLAPIResponse *response, NSError *error))completionBlock
{
    NSString *path = nil;
    NSString *sourceKey = source.key;
    if (sourceKey != nil) {
        path = [NSString stringWithFormat:@"%@/sources/%@/translations", [self applicationProjectPath], [sourceKey tmlMD5]];
    }
    else {
        path = [NSString stringWithFormat:@"%@/translations", [self applicationProjectPath]];
    }
    
    NSMutableDictionary *params = nil;
    if (options != nil) {
        params = [options mutableCopy];
    }
    else {
        params = [NSMutableDictionary dictionary];
    }
    
    params[TMLAPIOptionsLocale] = locale;
    
    [self send:[TMLAPIRequest requestWithMethod:@"GET" path:path parameters:params] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
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
    }];
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
    
    NSString *path = [self applicationProjectPath];
    if ([params[TMLAPIOptionsIncludeDefinition] boolValue] == YES) {
        path = [NSString stringWithFormat:@"%@", path];
        [params removeObjectForKey:TMLAPIOptionsIncludeDefinition];
    }
    
    [self send:[TMLAPIRequest requestWithMethod:@"GET" path:path parameters:params] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
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
    }];
}

- (void)getSources:(NSDictionary *)options
   completionBlock:(void (^)(NSArray *, TMLAPIResponse *response, NSError *))completionBlock
{
    [self send:[TMLAPIRequest requestWithMethod:@"GET" path:[NSString stringWithFormat:@"%@/sources", [self applicationProjectPath]] parameters:options] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
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
    [self send:[TMLAPIRequest requestWithMethod:@"GET" path:[NSString stringWithFormat:@"%@/languages/%@", [self applicationProjectPath], locale] parameters:options] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
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
    }];
}

- (void)getProjectLanguagesWithOptions:(NSDictionary *)options
                       completionBlock:(void (^)(NSArray*, TMLAPIResponse *response, NSError *))completionBlock
{
    [self send:[TMLAPIRequest requestWithMethod:@"GET" path:[NSString stringWithFormat:@"%@/languages", [self applicationProjectPath]] parameters:options] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
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
                      completionBlock:(void (^)(NSDictionary *, TMLAPIResponse *, NSError *))completionBlock
{
    NSMutableDictionary *params = [options mutableCopy];
    if (params == nil) {
        params = [NSMutableDictionary dictionary];
    }
    
    [self send:[TMLAPIRequest requestWithMethod:@"GET" path:[NSString stringWithFormat:@"%@/translation_keys", [self applicationProjectPath]] parameters:params] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
        NSDictionary *translationKeys = nil;
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
    
    NSString *path = [NSString stringWithFormat:@"%@/translation_keys", [self applicationProjectPath]];
    NSString *base64Encoded = [[TMLAPISerializer serializeObject:sourceKeysList] base64EncodedStringWithOptions:0];
    
    [self send:[TMLAPIRequest requestWithMethod:@"POST" path:path parameters:@{TMLAPIOptionsSourceKeys: base64Encoded, TMLAPIOptionsBase64: @"true", TMLAPIOptionsApplicationId: self.applicationKey}] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
        BOOL success = [apiResponse isSuccessfulResponse];
        if (success == NO) {
            TMLError(@"Error submitting translation keys by source: %@", error);
        }
        if (completionBlock != nil) {
            completionBlock(success, error);
        }
    }];
}

- (void)postScreenShot: (TMLScreenShot *)screenShot
       completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
    NSString *path = [NSString stringWithFormat:@"projects/%@/screenshots", self.applicationKey];
    NSURL *url = [self URLForAPIPath:path parameters:nil];
    NSError *postError = nil;
    
    NSMutableDictionary *payload = [[[TMLAPISerializer serializeObject:screenShot] tmlJSONObject] mutableCopy];
    if (self.accessToken != nil) {
        payload[@"access_token"] = self.accessToken;
    }
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer]
                                    multipartFormRequestWithMethod:@"POST"
                                    URLString:url.absoluteString
                                    parameters:payload
                                    constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                        if (screenShot.image != nil) {
                                            [formData appendPartWithFileData:UIImagePNGRepresentation(screenShot.image) name:@"image" fileName:@"screenshot.png" mimeType:@"image/png"];
                                        }
                                    }
                                    error:&postError];
    
    if (postError != nil) {
        TMLError(@"Error posting screenshot: %@", postError);
    }
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionUploadTask *uploadTask;
    uploadTask = [manager
                  uploadTaskWithStreamedRequest:request
                  progress:nil
                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                      if (error) {
                          NSLog(@"Error: %@", error);
                      } else {
                          NSLog(@"%@ %@", response, responseObject);
                      }
                      if (completionBlock != nil) {
                          completionBlock(error == nil, error);
                      }
                  }];
    
    [uploadTask resume];
}

- (void)highlightTranslationKeyOnDashboard: (NSString *)key completionBlock:(void (^)(BOOL, NSError *))completionBlock; {
    NSString *path = [NSString stringWithFormat:@"%@/translation_keys/%@/select", [self applicationProjectPath], key];
    
    [self send:[TMLAPIRequest requestWithMethod:@"POST" path:path parameters:@{}] completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
        BOOL success = [apiResponse isSuccessfulResponse];
        if (success == NO) {
            TMLError(@"Error highlighting translation key: %@", error);
        }
        if (completionBlock != nil) {
            completionBlock(success, error);
        }
    }];
}

@end
