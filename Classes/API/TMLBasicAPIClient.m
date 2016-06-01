//
//  TMLBasicAPIClient.m
//  TMLKit
//
//  Created by Pasha on 1/20/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TMLBasicAPIClient.h"
#import "TML.h"

@interface TMLBasicAPIClient()
@property (readwrite, strong, nonatomic) NSURL *baseURL;
@property (strong, nonatomic) NSURLSession *urlSession;
@end


@implementation TMLBasicAPIClient

- (instancetype)init {
    TMLRaiseAlternativeInstantiationMethod(@selector(initWithBaseURL:));
    return nil;
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL {
    if (self = [super init]) {
        self.baseURL = baseURL;
    }
    return self;
}

#pragma mark -

- (NSURLSession *)urlSession {
    if (_urlSession == nil) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
    }
    return _urlSession;
}

#pragma mark - Request Support

- (void) request: (NSURLRequest *) request
 completionBlock:(TMLAPIResponseHandler)completionBlock
{
    [[[self urlSession] dataTaskWithRequest: request
                                     completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
                                         dispatch_async(dispatch_get_main_queue(), ^(void){
                                             [self processResponse:response
                                                              data:data
                                                             error:error
                                                   completionBlock:completionBlock];
                                         });
                                     }] resume];
}

#pragma mark - GET

- (void) get:(NSString *)path
  parameters:(NSDictionary *)parameters
completionBlock:(TMLAPIResponseHandler)completionBlock
{
    [self get:path
   parameters:parameters
  cachePolicy:NSURLRequestUseProtocolCachePolicy
completionBlock:completionBlock];
}

#pragma mark - POST

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
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:cachePolicy
                                         timeoutInterval:TMLSharedConfiguration().timeoutIntervalForRequest];
    
    TMLDebug(@"GET %@", url);
    [self request:request
  completionBlock:completionBlock];
}

- (void) post:(NSString *)path
   parameters:(NSDictionary *)parameters
  cachePolicy:(NSURLRequestCachePolicy)cachePolicy
completionBlock:(TMLAPIResponseHandler)completionBlock
{
    NSURL *url = [self URLForAPIPath:path parameters:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:cachePolicy
                                                       timeoutInterval:TMLSharedConfiguration().timeoutIntervalForRequest];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];    
    [request setHTTPBody:[[self urlEncodedStringFromParameters: parameters] dataUsingEncoding:NSUTF8StringEncoding]];
    
    TMLDebug(@"POST %@", url);
    [self request:request
  completionBlock:completionBlock];
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


#pragma mark - URL Utils

- (NSURL *) URLForAPIPath: (NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableString *pathString = [NSMutableString stringWithFormat:@"%@/%@", self.baseURL, path];
    [pathString appendString:@"?"];
    for (NSString *key in parameters) {
        id value = [parameters objectForKey:key];
        NSString *valueClass = NSStringFromClass([value class]);
        if ([valueClass rangeOfString:@"Boolean"].location != NSNotFound) {
            value = ([value boolValue] == YES) ? @"true" : @"false";
        }
        [pathString appendFormat:@"&%@=%@", [self urlEncode:key], [self urlEncode:value]];
    }
    return [NSURL URLWithString:pathString];
}

- (NSString *) urlEncode: (id) object {
    NSString *string = [NSString stringWithFormat: @"%@", object];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
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

@end
