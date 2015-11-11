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


#import "NSString+TMLAdditions.h"
#import "TML.h"
#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLDataToken.h"
#import "TMLLanguage.h"
#import "TMLLanguageCase.h"
#import "TMLLogger.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"
#import <CommonCrypto/CommonDigest.h>

#define USE_STAGING 1

#if USE_STAGING
#define kTMLServiceHost @"https://staging-api.translationexchange.com"
#else
#define kTMLServiceHost @"https://api.translationexchange.com"
#endif

/************************************************************************************
 ** Implementation
 ************************************************************************************/

NSString * const TMLOptionsHostName = @"host";

@implementation TML

@synthesize configuration, currentApplication, defaultLanguage, currentLanguage, currentSource, currentUser, delegate, blockOptions;


// Shared instance of TML
+ (TML *)sharedInstance {
    static TML *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TML alloc] init];
    });
    return sharedInstance;
}

+ (TML *) sharedInstanceWithToken: (NSString *) token {
    return [self sharedInstanceWithToken:token launchOptions:nil];
}

+ (TML *) sharedInstanceWithToken: (NSString *) token launchOptions: (NSDictionary *) launchOptions {
    [[self sharedInstance] updateWithToken:token launchOptions:launchOptions];
    return [self sharedInstance];
}

/************************************************************************************
 ** Initialization
 ************************************************************************************/

- (id) init {
    if (self == [super init]) {
        self.configuration = [[TMLConfiguration alloc] init];
    }
    return self;
}

#pragma mark - Initialization
- (void) updateWithToken: (NSString *) token launchOptions: (NSDictionary *) launchOptions {
    NSString *host = launchOptions[TMLOptionsHostName];
    if (!host) host = kTMLServiceHost;
    
    TMLApplication *app = [[TMLApplication alloc] initWithToken: token host:host];
    self.currentApplication = app;
    
    TMLConfiguration *config = self.configuration;
    self.defaultLanguage = [app languageForLocale: config.defaultLocale];
    self.currentLanguage = [app languageForLocale: config.currentLocale];
    
    [self loadLocalLocalizationBundle];
    
    NSString *localeToLoad = self.currentLanguage.locale;
    [app loadTranslationsForLocale:localeToLoad completionBlock:^(BOOL success) {
        if (success == YES) {
            TMLInfo(@"Loaded translations for locale: %@", localeToLoad);
        }
    }];
}

- (NSArray *) findLocalTranslationBundles {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:&error];
    if (error != nil) {
        TMLError(@"Error listing main bundle files: %@", error);
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self matches '^tml_[0-9]+\\.zip'"];
    NSArray *bundles = [contents filteredArrayUsingPredicate:predicate];
    return bundles;
}

- (NSString *) latestLocalTranslationBundlePath {
    NSArray *localBundleZipFiles = [self findLocalTranslationBundles];
    if (localBundleZipFiles.count == 0) {
        TMLDebug(@"No local localization bundles found");
        return nil;
    }
    
    localBundleZipFiles = [localBundleZipFiles sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        NSString *aVersion = [a tmlTranslationBundleVersionFromPath];
        NSString *bVersion = [b tmlTranslationBundleVersionFromPath];
        return [aVersion compareToTMLTranslationBundleVersion:bVersion];
    }];
    NSString *latest = [localBundleZipFiles lastObject];
    latest = [[NSBundle mainBundle] pathForResource:[latest stringByDeletingPathExtension] ofType:[latest pathExtension]];
    return latest;
}

