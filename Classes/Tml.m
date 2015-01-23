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


#import "Tml.h"
#import <CommonCrypto/CommonDigest.h>
#import "TmlTranslationKey.h"
#import "TmlTranslation.h"
#import "TmlCache.h"
#import "TmlLanguageCase.h"
#import "TmlDataToken.h"
#import "TmlReachability.h"

#define kTmlServiceHost @"https://api.translationexchange.com"

/************************************************************************************
 ** Implementation
 ************************************************************************************/

@implementation Tml

@synthesize configuration, cache;
@synthesize currentApplication, defaultLanguage, currentLanguage, currentSource, currentUser, delegate;
@synthesize blockOptions;

static Tml *sharedInstance = nil;

// Shared instance of Tml
+ (Tml *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] init];
        sharedInstance.configuration = [[TmlConfiguration alloc] init];
    });
    return sharedInstance;
}

+ (Tml *) sharedInstanceWithToken: (NSString *) token {
    return [self sharedInstanceWithToken:token launchOptions:nil];
}

+ (Tml *) sharedInstanceWithToken: (NSString *) token launchOptions: (NSDictionary *) launchOptions {
    [[self sharedInstance] updateWithToken:token launchOptions:launchOptions];
    return [self sharedInstance];
}

/************************************************************************************
 ** Initialization
 ************************************************************************************/

- (void) updateWithToken: (NSString *) token launchOptions: (NSDictionary *) launchOptions {
    self.cache = [[TmlCache alloc] initWithKey: token];
    
    NSString *host = [launchOptions objectForKey:@"host"];
    if (!host) host = kTmlServiceHost;
    
    [self initReachabilityForHost: host];
    
    self.currentApplication = [[TmlApplication alloc] initWithToken: token host:host];
    self.defaultLanguage = [self.currentApplication languageForLocale: self.configuration.defaultLocale];
    self.currentLanguage = [self.currentApplication languageForLocale: self.configuration.currentLocale];
    
    [self.currentApplication loadTranslationsForLocale:self.currentLanguage.locale withOptions:@{} success:^{
        TmlDebug(@"Loaded translations for current locale!");
    } failure:^(NSError *error) {
        TmlDebug(@"Failed to load translations!");
    }];
    
    [self.currentApplication log];
}

- (void) initReachabilityForHost: (NSString *) host {
    TmlDebug(@"Initializing reachability for %@", host);
    self.reachability = [TmlReachability reachabilityForInternetConnection];
    self.reachability.reachableBlock = ^(TmlReachability*reach) {
        TmlDebug(@"Tml connection is available");
        [[NSNotificationCenter defaultCenter] postNotificationName: TmlIsReachableNotification object: nil];
    };
    self.reachability.unreachableBlock = ^(TmlReachability*reach) {
        TmlDebug(@"Tml connection is not available");
        [[NSNotificationCenter defaultCenter] postNotificationName: TmlIsUnreachableNotification object: nil];
    };
    [self.reachability startNotifier];
}

+ (NSString *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    NSMutableDictionary *opts = [NSMutableDictionary dictionaryWithDictionary:options];
    [opts setObject:@"html" forKey:@"tokenizer"];
    return (NSString *) [[self sharedInstance] translate:label withDescription:description andTokens:tokens andOptions:opts];
}

+ (NSAttributedString *) translateAttributedString:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    NSMutableDictionary *opts = [NSMutableDictionary dictionaryWithDictionary:options];
    [opts setObject:@"attributed" forKey:@"tokenizer"];
    return (NSAttributedString *) [[self sharedInstance] translate:label withDescription:description andTokens:tokens andOptions:opts];
}

+ (NSString *) localizeDate:(NSDate *) date withFormat:(NSString *) format andDescription: (NSString *) description {
    return [[self sharedInstance] localizeDate: date withFormat: format andDescription: description];
}

+ (NSString *) localizeDate:(NSDate *) date withFormatKey:(NSString *) formatKey andDescription: (NSString *) description {
    return [[self sharedInstance] localizeDate: date withFormatKey: formatKey andDescription: description];
}

+ (NSString *) localizeDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    return [[self sharedInstance] localizeDate: date withTokenizedFormat: tokenizedFormat andDescription: description];
}

+ (NSAttributedString *) localizeAttributedDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    return [[self sharedInstance] localizeAttributedDate: date withTokenizedFormat: tokenizedFormat andDescription: description];
}


