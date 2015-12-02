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
#import "TMLAPIClient.h"
#import "TMLBundleManager.h"
#import "TMLDataToken.h"
#import "TMLLanguageCase.h"
#import "TMLLogger.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"
#import <CommonCrypto/CommonDigest.h>


@interface TML() {
    BOOL _observingNotifications;
}
@property(strong, nonatomic) TMLConfiguration *configuration;
@property(strong, nonatomic) TMLAPIClient *apiClient;
@property(nonatomic, readwrite) TMLBundle *currentBundle;
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
    TMLConfiguration *config = [[TMLConfiguration alloc] initWithApplicationKey:applicationKey
                                                                    accessToken:token];
    return [self sharedInstanceWithConfiguration:config];
}

+ (TML *) sharedInstanceWithConfiguration:(TMLConfiguration *)configuration {
    TML *tml = [self sharedInstance];
    tml = [tml initWithConfiguration:configuration];
    return tml;
}

#pragma mark - Class side accessors

+ (NSString *)applicationKey {
    return [[[self sharedInstance] configuration] applicationKey];
}

+ (TMLApplication *) application {
    return [[TML sharedInstance] application];
}


#pragma mark - Init

- (instancetype) initWithConfiguration:(TMLConfiguration *)configuration {
    if (self == [super init]) {
        if (configuration == nil) {
            self.configuration = [[TMLConfiguration alloc] init];
        }
        else {
            self.configuration = configuration;
        }
        
        if (configuration.accessToken != nil) {
            TMLAPIClient *apiClient = [[TMLAPIClient alloc] initWithURL:configuration.apiURL
                                                            accessToken:configuration.accessToken];
            self.apiClient = apiClient;
        }
        
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
        
        self.translationEnabled = configuration.translationEnabled;
        if (self.translationEnabled == YES) {
            TMLAPIBundle *apiBundle = (TMLAPIBundle *)[TMLBundle apiBundle];
            self.currentBundle = apiBundle;
            [apiBundle sync];
        }
        
        [self setupNotificationObserving];
    }
    return self;
}

- (void)dealloc {
    [self teardownNotificationObserving];
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
                               name:TMLDidFinishSyncNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(bundleDidInstall:)
                               name:TMLLocalizationUpdatesInstalledNotification
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
    // Special handling of nil bundles - this scenario would arise
    // when switching from API bundle to nothing - b/c no bundles are available
    // neither locally nor on CDN.
    if (bundle == nil) {
        TMLWarn(@"Setting current bundle not nil");
        self.application = nil;
    }
    else {
        TMLApplication *newApplication = [bundle application];
        TMLInfo(@"Initializing from local bundle: %@", bundle.version);
        self.application = newApplication;
        NSString *ourLocale = [self currentLocale];
        if (ourLocale != nil && [bundle.availableLocales containsObject:ourLocale] == NO) {
            [bundle loadTranslationsForLocale:ourLocale completion:^(NSError *error) {
                if (error != nil) {
                    TMLError(@"Could not preload current locale '%@' into newly selected bundle: %@", ourLocale, error);
                }
            }];
        }
    }
    if ([self.application isInlineTranslationsEnabled] == NO) {
        self.configuration.translationEnabled = NO;
    }
}

- (void)setCurrentBundle:(TMLBundle *)currentBundle {
    if (_currentBundle == currentBundle) {
        return;
    }
    _currentBundle = currentBundle;
    [self updateWithBundle:currentBundle];
    if ([currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        [(TMLAPIBundle *)currentBundle sync];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TMLLocalizationDataChangedNotification object:nil];
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
                NSString *defaultLocale = [self defaultLocale];
                NSString *currentLocale = [self currentLocale];
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
                NSString *defaultLocale = [self defaultLocale];
                NSString *currentLocale = [self currentLocale];
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
    self.configuration.defaultLocale = application.defaultLocale;
}

#pragma mark - Translating

+ (NSString *)localizeString:(NSString *)string
                 description:(NSString *)description
                      tokens:(NSDictionary *)tokens
                     options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeString:string
                                     description:description
                                          tokens:tokens
                                         options:options];
}

+ (NSAttributedString *)localizeAttributedString:(NSString *)attributedString
                                     description:(NSString *)description
                                          tokens:(NSDictionary *)tokens
                                         options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeAttributedString:attributedString
                                               description:description
                                                    tokens:tokens
                                                   options:options];
}

+ (NSString *) localizeDate:(NSDate *)date
                 withFormat:(NSString *)format
                description:(NSString *)description
{
    return [[self sharedInstance] localizeDate:date
                                    withFormat:format
                                   description:description];
}

