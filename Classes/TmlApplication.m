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

#import "TmlApplication.h"
#import "TmlCache.h"
#import "TmlLanguage.h"
#import "TmlSource.h"
#import "TmlTranslation.h"
#import "Tml.h"
#import "TmlApiClient.h"
#import "TmlPostOffice.h"
#import "TmlConfiguration.h"

@implementation TmlApplication

@synthesize host, key, accessToken, secret, name, description, defaultLocale, threshold, features, tools;
@synthesize translationKeys, translations, languagesByLocales, sourcesByKeys, missingTranslationKeysBySources, scheduler;
@synthesize apiClient, postOffice;

+ (NSString *) cacheKey {
    return @"application";
}

- (id) initWithToken: (NSString *) token host: (NSString *) appHost {
    if (self = [super init]) {
        self.host = appHost;
        self.accessToken = token;
        self.apiClient = [[TmlApiClient alloc] initWithApplication:self];
        self.postOffice = [[TmlPostOffice alloc] initWithApplication:self];
        
        [self updateAttributes:@{@"name": @"Loading...",
                                 @"default_locale": @"en-US",
                                 @"treshold": [NSNumber numberWithInt:0]}];
        
        [self load];
    }
    return self;
}

- (void) updateAttributes: (NSDictionary *) attributes {
    self.key = [attributes objectForKey:@"key"];
    self.name = [attributes objectForKey:@"name"];
    self.description = [attributes objectForKey:@"description"];
    self.defaultLocale = [attributes objectForKey:@"default_locale"];
    self.threshold = [attributes objectForKey:@"threshold"];
    self.features = [attributes objectForKey:@"features"];
    self.tools = [attributes objectForKey:@"tools"];

    self.translations = [NSMutableDictionary dictionary];
    self.languagesByLocales = [NSMutableDictionary dictionary];
    self.sourcesByKeys = [NSMutableDictionary dictionary];
    self.missingTranslationKeysBySources = [NSMutableDictionary dictionary];
}

- (void) load {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@"true" forKey:@"definition"];
    [params setObject:@"ios" forKey:@"client"];

    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"])
        [params setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] forKey:@"bundle_id"];
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"])
        [params setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] forKey:@"display_name"];
    
    [self.apiClient get: @"applications/current"
                 params: params
//                options: @{@"realtime": @true, @"cache_key": [TmlApplication cacheKey]}
                options: @{@"realtime": @true}
                success: ^(id data) {
                   [self updateAttributes:data];
                }
                failure: ^(NSError *error) {
                }
     ];
}

- (void) log {
    NSDate *lastLogDate = (NSDate*) [TmlConfiguration persistentValueForKey:@"last_log_date"];
    
    if (lastLogDate) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
        NSDate *today = [cal dateFromComponents:components];
        components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:lastLogDate];
        NSDate *otherDate = [cal dateFromComponents:components];
        
        if([today isEqualToDate:otherDate]) {
            return;
        }
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject: [TmlConfiguration uuid] forKey:@"uuid"];
    [params setObject: @"ios" forKey:@"sdk"];
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(model)])
        [params setObject:[[UIDevice currentDevice] model] forKey:@"client"];

    TmlConfiguration *config = [Tml sharedInstance].configuration;
    
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDevelopmentRegion"])
        [params setObject:[config deviceLocale] forKey:@"client_locale"];
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDevelopmentRegion"])
        [params setObject:[config currentLocale] forKey:@"selected_locale"];
    
    [self.apiClient get: @"applications/current/log"
                 params: params
                options: @{}
                success: ^(id data) {
                    [TmlConfiguration setPersistentValue:[NSDate date] forKey:@"last_log_date"];
                }
                failure: ^(NSError *error) {
                }
     ];
}

- (NSString *) transltionsCacheKeyForLocale: (NSString *) locale {
    return [NSString stringWithFormat:@"%@/translations", locale];
}

- (void) resetTranslationsCacheForLocale: (NSString *) locale {
    [Tml.cache resetCacheForKey:[self transltionsCacheKeyForLocale:locale]];
}

- (BOOL) isTranslationCacheEmpty {
    return (self.translations == nil || [self.translations allKeys].count == 0);
}

- (void) updateTranslations:(NSDictionary *) data forLocale: locale {
    NSMutableDictionary *localeTranslations = [NSMutableDictionary dictionary];
    
    NSDictionary *results = [data objectForKey:@"results"];
    NSArray *translationsData;
    NSMutableArray *newTranslations;
    
//    TmlDebug(@"%@", data);

    if (!self.translationKeys)
        self.translationKeys = [NSMutableDictionary dictionary];
    
    for (NSString *tkey in [results allKeys]) {
        [self.translationKeys setObject: tkey forKey:tkey];
        
        if ([[results objectForKey:tkey] isKindOfClass:[NSDictionary class]])
            translationsData = [[results objectForKey:tkey] objectForKey:@"translations"];
        else if ([[results objectForKey:tkey] isKindOfClass:[NSArray class]])
            translationsData = [results objectForKey:tkey];
        else
            continue;
        
        newTranslations = [NSMutableArray array];
        for (NSDictionary* translation in translationsData) {
            [newTranslations addObject:[[TmlTranslation alloc] initWithAttributes:@{
                 @"label": [translation valueForKey:@"label"],
                 @"locale": ([translation valueForKey:@"locale"] == nil ? locale : [translation valueForKey:@"locale"]),
                 @"context": ([translation valueForKey:@"context"] == nil ? @{} : [translation valueForKey:@"context"]),
            }]];
        }
        
        [localeTranslations setObject:newTranslations forKey:tkey];
    }
    
    NSMutableDictionary *trans = [NSMutableDictionary dictionaryWithDictionary:self.translations];
    [trans setObject:localeTranslations forKey:locale];
    self.translations = trans;
}

