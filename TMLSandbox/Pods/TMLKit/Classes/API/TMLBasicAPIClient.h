//
//  TMLBasicAPIClient.h
//  TMLKit
//
//  Created by Pasha on 1/20/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

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