- (void) loadLocalLocalizationBundle {
    // TODO: no longer using cache, so this would have to be stashed elsewhere...
//    NSString *latestLocalBundlePath = [self latestLocalTranslationBundlePath];
//    NSString *latestLocalBundleVersion = [latestLocalBundlePath tmlTranslationBundleVersionFromPath];
//    TMLCache *ourCache = self.cache;
//    if (latestLocalBundlePath != nil
//        && [[NSFileManager defaultManager] fileExistsAtPath:[ourCache cachePathForTranslationBundleVersion:latestLocalBundleVersion]] == NO) {
//        [ourCache installContentsOfTranslationBundleAtPath:latestLocalBundlePath completion:^(NSString *destinationPath, BOOL success, NSError *error) {
//            if (success == YES && destinationPath != nil) {
//                NSString *latestCachedVersion = [ourCache latestTranslationBundleVersion];
//                if ([latestLocalBundleVersion compareToTMLTranslationBundleVersion:latestCachedVersion] != NSOrderedDescending) {
//                    [ourCache selectCachedTranslationBundleWithVersion:latestLocalBundleVersion];
//                }
//            }
//        }];
//    }
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

+ (void) configure:(void (^)(TMLConfiguration *config)) changes {
    changes([TML configuration]);
}

+ (TMLConfiguration *) configuration {
    return [[TML sharedInstance] configuration];
}

/************************************************************************************
 ** Block Options
 ************************************************************************************/

+ (void) beginBlockWithOptions:(NSDictionary *) options {
    [[TML sharedInstance] beginBlockWithOptions:options];
}

+ (NSObject *) blockOptionForKey: (NSString *) key {
    return [[TML sharedInstance] blockOptionForKey: key];
}

+ (void) endBlockWithOptions {
    [[TML sharedInstance] endBlockWithOptions];
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

+ (TMLApplication *) currentApplication {
    return [[TML sharedInstance] currentApplication];
}

+ (TMLLanguage *) defaultLanguage {
    return [[TML sharedInstance] defaultLanguage];
}

+ (TMLLanguage *) currentLanguage {
    return [[TML sharedInstance] currentLanguage];
}

+ (void) changeLocale:(NSString *)locale
      completionBlock:(void(^)(BOOL success))completionBlock
{
    [[TML sharedInstance] changeLocale:locale
                       completionBlock:completionBlock];
}

- (void) changeLocale:(NSString *)locale
      completionBlock:(void(^)(BOOL success))completionBlock
{
    TMLConfiguration *config = self.configuration;
    NSString *previousLocale = config.currentLocale;
    config.currentLocale = locale;
    
    TMLApplication *app = self.currentApplication;
    
    TMLLanguage *previousLanguage = self.currentLanguage;
    self.currentLanguage = (TMLLanguage *) [app languageForLocale: locale];
    
    [app resetTranslations];
    [app loadTranslationsForLocale:self.currentLanguage.locale
                   completionBlock:^(BOOL success) {
                       if (success == YES) {
                           if ([self.delegate respondsToSelector:@selector(tmlDidLoadTranslations)]) {
                               [self.delegate tmlDidLoadTranslations];
                           }
                       }
                       else {
                           self.configuration.currentLocale = previousLocale;
                           self.currentLanguage = previousLanguage;
                       }
                       if (completionBlock != nil) {
                           completionBlock(success);
                       }
                   }];
}

+ (void) reloadTranslations {
    [[TML sharedInstance] reloadTranslations];
}

- (void) reloadTranslations {
    [self.currentApplication resetTranslations];
    [self.currentApplication loadTranslationsForLocale:self.currentLanguage.locale completionBlock:^(BOOL success) {
        if (success == YES) {
            if ([self.delegate respondsToSelector:@selector(tmlDidLoadTranslations)]) {
                [self.delegate tmlDidLoadTranslations];
            }
        }
    }];
}

/************************************************************************************
 ** Translation Methods
 ************************************************************************************/

- (NSString *) callerClass {
    NSArray *stack = [NSThread callStackSymbols];
    NSString *caller = [[[stack objectAtIndex:2] componentsSeparatedByString:@"["] objectAtIndex:1];
    caller = [[caller componentsSeparatedByString:@" "] objectAtIndex:0];
    TMLDebug(@"caller: %@", stack);
    return caller;
}

- (NSObject *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    // if TML is used in a disconnected mode or has not been initialized, fallback onto English US
    if (self.currentLanguage == nil) {
        self.defaultLanguage = [TMLLanguage defaultLanguage];
        self.currentLanguage = self.defaultLanguage;
    }
    return [self.currentLanguage translate:label withDescription:description andTokens:tokens andOptions:options];
}


/************************************************************************************
 ** Localization Methods
 ************************************************************************************/

- (NSDictionary *) tokenValuesForDate: (NSDate *) date fromTokenizedFormat:(NSString *) tokenizedFormat {
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    
    NSArray *matches = [[TMLDataToken expression] matchesInString: tokenizedFormat options: 0 range: NSMakeRange(0, [tokenizedFormat length])];
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
    
//    TMLDebug(@"Tokenized date string: %@", tokenizedFormat);
//    TMLDebug(@"Tokenized date string: %@", [tokens description]);
    
    return TMLLocalizedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
}

// {days} {month_name::gen} at [bold: {hours}:{minutes}] {am_pm}
- (NSAttributedString *) localizeAttributedDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    
//    TMLDebug(@"Tokenized date string: %@", tokenizedFormat);
//    TMLDebug(@"Tokenized date string: %@", [tokens description]);
    
    return TMLLocalizedAttributedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
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

//    TMLDebug(@"Parsing date format: %@", format);
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

//    TMLDebug(@"Tokenized date string: %@", tokenizedFormat);

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
    
//    TMLDebug(@"Tokenized date string: %@", tokenizedFormat);
//    TMLDebug(@"Tokenized date string: %@", [tokens description]);

    return TMLLocalizedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
}


@end
