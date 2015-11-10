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

#import "TMLAPIClient.h"
#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLSource.h"
#import "TMLTranslation.h"

@implementation TMLSource

@synthesize application, key, translations;

- (id)copyWithZone:(NSZone *)zone {
    TMLSource *aCopy = [[TMLSource alloc] init];
    aCopy.application = [self.application copyWithZone:zone];
    aCopy.key = [self.key copyWithZone:zone];
    aCopy.translations = [self.translations copyWithZone:zone];
    return aCopy;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ Key: %@", [super description], self.key];
}

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"application"])
        self.application = [attributes objectForKey:@"application"];

    self.key = [attributes objectForKey:@"key"];
    self.translations = @{};
}

- (void) updateTranslations:(NSDictionary *)translationInfo forLocale:(NSString *)locale {
    NSMutableDictionary *newTranslations = [self.translations mutableCopy];
    newTranslations[locale]=translationInfo;
    self.translations = (NSDictionary *)newTranslations;
}

- (void) loadTranslationsForLocale:(NSString *)locale {
    [self.application.apiClient get: [NSString stringWithFormat: @"sources/%@/translations", [TMLConfiguration md5: self.key]]
                         parameters: @{@"locale": locale, @"all": @"true"}
                    completionBlock:^(TMLAPIResponse *apiResponse, NSURLResponse *response, NSError *error) {
                             if (apiResponse != nil) {
                                 [self updateTranslations:[apiResponse resultsAsTranslations] forLocale:locale];
                             }
                         }
     
     ];
}

- (NSArray *) translationsForKey:(NSString *) translationKey inLanguage: (NSString *) locale {
    if (!self.translations && ![self.translations objectForKey:locale]) return nil;
    return [[self.translations objectForKey:locale] objectForKey:translationKey];
}

@end
