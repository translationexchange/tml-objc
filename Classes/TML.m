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
#import "TMLAPIBundle.h"
#import "TMLApplication.h"
#import "TMLBundle.h"
#import "TMLBundleManager.h"
#import "TMLConfiguration.h"
#import "TMLDataToken.h"
#import "TMLLanguage.h"
#import "TMLLanguageCase.h"
#import "TMLLogger.h"
#import "TMLPostOffice.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"
#import <CommonCrypto/CommonDigest.h>

NSString * const TMLLanguageChangedNotification = @"TMLLanguageChangedNotification";
NSString * const TMLIsReachableNotification = @"TMLIsReachableNotification";
NSString * const TMLIsUnreachableNotification = @"TMLIsUnreachableNotification";

NSString * const TMLLanguagePreviousLocaleUserInfoKey = @"TMLLanguagePreviousLocaleUserInfoKey";

NSString * const TMLOptionsHostName = @"host";

NSString * const TMLBundleDidChangeNotification = @"TMLBundleDidChangeNotification";

@interface TML() {
    NSTimer *_translationSubmissionTimer;
    BOOL _observingNotifications;
}
@property(strong, nonatomic) TMLConfiguration *configuration;
@property(strong, nonatomic) NSString *applicationKey;
@property(strong, nonatomic) NSString *accessToken;
@property(strong, nonatomic) TMLAPIClient *apiClient;
@property(strong, nonatomic) TMLPostOffice *postOffice;
@property(nonatomic, readwrite) TMLBundle *currentBundle;
@property(nonatomic, strong) NSMutableDictionary <NSString *, NSMutableSet *>*missingTranslationKeysBySources;
@end

@implementation TML


// Shared instance of TML
+ (TML *)sharedInstance {
    static TML *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TML alloc] init];
    });
    return sharedInstance;
}

+ (TML *) sharedInstanceWithApplicationKey:(NSString *)applicationKey
                               accessToken:(NSString *)token
{
    return [self sharedInstanceWithApplicationKey:applicationKey
                                      accessToken:token
                                    configuration:nil];
}

+ (TML *) sharedInstanceWithApplicationKey:(NSString *)applicationKey accessToken:(NSString *)token configuration:(TMLConfiguration *)configuration {
    [[self sharedInstance] updateWithApplicationKey:applicationKey accessToken:token configuration:configuration];
    return [self sharedInstance];
}

#pragma mark - Init

- (id) init {
    if (self == [super init]) {
        self.configuration = [[TMLConfiguration alloc] init];
        self.missingTranslationKeysBySources = [NSMutableDictionary dictionary];
        [self setupNotificationObserving];
    }
    return self;
}

- (void)dealloc {
    [self stopSubmissionTimerIfNecessary];
    [self teardownNotificationObserving];
}

#pragma mark - Initialization
- (void) updateWithApplicationKey:(NSString *)applicationKey
                      accessToken:(NSString *)accessToken
                    configuration:(TMLConfiguration *)configuration
{
    self.applicationKey = applicationKey;
    self.accessToken = accessToken;
    if (configuration != nil) {
        self.configuration = configuration;
    }
    else {
        configuration = self.configuration;
    }
    TMLAPIClient *apiClient = [[TMLAPIClient alloc] initWithURL:configuration.apiURL
                                                    accessToken:accessToken];
    self.apiClient = apiClient;
    
    [self initTranslationBundle:^(TMLBundle *bundle) {
        if (bundle == nil) {
            TMLError(@"Failed to initialize translation bundle");
        }
        else {
            if (self.translationEnabled == NO) {
                self.currentBundle = bundle;
            }
        }
    }];
    
    if (self.translationEnabled == YES) {
        TMLAPIBundle *apiBundle = (TMLAPIBundle *)[TMLBundle apiBundle];
        self.currentBundle = apiBundle;
        [apiBundle sync];
    }
}

#pragma mark - Notifications

- (void) setupNotificationObserving {
    if (_observingNotifications == YES) {
        return;
    }
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self selector:@selector(bundleSyncDidFinish:)
                               name:TMLBundleSyncDidFinishNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(bundleDidInstall:)
                               name:TMLBundleInstallationDidFinishNotification
                             object:nil];
    _observingNotifications = YES;
}

- (void) teardownNotificationObserving {
    if (_observingNotifications == NO) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _observingNotifications = NO;
}

