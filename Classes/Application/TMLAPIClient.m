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

NSString * const TMLAPIResponseResultKey = @"results";

@implementation TMLAPIClient

@synthesize application;

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
    if (parameters != nil) {
        [pathString appendString:@"?"];
        NSDictionary *requestParameters = [self prepareAPIParameters:parameters];
        for (NSString *key in requestParameters) {
            id value = [parameters objectForKey:key];
            [pathString appendFormat:@"%@=%@", [self urlEncode:key], [self urlEncode:value]];
        }
    }
    return [NSURL URLWithString:pathString];
}

- (NSDictionary *) prepareAPIParameters:(NSDictionary *)params {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    [parameters setObject: self.application.accessToken forKey: @"access_token"];
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

- (NSObject *) parseData: (NSData *) data {
    NSError *error = nil;
    NSObject *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error) {
        TMLDebug(@"Error trace: %@", error);
        return nil;
    }
    
    if ([responseObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *responseData = (NSDictionary *) responseObject;
        if ([responseData valueForKey:@"error"] != nil) {
            TMLDebug(@"Error trace: %@", [responseData valueForKey:@"error"]);
            return nil;
        }
    }
    
    return responseObject;
}

- (void) processResponse:(NSURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *)error
         completionBlock:(TMLAPIResponseHandler)completionBlock
{
    if (error) {
        TMLError(@"Error: %@", error);
    }
    
    id responseData = [self parseData:data];
    if (!responseData) {
        TMLWarn(@"Empty response object: %@", responseData);
        if (error == nil) {
            error = [NSError errorWithDomain:@"Failed to retrieve data" code:0 userInfo:nil];
        }
    }
    
    TMLAPIResponse *apiResponse = [[TMLAPIResponse alloc] initFromResponseResultObject:responseData];
    
    if (completionBlock != nil) {
        completionBlock(apiResponse, response, error);
    }
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

@end