/************************************************************************************
 ** Configuration
 ************************************************************************************/

+ (BOOL) isReachable {
    return [[Tml sharedInstance].reachability isReachable];
}

+ (void) configure:(void (^)(TmlConfiguration *config)) changes {
    changes([Tml sharedInstance].configuration);
}

+ (TmlConfiguration *) configuration {
    return [[Tml sharedInstance] configuration];
}

+ (TmlCache *) cache {
    return [[Tml sharedInstance] cache];
}

/************************************************************************************
 ** Block Options
 ************************************************************************************/

+ (void) beginBlockWithOptions:(NSDictionary *) options {
    [[Tml sharedInstance] beginBlockWithOptions:options];
}

+ (NSObject *) blockOptionForKey: (NSString *) key {
    return [[Tml sharedInstance] blockOptionForKey: key];
}

+ (void) endBlockWithOptions {
    [[Tml sharedInstance] endBlockWithOptions];
}

- (void) beginBlockWithOptions:(NSDictionary *) options {
    if (self.blockOptions == nil)
        self.blockOptions = [NSMutableArray array];
    
    [self.blockOptions insertObject:options atIndex:0];
}

- (NSDictionary *) currentBlockOptions {
    if (self.blockOptions == nil)
        self.blockOptions = [NSMutableArray array];
    
    if ([self.blockOptions count] == 0)
        return [NSDictionary dictionary];

    return [self.blockOptions objectAtIndex:0];
}

- (NSObject *) blockOptionForKey: (NSString *) key {
    return [[self currentBlockOptions] objectForKey:key];
}

- (void) endBlockWithOptions {
    if (self.blockOptions == nil)
        return;
    
    if ([self.blockOptions count] == 0)
        return;
    
    [self.blockOptions removeObjectAtIndex:0];
}

/************************************************************************************
 ** Class Methods
 ************************************************************************************/

+ (TmlApplication *) currentApplication {
    return [[Tml sharedInstance] currentApplication];
}

+ (TmlLanguage *) defaultLanguage {
    return [[Tml sharedInstance] defaultLanguage];
}

+ (TmlLanguage *) currentLanguage {
    return [[Tml sharedInstance] currentLanguage];
}

+ (void) changeLocale: (NSString *) locale success: (void (^)()) success failure: (void (^)(NSError *error)) failure {
    [[Tml sharedInstance] changeLocale:locale success:success failure:failure];
}

- (void) changeLocale: (NSString *) locale success: (void (^)()) success failure: (void (^)(NSError *error)) failure {
    NSString *previousLocale = self.configuration.currentLocale;
    self.configuration.currentLocale = locale;
    BOOL hasBackup = [cache backupCacheForLocale: locale];
    
    TmlLanguage *previousLanguage = self.currentLanguage;
    self.currentLanguage = (TmlLanguage *) [self.currentApplication languageForLocale: locale];
    
    [self.currentApplication resetTranslations];
    [self.currentApplication loadTranslationsForLocale:self.currentLanguage.locale withOptions:@{@"offline": @YES} success:^{
        if ([self.delegate respondsToSelector:@selector(tr8nDidLoadTranslations)]) {
            [self.delegate tr8nDidLoadTranslations];
        }
        
        success();
        
    } failure:^(NSError *error) {
        // restore backup folder and load translation from previous backup
        [cache restoreCacheBackupForLocale:locale];
        
        if (hasBackup) {
            [self.currentApplication resetTranslations];
            [self.currentApplication loadTranslationsForLocale:self.currentLanguage.locale withOptions:@{@"offline": @YES} success:^{
                if ([self.delegate respondsToSelector:@selector(tr8nDidLoadTranslations)]) {
                    [self.delegate tr8nDidLoadTranslations];
                }
                success();
            } failure:^(NSError *error) {
                self.configuration.currentLocale = previousLocale;
                self.currentLanguage = previousLanguage;
                failure(error);
            }];
        } else {
            self.configuration.currentLocale = previousLocale;
            self.currentLanguage = previousLanguage;
            failure(error);
        }
    }];
}

+ (void) reloadTranslations {
    [[Tml sharedInstance] reloadTranslations];
}

- (void) reloadTranslations {
    [cache backupCacheForLocale: self.currentLanguage.locale];

    [self.currentApplication resetTranslations];
    [self.currentApplication loadTranslationsForLocale:self.currentLanguage.locale withOptions:@{@"offline": @YES} success:^{
        if ([self.delegate respondsToSelector:@selector(tr8nDidLoadTranslations)]) {
            [self.delegate tr8nDidLoadTranslations];
        }
    } failure:^(NSError *error) {
        [cache restoreCacheBackupForLocale: self.currentLanguage.locale];
    }];
}

