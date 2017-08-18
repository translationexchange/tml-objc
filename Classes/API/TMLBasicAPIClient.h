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
#import "TMLAPIResponse.h"

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


#pragma mark - TMLBasicAPIClient

@interface TMLBasicAPIClient : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL;
@property (readonly, strong, nonatomic) NSURL *baseURL;

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

@end