+ (NSAttributedString *)localizeAttributedDate:(NSDate *)date
                                    withFormat:(NSString *)format
                                   description:(NSString *)description
{
    return [[self sharedInstance] localizeAttributedDate:date
                                              withFormat:format
                                             description:description];
}

+ (NSString *) localizeDate:(NSDate *)date
             withFormatName:(NSString *)formatName
                description:(NSString *)description
{
    return [[self sharedInstance] localizeDate:date
                                withFormatName:formatName
                                   description:description];
}

+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description
{
    return [[self sharedInstance] localizeAttributedDate:date
                                          withFormatName:formatName
                                             description:description];
}

+ (NSString *) localizeDate:(NSDate *)date
        withTokenizedFormat:(NSString *)tokenizedFormat
             description:(NSString *)description
{
    return [[self sharedInstance] localizeDate:date
                           withTokenizedFormat:tokenizedFormat
                                   description:description];
}

+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                            withTokenizedFormat:(NSString *)tokenizedFormat
                                 description:(NSString *)description
{
    return [[self sharedInstance] localizeAttributedDate:date
                                     withTokenizedFormat:tokenizedFormat
                                          description:description];
}

- (NSString *)localizeString:(NSString *)string
                 description:(NSString *)description
                      tokens:(NSDictionary *)tokens
                     options:(NSDictionary *)options
{
    NSMutableDictionary *opts = [NSMutableDictionary dictionary];
    if (opts != nil) {
        [opts addEntriesFromDictionary:options];
    }
    opts[TMLTokenFormatOptionName] = TMLHTMLTokenFormatString;
    id result = [[self currentLanguage] translate:string
                                      description:description
                                           tokens:tokens
                                          options:opts];
    if ([result isKindOfClass:[NSString class]] == YES) {
        return (NSString *)result;
    }
    else if ([result isKindOfClass:[NSAttributedString class]] == YES) {
        return [(NSAttributedString *)result string];
    }
    else {
        return string;
    }
}

- (NSAttributedString *)localizeAttributedString:(NSString *)string
                                     description:(NSString *)description
                                          tokens:(NSDictionary *)tokens
                                         options:(NSDictionary *)options
{
    NSMutableDictionary *opts = [NSMutableDictionary dictionary];
    if (opts != nil) {
        [opts addEntriesFromDictionary:options];
    }
    opts[TMLTokenFormatOptionName] = TMLAttributedTokenFormatString;
    id result = [[self currentLanguage] translate:string
                                      description:description
                                           tokens:tokens
                                          options:options];
    if ([result isKindOfClass:[NSAttributedString class]] == YES) {
        return (NSAttributedString *)result;
    }
    else if ([result isKindOfClass:[NSString class]] == YES) {
        return [[NSAttributedString alloc] initWithString:(NSString *)result attributes:nil];
    }
    else {
        return [[NSAttributedString alloc] initWithString:string attributes:nil];
    }
}

- (NSString *) localizeDate:(NSDate *)date
        withTokenizedFormat:(NSString *)tokenizedFormat
                description:(NSString *)description
{
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    return [self localizeString:tokenizedFormat
                    description:description
                         tokens:tokens
                        options:nil];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                            withTokenizedFormat:(NSString *)tokenizedFormat
                                    description: (NSString *)description
{
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    return [self localizeAttributedString:tokenizedFormat
                              description:description
                                   tokens:tokens
                                  options:nil];
}

- (NSString *) localizeDate:(NSDate *)date
              withFormatName:(NSString *)formatName
                description:(NSString *)description
{
    NSString *format = [[self configuration] customDateFormatForKey: formatName];
    if (!format) return formatName;
    return [self localizeDate:date
                   withFormat:format
                  description:description];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description
{
    NSString *format = [[self configuration] customDateFormatForKey: formatName];
    if (!format) return [[NSAttributedString alloc] initWithString:formatName attributes:nil];
    return [self localizeAttributedDate:date
                             withFormat:format
                            description:description];
}

- (NSString *)tokenizedDateFormatFromString:(NSString *)string
                                   withDate:(NSDate *)date
                                     tokens:(NSDictionary **)tokens
{
    NSError *error = NULL;
    NSRegularExpression *expression = [NSRegularExpression
                                       regularExpressionWithPattern: @"[\\w]*"
                                       options: NSRegularExpressionCaseInsensitive
                                       error: &error];
    
    NSString *tokenizedFormat = string;
    
    NSArray *matches = [expression matchesInString:string
                                           options:0
                                             range:NSMakeRange(0, string.length)];
    NSMutableArray *elements = [NSMutableArray array];
    
    int index = 0;
    for (NSTextCheckingResult *match in matches) {
        NSString *element = [string substringWithRange:[match range]];
        [elements addObject:element];
        NSString *placeholder = [NSString stringWithFormat: @"{%d}", index++];
        tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:element
                                                                     withString:placeholder];
    }
    
    NSMutableDictionary *ourTokens = [NSMutableDictionary dictionary];
    TMLConfiguration *configuration = [self configuration];
    for (index=0; index<[elements count]; index++) {
        NSString *element = [elements objectAtIndex:index];
        NSString *tokenName = [configuration dateTokenNameForKey: element];
        NSString *placeholder = [NSString stringWithFormat: @"{%d}", index];
        
        if (tokenName) {
            tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:placeholder
                                                                         withString:tokenName];
            [ourTokens setObject:[configuration dateValueForToken:tokenName inDate:date]
                          forKey:[tokenName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]]];
        } else
            tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:placeholder
                                                                         withString:element];
    }
    if (tokens != nil) {
        *tokens = [ourTokens copy];
    }
    return tokenizedFormat;
}