- (void) applicationDidBecomeActive:(NSNotification *)aNotification {
    TMLBundle *currentBundle = self.currentBundle;
    if ([currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        [(TMLAPIBundle *)currentBundle setNeedsSync];
    }
    else {
        [self checkForBundleUpdate:YES completion:^(NSString *version, NSString *path, NSError *error) {
            if (error == nil
                && self.translationEnabled == NO) {
                self.currentBundle = [TMLBundle mainBundle];
            }
        }];
    }
}

#pragma mark - Bundles

- (void) updateWithBundle:(TMLBundle *)bundle {
    if (bundle == nil) {
        return;
    }
    TMLApplication *newApplication = [bundle application];
    TMLInfo(@"Initializing from local bundle: %@", bundle.version);
    self.application = newApplication;
    NSString *ourLocale = self.currentLanguage.locale;
    if (ourLocale != nil && [bundle.availableLocales containsObject:ourLocale] == NO) {
        [bundle loadTranslationsForLocale:ourLocale completion:^(NSError *error) {
            if (error != nil) {
                TMLError(@"Could not preload current locale '%@' into newly selected bundle: %@", ourLocale, error);
            }
        }];
    }
}

- (void)setCurrentBundle:(TMLBundle *)currentBundle {
    if (_currentBundle == currentBundle) {
        return;
    }
    _currentBundle = currentBundle;
    if (currentBundle != nil) {
        [self updateWithBundle:currentBundle];
    }
    if ([currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        [(TMLAPIBundle *)currentBundle sync];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TMLBundleDidChangeNotification object:nil];
}

- (void) initTranslationBundle:(void(^)(TMLBundle *bundle))completion {
    // Check if there's a main bundle already set up
    TMLBundle *bundle = [TMLBundle mainBundle];

    // Check if we have a locally availale archive
    // use it if we have no main bundle, or archived version supersedes
    NSString *archivePath = [self latestLocalBundleArchivePath];
    NSString *archivedVersion = [archivePath tmlTranslationBundleVersionFromPath];
    BOOL hasNewerArchive = NO;
    if (archivedVersion != nil) {
        hasNewerArchive = [archivedVersion compareToTMLTranslationBundleVersion:bundle.version] == NSOrderedAscending;
    }
    
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    
    // Install archived bundle if we got one
    if (hasNewerArchive == YES) {
        __block TMLBundle *latestArchivedBundle = nil;
        [bundleManager installBundleFromPath:archivePath completionBlock:^(NSString *path, NSError *error) {
            if (path != nil && error == nil) {
                latestArchivedBundle = [[TMLBundle alloc] initWithContentsOfDirectory:path];
            }
            if (completion != nil) {
                completion(latestArchivedBundle);
            }
        }];
        return;
    }
    // Otherwise, if we got nothing at all, look up on CDN
    else if (bundle == nil) {
        [bundleManager fetchPublishedBundleInfo:^(NSDictionary *info, NSError *error) {
            NSString *publishedVersion = info[TMLBundleManagerVersionKey];
            if (publishedVersion != nil) {
                NSMutableArray *locales = [NSMutableArray array];
                NSString *defaultLocale = self.defaultLanguage.locale;
                NSString *currentLocale = self.currentLanguage.locale;
                if (defaultLocale != nil) {
                    [locales addObject:defaultLocale];
                }
                if (currentLocale != nil && [locales containsObject:currentLocale] == NO) {
                    [locales addObject:currentLocale];
                }
                [bundleManager installPublishedBundleWithVersion:publishedVersion
                                                         locales:locales
                                                 completionBlock:^(NSString *path, NSError *error) {
                                                     TMLBundle *newBundle = nil;
                                                     if (path != nil && error == nil) {
                                                         newBundle = [[TMLBundle alloc] initWithContentsOfDirectory:path];
                                                     }
                                                     if (completion != nil) {
                                                         completion(newBundle);
                                                     }
                                                 }];
            }
        }];
        return;
    }
    if (completion != nil) {
        completion(bundle);
    }
}

- (NSArray *) findLocalBundleArchives {
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

- (NSString *) latestLocalBundleArchivePath {
    NSArray *localBundleZipFiles = [self findLocalBundleArchives];
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

- (void) checkForBundleUpdate:(BOOL)install
                   completion:(void(^)(NSString *version, NSString *path, NSError *error))completion
{
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    [bundleManager fetchPublishedBundleInfo:^(NSDictionary *info, NSError *error) {
        NSString *version = info[TMLBundleVersionKey];
        TMLBundle *mainBundle = [TMLBundle mainBundle];
        if (version == nil) {
            return;
        }
        if (mainBundle == nil
            || [mainBundle.version compareToTMLTranslationBundleVersion:version] == NSOrderedAscending) {
            if (install == YES) {
                NSString *defaultLocale = self.defaultLanguage.locale;
                NSString *currentLocale = self.currentLanguage.locale;
                NSMutableArray *localesToFetch = [NSMutableArray array];
                if (defaultLocale != nil) {
                    [localesToFetch addObject:defaultLocale];
                }
                if (currentLocale != nil) {
                    [localesToFetch addObject:currentLocale];
                }
                [bundleManager installPublishedBundleWithVersion:version
                                                         locales:localesToFetch
                                                 completionBlock:^(NSString *path, NSError *error) {
                                                     if (completion != nil) {
                                                         completion(version, path, error);
                                                     }
                                                 }];
            }
            else {
                if (completion != nil) {
                    completion(version, nil, nil);
                }
            }
        }
    }];
}

#pragma mark - Bundle Notifications

- (void)bundleSyncDidFinish:(NSNotification *)aNotification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *userInfo = aNotification.userInfo;
    TMLBundle *bundle = userInfo[TMLBundleChangeInfoBundleKey];
    if (bundle != nil) {
        [self updateWithBundle:bundle];
    }
}

- (void) bundleDidInstall:(NSNotification *)aNotification {
    if (self.translationEnabled == NO) {
        TMLBundle *newBundle = aNotification.userInfo[TMLBundleChangeInfoBundleKey];
        if (newBundle != nil) {
            self.currentBundle = newBundle;
        }
    }
}

#pragma mark - Application

- (void)setApplication:(TMLApplication *)application {
    if (_application == application) {
        return;
    }
    _application = application;
    if (application != nil) {
        TMLConfiguration *configuration = self.configuration;
        self.postOffice = [[TMLPostOffice alloc] initWithApplication:application];
        self.defaultLanguage = [application languageForLocale: configuration.defaultLocale];
        self.currentLanguage = [application languageForLocale: configuration.currentLocale];
    }
}

#pragma mark - Translating

+ (NSString *)translate:(NSString *)label
        withDescription:(NSString *)description
              andTokens:(NSDictionary *)tokens
             andOptions:(NSDictionary *)options
{
    NSMutableDictionary *opts = nil;
    if (options != nil) {
        opts = [NSMutableDictionary dictionaryWithDictionary:options];
    }
    else {
        opts = [NSMutableDictionary dictionary];
    }
    opts[@"tokenizer"] = @"html";
    return (NSString *) [[self sharedInstance] translate:label
                                         withDescription:description
                                               andTokens:tokens
                                              andOptions:opts];
}

+ (NSAttributedString *)translateAttributedString:(NSString *)attributedString
                                  withDescription:(NSString *)description
                                        andTokens:(NSDictionary *)tokens
                                       andOptions:(NSDictionary *)options
{
    NSMutableDictionary *opts = nil;
    if (options != nil) {
        opts = [NSMutableDictionary dictionaryWithDictionary:options];
    }
    else {
        opts = [NSMutableDictionary dictionary];
    }
    opts[@"tokenizer"] = @"attributed";
    return (NSAttributedString *) [[self sharedInstance] translate:attributedString
                                                   withDescription:description
                                                         andTokens:tokens
                                                        andOptions:opts];
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

#pragma mark - Configuration

+ (void) configure:(void (^)(TMLConfiguration *config)) changes {
    changes([TML configuration]);
}

+ (TMLConfiguration *) configuration {
    return [[TML sharedInstance] configuration];
}

- (void)setTranslationEnabled:(BOOL)translationEnabled {
    if (_translationEnabled == translationEnabled) {
        return;
    }
    _translationEnabled = translationEnabled;
    TMLBundle *newBundle = nil;
    if (translationEnabled == YES) {
        newBundle = [TMLBundle apiBundle];
    }
    else {
        newBundle = [TMLBundle mainBundle];
    }
    self.currentBundle = newBundle;
}

#pragma mark - Block Options

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

#pragma mark - Class Methods

+ (TMLApplication *) application {
    return [[TML sharedInstance] application];
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

#pragma mark - Locales

- (void) changeLocale:(NSString *)locale
      completionBlock:(void(^)(BOOL success))completionBlock
{
    void(^finalize)(BOOL) = ^(BOOL success) {
        if (success == YES) {
            [self _changeToLocale:locale];
        }
        if (completionBlock != nil) {
            completionBlock(success);
        }
    };
    TMLBundle *ourBundle = self.currentBundle;
    if ([ourBundle translationsForLocale:locale] == nil) {
        [ourBundle loadTranslationsForLocale:locale completion:^(NSError *error) {
            TMLLanguage *newLanguage;
            if (error == nil) {
                newLanguage = [self.application languageForLocale:locale];
            }
            BOOL success = NO;
            if (newLanguage != nil) {
                id<TMLDelegate>delegate = self.delegate;
                if ([delegate respondsToSelector:@selector(tmlDidLoadTranslations)] == YES) {
                    [delegate tmlDidLoadTranslations];
                }
                success = YES;
            }
            finalize(success);
        }];
    }
    else {
        finalize(YES);
    }
}

- (void)_changeToLocale:(NSString *)locale {
    TMLLanguage *newLanguage = [self.application languageForLocale:locale];
    if (newLanguage == nil) {
        return;
    }
    // TODO: do we really need toi change both ourselves and config?
    NSString *oldLocale = self.configuration.currentLocale;
    self.currentLanguage = newLanguage;
    self.configuration.currentLocale = newLanguage.locale;
    [self didChangeFromLocale:oldLocale];
}

- (void)didChangeFromLocale:(NSString *)previousLocale {
    NSDictionary *info = @{
                           TMLLanguagePreviousLocaleUserInfoKey: previousLocale
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:TMLLanguageChangedNotification
                                                        object:nil
                                                      userInfo:info];
}

#pragma mark - Translations

- (NSArray *) translationsForKey:(NSString *)translationKey locale:(NSString *)locale {
    NSDictionary *translations = [self.currentBundle translationsForLocale:locale];
    return translations[translationKey];
}

- (BOOL)isTranslationKeyRegistered:(NSString *)translationKey {
    NSArray *results = [self translationsForKey:translationKey locale:self.currentLanguage.locale];
    return results != nil;
}

+ (void) reloadTranslations {
    [[TML sharedInstance] reloadTranslations];
}

- (void) reloadTranslations {
    TMLBundle *ourBundle = self.currentBundle;
    if ([ourBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        [(TMLAPIBundle *)ourBundle setNeedsSync];
    }
}

- (NSObject *)translate:(NSString *)label
        withDescription:(NSString *)description
              andTokens:(NSDictionary *)tokens
             andOptions:(NSDictionary *)options
{
    // if TML is used in a disconnected mode or has not been initialized, fallback onto English US
    if (self.currentLanguage == nil) {
        self.defaultLanguage = [TMLLanguage defaultLanguage];
        self.currentLanguage = self.defaultLanguage;
    }
    id result = [self.currentLanguage translate:label
                                withDescription:description
                                      andTokens:tokens
                                     andOptions:options];
    return (result == nil) ? label : result;
}

#pragma mark - Utility Methods

- (NSString *) callerClass {
    NSArray *stack = [NSThread callStackSymbols];
    NSString *caller = [[[stack objectAtIndex:2] componentsSeparatedByString:@"["] objectAtIndex:1];
    caller = [[caller componentsSeparatedByString:@" "] objectAtIndex:0];
    TMLDebug(@"caller: %@", stack);
    return caller;
}

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

- (void) registerMissingTranslationKey: (TMLTranslationKey *) translationKey {
    [self registerMissingTranslationKey:translationKey forSourceKey:nil];
}

- (void) registerMissingTranslationKey:(TMLTranslationKey *)translationKey
                          forSourceKey:(NSString *)sourceKey
{
    if (translationKey.label.length == 0) {
        TMLWarn(@"Tried to register missing translation for translationKey with empty label");
        return;
    }
    
    TMLBundle *currentBundle = self.currentBundle;
    if ([currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        [(TMLAPIBundle *)currentBundle addTranslationKey:translationKey forSource:sourceKey];
    }
}

- (void) submitMissingTranslationKeys {
    if (self.missingTranslationKeysBySources == nil
        || [self.missingTranslationKeysBySources count] == 0) {
        [self stopSubmissionTimerIfNecessary];
        return;
    }
    
    TMLInfo(@"Submitting missing translations...");
    
    NSMutableDictionary *missingTranslations = self.missingTranslationKeysBySources;
    [[[TML sharedInstance] apiClient] registerTranslationKeysBySourceKey:missingTranslations
                                                         completionBlock:^(BOOL success, NSError *error) {
                                                             //                                           if (success == YES && missingTranslations.count > 0) {
                                                             //                                               NSMutableDictionary *existingSources = [NSMutableDictionary dictionary];
                                                             //                                               for (TMLSource *source in existingSources) {
                                                             //                                                   existingSources[source.key] = source;
                                                             //                                               }
                                                             //                                               for (NSString *sourceKey in missingTranslations) {
                                                             //                                                   [existingSources removeObjectForKey:sourceKey];
                                                             //                                               }
                                                             //                                               self.sources = [existingSources allValues];
                                                             //                                           }
                                                         }];
    
    [missingTranslations removeAllObjects];
}

#pragma mark - Timer
- (void)startSubmissionTimerIfNecessary {
    if (_translationSubmissionTimer != nil) {
        return;
    }
    _translationSubmissionTimer = [NSTimer timerWithTimeInterval:3.
                                     target:self
                                   selector:@selector(submitMissingTranslationKeys)
                                   userInfo:nil
                                    repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_translationSubmissionTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopSubmissionTimerIfNecessary {
    if (_translationSubmissionTimer != nil) {
        [_translationSubmissionTimer invalidate];
        _translationSubmissionTimer = nil;
    }
}

@end