- (void) loadTranslationsForLocale: (NSString *) locale
                       withOptions: (NSDictionary *) options
                           success: (void (^)()) success
                           failure: (void (^)(NSError *error)) failure
{
    [self.apiClient get: @"applications/current/translations"
                 params: @{@"locale": locale, @"all": @"true"}
                options: @{@"cache_key": [self transltionsCacheKeyForLocale:locale]}
      success: ^(id responseObject) {
          [self updateTranslations:responseObject forLocale:locale];
          [[NSNotificationCenter defaultCenter] postNotificationName: TmlLanguageChangedNotification object: locale];
          success();
      }
      failure: ^(NSError *error) {
          NSDictionary *data = (NSDictionary *) [Tml.cache fetchObjectForKey: [self transltionsCacheKeyForLocale:locale]];
          if (data) {
              [self updateTranslations:data forLocale:locale];
              success();
              return;
          }
          failure(error);
      }];
}

- (BOOL) isTranslationKeyRegistered: (NSString *) translationKey {
    return [self.translationKeys objectForKey:translationKey] != nil;
}

- (NSArray *) translationsForKey:(NSString *) translationKey inLanguage: (NSString *) locale {
    if (!self.translations && ![self.translations objectForKey:locale]) return nil;
    return [[self.translations objectForKey:locale] objectForKey:translationKey];
}

- (void) resetTranslations {
    self.translations = @{};
    self.translationKeys = [NSMutableDictionary dictionary];
    self.sourcesByKeys = [NSMutableDictionary dictionary];
}

- (TmlLanguage *) languageForLocale: (NSString *) locale {
    if ([self.languagesByLocales objectForKey:locale]) {
        return [self.languagesByLocales objectForKey:locale];
    }
    
    TmlLanguage *language = [[TmlLanguage alloc] initWithAttributes:@{@"locale": locale, @"application": self}];
    [language load];
    [self.languagesByLocales setObject:language forKey:locale];
    
    TmlDebug(@"Language: %@", [language description]);
    
    return language;
}

- (TmlSource *) sourceForKey: (NSString *) sourceKey andLocale: (NSString *) locale {
    if (sourceKey == nil)
        return nil;
    
    if ([self.sourcesByKeys objectForKey:sourceKey] != nil) {
        return [self.sourcesByKeys objectForKey:sourceKey];
    }
    
    TmlSource *source = [[TmlSource alloc] initWithAttributes:@{@"key": sourceKey, @"application": self}];
    [source loadTranslationsForLocale:locale];
    [self.sourcesByKeys setObject:source forKey:sourceKey];
    
    return source;
}

- (void) registerMissingTranslationKey: (NSObject *) translationKey {
    [self registerMissingTranslationKey:translationKey forSource:nil];
}

- (void) registerMissingTranslationKey: (NSObject *) translationKey forSource: (TmlSource *) source {
    TmlTranslationKey *tkey = (TmlTranslationKey *) translationKey;
    if ([tkey.label isEqualToString:@""])
        return;
    
    if (self.missingTranslationKeysBySources == nil) {
        self.missingTranslationKeysBySources = [NSMutableDictionary dictionary];
    }
    
    NSString *sourceKey = @"Tml";
    if (source) sourceKey = source.key;

    NSMutableDictionary *sourceKeys = [self.missingTranslationKeysBySources objectForKey:sourceKey];
    if (sourceKeys == nil) {
        sourceKeys = [NSMutableDictionary dictionary];
        [self.missingTranslationKeysBySources setObject:sourceKeys forKey:sourceKey];
    }
    
    if ([sourceKeys objectForKey:tkey.key] == nil) {
        [sourceKeys setObject:tkey forKey:tkey.key];
    }
    
    if (self.scheduler == nil) {
        TmlDebug(@"Setting up scheduler for 3 seconds...");
        self.scheduler = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(submitMissingTranslationKeys) userInfo:nil repeats:NO];
    }
}

- (void) submitMissingTranslationKeys {
    if (self.missingTranslationKeysBySources == nil || [[self.missingTranslationKeysBySources allKeys] count] == 0) {
        self.scheduler = nil;
        return;
    }

    TmlDebug(@"Submitting missing translations...");
    

    NSMutableArray *params = [NSMutableArray array];

    NSArray *sourceKeys = [self.missingTranslationKeysBySources allKeys];
    for (NSString *sourceKey in sourceKeys) {
        NSDictionary *keys = [self.missingTranslationKeysBySources objectForKey:sourceKey];
        NSMutableArray *keysData = [NSMutableArray array];
        for (TmlTranslationKey *tkey in [keys allValues]) {
            [keysData addObject:[tkey toDictionary]];
        }
        
        [params addObject:@{@"source": sourceKey, @"keys": keysData}];
    }
    
    [self.missingTranslationKeysBySources removeAllObjects];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:(NSJSONWritingPrettyPrinted) error:&error];
    
    TmlDebug(@"%@", params);
    
    [self.apiClient post: @"sources/register_keys"
        params: @{@"source_keys": [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]}
       options: @{}
       success: ^(id responseObject) {
           for (NSString *sourceKey in sourceKeys) {
               [self.sourcesByKeys removeObjectForKey:sourceKey];
               [[Tml cache] resetCacheForKey:[TmlSource cacheKeyForLocale:[[Tml currentLanguage] locale] andKey:sourceKey]];
           }
           
           [self submitMissingTranslationKeys];
       } failure: ^(NSError *error) {
           TmlError(@"Failed to submit missing translation keys: %@", [error description]);
           self.scheduler = nil;
       }];
}

@end