/************************************************************************************
 ** Translation Methods
 ************************************************************************************/

- (NSString *) callerClass {
    NSArray *stack = [NSThread callStackSymbols];
    NSString *caller = [[[stack objectAtIndex:2] componentsSeparatedByString:@"["] objectAtIndex:1];
    caller = [[caller componentsSeparatedByString:@" "] objectAtIndex:0];
    TmlDebug(@"caller: %@", stack);
    return caller;
}

- (NSObject *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    // if Tml is used in a disconnected mode or has not been initialized, fallback onto English US
    if (self.currentLanguage == nil) {
        self.defaultLanguage = [TmlLanguage defaultLanguage];
        self.currentLanguage = self.defaultLanguage;
    }
    return [self.currentLanguage translate:label withDescription:description andTokens:tokens andOptions:options];
}


/************************************************************************************
 ** Localization Methods
 ************************************************************************************/

- (NSDictionary *) tokenValuesForDate: (NSDate *) date fromTokenizedFormat:(NSString *) tokenizedFormat {
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    
    NSArray *matches = [[TmlDataToken expression] matchesInString: tokenizedFormat options: 0 range: NSMakeRange(0, [tokenizedFormat length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *tokenName = [tokenizedFormat substringWithRange:[match range]];
        
        if (tokenName) {
            [tokens setObject:[[self configuration] dateValueForToken: tokenName inDate:date] forKey:[tokenName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]]];
        }
    }
    
    return tokens;
}

// {months_padded}/{days_padded}/{years} at {hours}:{minutes}
- (NSString *) localizeDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    
//    TmlDebug(@"Tokenized date string: %@", tokenizedFormat);
//    TmlDebug(@"Tokenized date string: %@", [tokens description]);
    
    return TmlLocalizedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
}

// {days} {month_name::gen} at [bold: {hours}:{minutes}] {am_pm}
- (NSAttributedString *) localizeAttributedDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    
//    TmlDebug(@"Tokenized date string: %@", tokenizedFormat);
//    TmlDebug(@"Tokenized date string: %@", [tokens description]);
    
    return TmlLocalizedAttributedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
}

// default_format
- (NSString *) localizeDate:(NSDate *) date withFormatKey:(NSString *) formatKey andDescription: (NSString *) description {
    NSString *format = [[self configuration] customDateFormatForKey: formatKey];
    if (!format) return formatKey;
    return [self localizeDate: date withFormat:format andDescription: description];
}

// MM/dd/yyyy at h:m
- (NSString *) localizeDate:(NSDate *) date withFormat:(NSString *) format andDescription: (NSString *) description {
    NSError *error = NULL;
    NSRegularExpression *expression = [NSRegularExpression
                                  regularExpressionWithPattern: @"[\\w]*"
                                  options: NSRegularExpressionCaseInsensitive
                                  error: &error];

//    TmlDebug(@"Parsing date format: %@", format);
    NSString *tokenizedFormat = format;
    
    NSArray *matches = [expression matchesInString: format options: 0 range: NSMakeRange(0, [format length])];
    NSMutableArray *elements = [NSMutableArray array];
    
    int index = 0;
    for (NSTextCheckingResult *match in matches) {
        NSString *element = [format substringWithRange:[match range]];
        [elements addObject:element];
        NSString *placeholder = [NSString stringWithFormat: @"{%d}", index++];
        tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:element withString: placeholder];
    }

//    TmlDebug(@"Tokenized date string: %@", tokenizedFormat);

    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    
    for (index=0; index<[elements count]; index++) {
        NSString *element = [elements objectAtIndex:index];
        NSString *tokenName = [[self configuration] dateTokenNameForKey: element];
        NSString *placeholder = [NSString stringWithFormat: @"{%d}", index];
        
        if (tokenName) {
            tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:placeholder withString:tokenName];
            [tokens setObject:[[self configuration] dateValueForToken: tokenName inDate:date] forKey:[tokenName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]]];
        } else
            tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:placeholder withString:element];
    }
    
//    TmlDebug(@"Tokenized date string: %@", tokenizedFormat);
//    TmlDebug(@"Tokenized date string: %@", [tokens description]);

    return TmlLocalizedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
}


@end
