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

#import "TMLPostOffice.h"
#import "TMLApplication.h"

@implementation TMLPostOffice

- (id) initWithApplication: (TMLApplication *) owner {
    if (self == [super init]) {
        self.application = owner;
    }
    return self;
}

- (NSString *) host {
    NSString *host = [self.application.tools objectForKey: @"postoffice"];
    if(!host) host = @"https://postoffice.translationexchange.com";
    return host;
}

- (NSString *) apiFullPath: (NSString *) path {
    return [NSString stringWithFormat:@"%@/api/v1/%@", [self host], path];
}

- (void) deliver:(NSString *)templateKeyword
              to:(NSString *)to
          tokens:(NSDictionary *)tokens
 completionBlock:(TMLAPIResponseHandler)completionBlock
{
 
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:tokens forKey:@"tokens"];
    [params setObject:to forKey:@"to"];
    
    [self.application.apiClient post:[self apiFullPath:[NSString stringWithFormat:@"templates/%@/deliver", templateKeyword]]
                          parameters:params
                     completionBlock:completionBlock];
}

- (void) registerToken: (NSString *) token {
    [self registerToken:token options:@{}];
}

- (void) registerToken: (NSString *) token options: (NSDictionary *) options {
    [self registerToken:token
                options:options
        completionBlock:nil];
}

- (void) registerToken:(NSString *)token
               options:(NSDictionary *)options
               completionBlock:(TMLAPIResponseHandler)completionBlock;
{
//    
//    if (!token) return;
//        
//    NSMutableDictionary *params = [NSMutableDictionary dictionary];
//    [params setObject:application.key forKey:@"client_id"];
//    [params setObject:token forKey:@"device_token"];
//    [params setObject:[[TML currentLanguage] locale] forKey:@"locale"];
//
//    NSArray *keys = @[@"name", @"first_name", @"last_name", @"gender", @"tokens", @"external_id", @"email", @"phone_number", @"country_code", @"list", @"lists"];
//    for (NSString *key in keys) {
//        if ([options valueForKey:key])
//            [params setObject:[options valueForKey:key] forKey:key];
//    }
//
//    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
//
//    if ([params objectForKey:@"tokens"]) {
//        [tokens addEntriesFromDictionary: [params objectForKey:@"tokens"]];
//    }
//    
//    if ([params objectForKey:@"tokens"]) {
//        NSError *error;
//        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tokens options:0 error:&error];
//        if (jsonData) {
//            [params setObject:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] forKey:@"tokens"];
//        }
//    }
//    
//    [self.application.apiClient post: [self apiFullPath: @"contacts/register"]
//                          parameters: params
//                     completionBlock:completionBlock
//     ];
}

@end