- (NSString *) localizeDate:(NSDate *)date
                 withFormat:(NSString *)format
                description:(NSString *)description
{
    NSDictionary *tokens = nil;
    NSString *tokenizedFormat = [self tokenizedDateFormatFromString:format
                                                           withDate:date
                                                             tokens:&tokens];
    return [self localizeString:tokenizedFormat
                    description:description
                         tokens:tokens
                        options:nil];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                     withFormat:(NSString *)format
                                    description:(NSString *)description
{
    NSDictionary *tokens = nil;
    NSString *tokenizedFormat = [self tokenizedDateFormatFromString:format
                                                           withDate:date
                                                             tokens:&tokens];
    return [self localizeAttributedString:tokenizedFormat
                              description:description
                                   tokens:tokens
                                  options:nil];
}

#pragma mark - Registering new translation keys

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
    self.configuration.translationEnabled = translationEnabled;
}

- (BOOL)isInlineTranslationsEnabled {
    if (self.application == nil) {
        // application may start up w/o any project metadata (no release available locally or on CDN)
        // however, we could still try to comminicate with the API
        return YES;
    }
    return [self.application isInlineTranslationsEnabled];
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

#pragma mark - Sources

+ (NSString *) currentSource {
    return [[self sharedInstance] currentSource];
}

- (void)setCurrentSource:(NSString *)currentSource {
    if (currentSource != nil) {
        [self beginBlockWithOptions:@{TMLSourceOptionName : currentSource}];
    }
}

- (NSString *)currentSource {
    NSString *source = (NSString *)[self blockOptionForKey:TMLSourceOptionName];
    if (source == nil) {
        source = [[TMLSource defaultSource] sourceName];
    }
    return source;
}

#pragma mark - Languages and Locales

+ (TMLLanguage *) defaultLanguage {
    return [[TML sharedInstance] defaultLanguage];
}

- (TMLLanguage *)defaultLanguage {
    return [[self application] languageForLocale:[self defaultLocale]];
}

+ (NSString *)defaultLocale {
    return [[TML sharedInstance] defaultLocale];
}

- (NSString *)defaultLocale {
    return self.configuration.defaultLocale;
}

+ (TMLLanguage *) currentLanguage {
    return [[TML sharedInstance] currentLanguage];
}

- (TMLLanguage *)currentLanguage {
    TMLLanguage *lang = [[self application] languageForLocale:[self currentLocale]];
    if (lang == nil) {
        lang = [TMLLanguage defaultLanguage];
    }
    return lang;
}

+ (NSString *)currentLocale {
    return [[TML sharedInstance] currentLocale];
}

- (NSString *)currentLocale {
    return self.configuration.currentLocale;
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
            BOOL success = newLanguage != nil;
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
    self.configuration.currentLocale = newLanguage.locale;
    [self didChangeFromLocale:oldLocale];
}

- (void)didChangeFromLocale:(NSString *)previousLocale {
    NSDictionary *info = @{
                           TMLPreviousLocaleUserInfoKey: previousLocale
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
    NSArray *results = [self translationsForKey:translationKey locale:[self currentLocale]];
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

- (BOOL) hasLocalTranslationsForLocale:(NSString *)locale {
    if (locale == nil) {
        return NO;
    }
    TMLBundle *bundle = self.currentBundle;
    return [bundle translationsForLocale:locale] != nil;
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

- (void) submitMissingTranslationKeys {
    if ([self.currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        TMLAPIBundle *bundle = (TMLAPIBundle *)self.currentBundle;
        [bundle sync];
    }
}

@end
