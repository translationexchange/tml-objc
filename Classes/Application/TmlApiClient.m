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

#import "TMLApiClient.h"
#import "TML.h"
#import "TMLApplication.h"

@implementation TMLApiClient

@synthesize application;

- (id) initWithApplication: (TMLApplication *) owner {
    if (self == [super init]) {
        self.application = owner;
    }
    return self;
}

- (NSString *) apiFullPath: (NSString *) path {
    if ([path rangeOfString:@"http"].location != NSNotFound)
        return path;
    return [NSString stringWithFormat:@"%@/v1/%@", self.application.host, path];
}

- (NSDictionary *) apiParameters: (NSDictionary *) params {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    [parameters setObject: self.application.accessToken forKey: @"access_token"];
    return parameters;
}

- (NSString *) urlEncode: (id) object {
    NSString *string = [NSString stringWithFormat: @"%@", object];
    return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

- (NSString*) urlEncodedStringFromParams: (NSDictionary *) params {
    NSMutableArray *parts = [NSMutableArray array];
    for (id paramKey in params) {
        id paramValue = [params objectForKey: paramKey];
        NSString *part = [NSString stringWithFormat: @"%@=%@", [self urlEncode: paramKey], [self urlEncode: paramValue]];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

- (NSObject *) parseData: (NSData *) data {
//    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    TMLDebug(@"Response: %@", json);
    
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

- (void) processResponseWithData: (NSData *)data
                           error: (NSError *)error
                         options: (NSDictionary *) options
                         success: (void (^)(id responseObject)) success
                         failure: (void (^)(NSError *error)) failure {
    if (error) {
        TMLDebug(@"Error: %@", error);
        failure(error);
        return;
    }
    
    if (!data) {
        success(nil);
        return;
    }
    
    NSObject *responseObject = [self parseData:data];
//    if (!responseObject) {
//        error = [NSError errorWithDomain:@"Failed to retrieve data" code:0 userInfo:nil];
//        failure(error);
//        return;
//    }
    
    if ([options objectForKey:@"cache_key"]) {
        [TML.cache storeData: data forKey: [options objectForKey:@"cache_key"] withOptions: options];
    }
    
    success(responseObject);
}

- (void) request: (NSURLRequest *) request
         options: (NSDictionary *) options
         success: (void (^)(id responseObject)) success
         failure: (void (^)(NSError *error)) failure
{
    if (NSClassFromString(@"NSURLSession") != nil) {
        [[[NSURLSession sharedSession] dataTaskWithRequest: request
                                         completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
                                             dispatch_async(dispatch_get_main_queue(), ^(void){
                                                 [self processResponseWithData:data error:error options:options success:success failure:failure];
                                             });
                                         }] resume];
        
    } else {
        [NSURLConnection sendAsynchronousRequest: request
                                           queue: [NSOperationQueue mainQueue]
                               completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
                                   dispatch_async(dispatch_get_main_queue(), ^(void){
                                       [self processResponseWithData:data error:error options:options success:success failure:failure];
                                   });
                               }];
    }
}

- (void) get: (NSString *) path
      params: (NSDictionary *) params
     options: (NSDictionary *) options
     success: (void (^)(id responseObject)) success
     failure: (void (^)(NSError *error)) failure
{
    
    if ([options objectForKey:@"cache_key"]) {
        NSObject *data = [TML.cache fetchObjectForKey:[options objectForKey:@"cache_key"]];
        if (data) {
            success(data);
            return;
        }
    }
    
    NSString *fullPathWithQuery = [NSString stringWithFormat:@"%@?%@", [self apiFullPath: path], [self urlEncodedStringFromParams: [self apiParameters: params]]];
    TMLDebug(@"GET %@", fullPathWithQuery);

    NSURL *url = [NSURL URLWithString:fullPathWithQuery];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    if ([options objectForKey:@"realtime"]) {
        // Synchronous get for loading sources realtime - in translation mode only
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        [self processResponseWithData:data error:error options:options success:success failure:failure];
    } else {
        [self request:request options:options success:success failure:failure];
    }
}

- (void) post: (NSString *) path
       params: (NSDictionary *) params
      options: (NSDictionary *) options
      success: (void (^)(id responseObject)) success
      failure: (void (^)(NSError *error)) failure
{
//    TMLDebug(@"POST %@", [self apiFullPath: path]);

    NSURL *url = [NSURL URLWithString:[self apiFullPath: path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[self urlEncodedStringFromParams: [self apiParameters: params]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self request:request options:options success:success failure:failure];
}

@end
