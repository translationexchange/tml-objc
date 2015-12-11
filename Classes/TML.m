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


#import "NSObject+TML.h"
#import "NSString+TML.h"
#import "TML.h"
#import "TMLAPIBundle.h"
#import "TMLAPIClient.h"
#import "TMLApplication.h"
#import "TMLBundleManager.h"
#import "TMLDataToken.h"
#import "TMLLanguage.h"
#import "TMLLanguageCase.h"
#import "TMLLogger.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationActivationView.h"
#import "TMLTranslationKey.h"
#import "TMLTranslatorViewController.h"
#import "UIResponder+TML.h"
#import "UIView+TML.h"


/**
 *  Returns localized version of the string argument.
 *  The first argument is a dictionary of options, normally passed in by macros.
 *  The second argument is expected to have TML string that needs to be localized,
 *  and the rest of the arguments can be: tokens, restoration key, user options, or description.
 *
 *  The order is only relevant with respect to data types - that is, tokens (NSDictionary)
 *  will be processed before user options (NSDictionary), and restoration key (NSString) before description (NSString).
 *
 *  In the event only a single secondary NSString argument is provided - a check is made to see if options contain
 *  sender object and if that sender responds to the keyPath indicated in that string. If so - it's used as a restoration
 *  key path, otherwise - as a description.
 *  
 *  In the event user options are given among varargs, options and user options will be merged, with user options
 *  overriding values in options, but only after this method has parsed out key information from options.
 *
 *  @param options NSDictionary of options
 *  @param string  TML string
 *  @param ...     NSDictionary *tokens, NSString *restorationKeyPath, NSString *description, NDictionary *userOptions
 *
 *  @return Localized NSString or NSAttributedString, depending on token format given in options. 
 *  If options do not specify token format - NSString is returned.
 */
id TMLLocalize(NSDictionary *options, NSString *string, ...) {
    NSDictionary *tokens;
    NSString *keyPath;
    NSString *description;
    NSDictionary *userOpts;
    
    va_list args;
    va_start(args, string);
    id arg;
    while ((arg = va_arg(args, id))) {
        if ([arg isKindOfClass:[NSDictionary class]] == YES) {
            if (!tokens) {
                tokens = arg;
            }
            else if (!userOpts) {
                userOpts = arg;
            }
        }
        else if ([arg isKindOfClass:[NSString class]] == YES) {
            if (!keyPath) {
                keyPath = arg;
            }
            else if (!description) {
                description = arg;
            }
        }
    }
    va_end(args);
    
    NSMutableDictionary *ourOpts = [options mutableCopy];
    if (ourOpts == nil) {
        ourOpts = [NSMutableDictionary dictionary];
    }
    
    NSString *decorationFormat = options[TMLTokenFormatOptionName];
    if (keyPath && !description) {
        id sender = ourOpts[TMLSenderOptionName];
        id test;
        @try {
            test = [sender valueForKeyPath:keyPath];
        }
        @catch (NSException *exception) {
            description = keyPath;
            keyPath = description;
        }
    }
    
    if (keyPath != nil) {
        ourOpts[TMLRestorationKeyOptionName] = keyPath;
    }
    
    if (userOpts != nil) {
        [ourOpts addEntriesFromDictionary:userOpts];
    }
    
    if ([decorationFormat isEqualToString:TMLAttributedTokenFormatString] == YES) {
        return [TML localizeAttributedString:string
                                 description:description
                                      tokens:tokens
                                     options:[ourOpts copy]];
    }
    else {
        return [TML localizeString:string
                       description:description
                            tokens:tokens
                           options:[ourOpts copy]];
    }
}

id TMLLocalizeDate(NSDictionary *options, NSDate *date, NSString *format, ...) {
    NSString *keyPath;
    NSString *description;
    
    va_list args;
    va_start(args, format);
    id arg;
    while ((arg = va_arg(args, id))) {
        if (!description && [arg isKindOfClass:[NSString class]] == YES) {
            description = arg;
        }
        else if (description && !keyPath && [arg isKindOfClass:[NSString class]] == YES) {
            keyPath = description;
            description = arg;
        }
    }
    va_end(args);
    
    if (description && !keyPath) {
        keyPath = description;
    }
    
    NSMutableDictionary *ourOpts = [options mutableCopy];
    if (ourOpts == nil) {
        ourOpts = [NSMutableDictionary dictionary];
    }
    
    if (keyPath != nil) {
        ourOpts[TMLRestorationKeyOptionName] = keyPath;
    }
    
    NSString *dateFormat = format;
    NSString *configFormat = [[[TML sharedInstance] configuration] customDateFormatForKey:format];
    if (configFormat != nil) {
        dateFormat = configFormat;
    }
    
    NSString *decorationFormat = options[TMLTokenFormatOptionName];
    if ([decorationFormat isEqualToString:TMLAttributedTokenFormatString] == YES) {
        return [TML localizeAttributedDate:date
                                withFormat:dateFormat
                               description:description
                                   options:[ourOpts copy]];
    }
    else {
        return [TML localizeDate:date
                      withFormat:dateFormat
                     description:description
                         options:[ourOpts copy]];
    }
}


@interface TML()<UIGestureRecognizerDelegate> {
    BOOL _observingNotifications;
    BOOL _checkingForBundleUpdate;
    NSDate *_lastBundleUpdateDate;
    UIGestureRecognizer *_translationActivationGestureRecognizer;
    UIGestureRecognizer *_inlineTranslationGestureRecognizer;
    TMLTranslationActivationView *_translationActivationView;
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

- (instancetype)init {
    return [self initWithConfiguration:nil];
}

- (instancetype) initWithConfiguration:(TMLConfiguration *)configuration {
    if (self == [super init]) {
        if (configuration == nil) {
            configuration = [[TMLConfiguration alloc] init];
        }
        self.configuration = configuration;
        
        if (configuration.accessToken != nil) {
            TMLAPIClient *apiClient = [[TMLAPIClient alloc] initWithURL:configuration.apiURL
                                                            accessToken:configuration.accessToken];
            self.apiClient = apiClient;
        }
        
        [self setupNotificationObserving];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initTranslationBundle:^(TMLBundle *bundle) {
                if (bundle == nil) {
                    TMLWarn(@"No local translation bundle found...");
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
            
        });
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
        if ([self shouldCheckForBundleUpdate] == YES) {
            [self checkForBundleUpdate:YES completion:^(NSString *version, NSString *path, NSError *error) {
                if (version != nil && self.translationEnabled == NO) {
                    TMLBundle *newBundle = [TMLBundle bundleWithVersion:version];
                    if ([newBundle isEqualToBundle:self.currentBundle] == NO) {
                        self.currentBundle = newBundle;
                    }
                }
            }];
        }
    }
    [self setupTranslationActivationGestureRecognizer];
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
        if (ourLocale != nil) {
            [bundle loadTranslationsForLocale:ourLocale completion:^(NSError *error) {
                if (error != nil) {
                    TMLError(@"Could not preload current locale '%@' into newly selected bundle: %@", ourLocale, error);
                }
                else {
                    [self restoreTMLLocalizations];
                }
            }];
        }
    }
    if ([self.application isInlineTranslationsEnabled] == NO) {
        self.configuration.translationEnabled = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TMLLocalizationDataChangedNotification object:nil];
}

- (void)setCurrentBundle:(TMLBundle *)currentBundle {
    if (_currentBundle == currentBundle) {
        return;
    }
    _currentBundle = currentBundle;
    [self updateWithBundle:currentBundle];
    if ([currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        TMLAPIBundle *apiBundle = (TMLAPIBundle *)currentBundle;
        apiBundle.syncEnabled = YES;
        [apiBundle setNeedsSync];
    }
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

- (BOOL)shouldCheckForBundleUpdate {
    if (_checkingForBundleUpdate == YES) {
        return NO;
    }
    if (_lastBundleUpdateDate != nil) {
        NSTimeInterval sinceLastUpdate = [[NSDate date] timeIntervalSinceDate:_lastBundleUpdateDate];
        return (sinceLastUpdate > 60);
    }
    return YES;
}

/**
 *  Checks CDN for the current version info, and calls completion block when finishes.
 *
 *  The arguments passed to the completion block indicates several possible outcomes:
 *
 *     - The version argument indicates version found on CDN
 *
 *     - The path argument would indicate that a bundle was installed to that path.
 *       If path is nil - that means no installation took place - that could mean - bundle with given version is already installed.
 *
 *     - Error will indicate there was an error anywhere in the process - either fetching the version info, 
 *       or installing the new bundle.
 *
 *  @param install    Whether to install a bundle from CDN, if we don't have that version installed locally, that is...
 *  @param completion Completion block
 */
- (void) checkForBundleUpdate:(BOOL)install
                   completion:(void(^)(NSString *version, NSString *path, NSError *error))completion
{
    _checkingForBundleUpdate = YES;
    
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    void(^finalize)(NSString *, NSString *, NSError *) = ^(NSString *aVersion, NSString *aPath, NSError *anError){
        dispatch_async(dispatch_get_main_queue(), ^{
            _checkingForBundleUpdate = NO;
            _lastBundleUpdateDate = [NSDate date];
            if (completion != nil) {
                completion(aVersion, aPath, anError);
            }
        });
    };
    
    [bundleManager fetchPublishedBundleInfo:^(NSDictionary *info, NSError *error) {
        NSString *version = info[TMLBundleVersionKey];
        if (version == nil) {
            NSError *error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                                 code:TMLBundleManagerInvalidData
                                             userInfo:nil];
            finalize(version, nil, error);
            return;
        }
        
        TMLBundle *existingBundle = [TMLBundle bundleWithVersion:version];
        
        if (install == YES) {
            if (existingBundle != nil && [existingBundle isValid] == YES) {
                bundleManager.latestBundle = existingBundle;
                finalize(version, nil, nil);
            }
            else {
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
                                                     finalize(version, path, error);
                                                 }];
            }
        }
        else {
            finalize(version, nil, nil);
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
                    options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeDate:date
                                    withFormat:format
                                   description:description
                                       options:options];
}

+ (NSAttributedString *)localizeAttributedDate:(NSDate *)date
                                    withFormat:(NSString *)format
                                   description:(NSString *)description
                                       options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeAttributedDate:date
                                              withFormat:format
                                             description:description
                                                 options:options];
}

+ (NSString *) localizeDate:(NSDate *)date
             withFormatName:(NSString *)formatName
                description:(NSString *)description
                    options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeDate:date
                                withFormatName:formatName
                                   description:description
                                       options:options];
}

+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description
                                        options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeAttributedDate:date
                                          withFormatName:formatName
                                             description:description
                                                 options:options];
}

+ (NSString *) localizeDate:(NSDate *)date
        withTokenizedFormat:(NSString *)tokenizedFormat
             description:(NSString *)description
                    options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeDate:date
                           withTokenizedFormat:tokenizedFormat
                                   description:description
                                       options:options];
}

+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                            withTokenizedFormat:(NSString *)tokenizedFormat
                                 description:(NSString *)description
                                        options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeAttributedDate:date
                                     withTokenizedFormat:tokenizedFormat
                                             description:description
                                                 options:options];
}

- (NSString *)localizeString:(NSString *)string
                 description:(NSString *)description
                      tokens:(NSDictionary *)tokens
                     options:(NSDictionary *)options
{
    id result = [[self currentLanguage] translate:string
                                      description:description
                                           tokens:tokens
                                          options:options];
    
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
                                          options:opts];
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
                    options:(NSDictionary *)options
{
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    return [self localizeString:tokenizedFormat
                    description:description
                         tokens:tokens
                        options:options];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                            withTokenizedFormat:(NSString *)tokenizedFormat
                                    description:(NSString *)description
                                        options:(NSDictionary *)options
{
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    return [self localizeAttributedString:tokenizedFormat
                              description:description
                                   tokens:tokens
                                  options:options];
}

- (NSString *) localizeDate:(NSDate *)date
              withFormatName:(NSString *)formatName
                description:(NSString *)description
                    options:(NSDictionary *)options
{
    NSString *format = [[self configuration] customDateFormatForKey: formatName];
    if (!format) return formatName;
    return [self localizeDate:date
                   withFormat:format
                  description:description
                      options:options];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description
                                        options:(NSDictionary *)options
{
    NSString *format = [[self configuration] customDateFormatForKey: formatName];
    if (!format) return [[NSAttributedString alloc] initWithString:formatName attributes:nil];
    return [self localizeAttributedDate:date
                             withFormat:format
                            description:description
                                options:options];
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
                    options:(NSDictionary *)options
{
    NSDictionary *tokens = nil;
    NSString *tokenizedFormat = [self tokenizedDateFormatFromString:format
                                                           withDate:date
                                                             tokens:&tokens];
    return [self localizeString:tokenizedFormat
                    description:description
                         tokens:tokens
                        options:options];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                     withFormat:(NSString *)format
                                    description:(NSString *)description
                                        options:(NSDictionary *)options
{
    NSDictionary *tokens = nil;
    NSString *tokenizedFormat = [self tokenizedDateFormatFromString:format
                                                           withDate:date
                                                             tokens:&tokens];
    return [self localizeAttributedString:tokenizedFormat
                              description:description
                                   tokens:tokens
                                  options:options];
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
    
    TMLAPIBundle *apiBundle = (TMLAPIBundle *)[TMLBundle apiBundle];
    [(TMLAPIBundle *)apiBundle addTranslationKey:translationKey forSource:sourceKey];
}

#pragma mark - Configuration

+ (void) configure:(void (^)(TMLConfiguration *config)) changes {
    changes([TML configuration]);
}

+ (TMLConfiguration *) configuration {
    return [[TML sharedInstance] configuration];
}

#pragma mark - In-App Translations

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
    if (translationEnabled == YES) {
        [self setupInlineTranslationGestureRecognizer];
    }
    else {
        [self teardownInlineTranslationGestureRecognizer];
    }
}

- (BOOL)isInlineTranslationsEnabled {
    if (self.application == nil) {
        // application may start up w/o any project metadata (no release available locally or on CDN)
        // however, we could still try to comminicate with the API
        return YES;
    }
    return [self.application isInlineTranslationsEnabled];
}

#pragma mark - Gesture Recognizer

- (void) setupTranslationActivationGestureRecognizer {
    if (_translationActivationGestureRecognizer.view != nil) {
        return;
    }
    UIGestureRecognizer *gestureRecognizer = nil;
    id<TMLDelegate>delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(gestureRecognizerForTranslationActivation)] == YES) {
        gestureRecognizer = [delegate gestureRecognizerForTranslationActivation];
    }
    if (gestureRecognizer == nil) {
        gestureRecognizer = [self defaultGestureRecognizerForTranslationActivation];
    }
    [gestureRecognizer addTarget:self action:@selector(translationActivationGestureRecognized:)];
    _translationActivationGestureRecognizer = gestureRecognizer;
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addGestureRecognizer:gestureRecognizer];
}

- (void) teardownTranslationActivationGestureRecognizer {
    if (_translationActivationGestureRecognizer.view == nil) {
        return;
    }
    [_translationActivationGestureRecognizer.view removeGestureRecognizer:_translationActivationGestureRecognizer];
    _translationActivationGestureRecognizer = nil;
}

- (void) setupInlineTranslationGestureRecognizer {
    if (_inlineTranslationGestureRecognizer.view != nil) {
        return;
    }
    id<TMLDelegate>delegate = self.delegate;
    UIGestureRecognizer *recognizer = nil;
    if ([delegate respondsToSelector:@selector(gestureRecognizerForInlineTranslation)] == YES) {
        recognizer = [[delegate gestureRecognizerForInlineTranslation] copy];
    }
    // default recognizer
    if (recognizer == nil) {
        recognizer = [self defaultGestureRecognizerForInlineTranslation];
    }
    [recognizer addTarget:self action:@selector(inlineTranslationGestureRecognized:)];
    recognizer.delegate = self;
    _inlineTranslationGestureRecognizer = recognizer;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addGestureRecognizer:recognizer];
}

- (void)teardownInlineTranslationGestureRecognizer {
    if (_inlineTranslationGestureRecognizer.view == nil) {
        return;
    }
    [_inlineTranslationGestureRecognizer.view removeGestureRecognizer:_inlineTranslationGestureRecognizer];
    _inlineTranslationGestureRecognizer = nil;
}

- (UIGestureRecognizer *)defaultGestureRecognizerForTranslationActivation {
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] init];
    [recognizer addTarget:self action:@selector(inlineTranslationGestureRecognized:)];
    recognizer.numberOfTouchesRequired = 4;
    return recognizer;
}

- (UIGestureRecognizer *)defaultGestureRecognizerForInlineTranslation {
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] init];
    recognizer.numberOfTouchesRequired = 1;
    return recognizer;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _inlineTranslationGestureRecognizer) {
        return self.translationEnabled == YES;
    }
    return NO;
}

- (void)translationActivationGestureRecognized:(UIGestureRecognizer *)gestureRecognizer {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    BOOL translationEnabled = self.translationEnabled;
    UIColor *backgroundColor = nil;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (_translationActivationView == nil) {
            _translationActivationView = [[TMLTranslationActivationView alloc] initWithFrame:window.bounds];
        }
        
        if (translationEnabled) {
            backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.77];
        }
        else {
            backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.77];
        }
        _translationActivationView.backgroundColor = [UIColor clearColor];
        [UIView animateWithDuration:0.13 animations:^{
            _translationActivationView.backgroundColor = backgroundColor;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.13 animations:^{
                _translationActivationView.backgroundColor = [UIColor clearColor];
            } completion:^(BOOL finished) {
                [_translationActivationView removeFromSuperview];
            }];
        }];
        
        if (_translationActivationView.superview == nil) {
            [window addSubview:_translationActivationView];
        }
        self.translationEnabled = !self.translationEnabled;
    }
}

- (void)inlineTranslationGestureRecognized:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    UIView *view = gestureRecognizer.view;
    CGPoint location = [gestureRecognizer locationInView:view];
    __block UIView *hitView = [view hitTest:location withEvent:nil];
    __block NSArray *translationKeys = [hitView tmlTranslationKeys];
    if (translationKeys.count == 0) {
        [hitView tmlIterateSubviewsWithBlock:^(UIView *view, BOOL *skip, BOOL *stop) {
            CGPoint location = [gestureRecognizer locationInView:view];
            if (CGRectContainsPoint(view.bounds, location) == NO) {
                *skip = YES;
            }
            else {
                translationKeys = [view tmlTranslationKeys];
                if (translationKeys.count > 0) {
                    hitView = view;
                    *stop = YES;
                }
            }
        }];
    }
    
    if (translationKeys.count > 0) {
        TMLTranslationKey *translationKey = [translationKeys firstObject];
        TMLTranslatorViewController *translator = [[TMLTranslatorViewController alloc] initWithTranslationKey:translationKey.key];
        UINavigationController *wrapper = [[UINavigationController alloc] initWithRootViewController:translator];
        UIViewController *presenter = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [presenter presentViewController:wrapper animated:YES completion:nil];
    }
    else {
        TMLWarn(@"Could not find a string to localize");
    }
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
    [self restoreTMLLocalizations];
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

- (void)restoreTMLLocalizations {
    NSMutableSet *toRestore = [NSMutableSet set];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow != nil) {
        [toRestore addObject:keyWindow];
    }
    
    UIViewController *rootViewController = [keyWindow rootViewController];
    if (rootViewController != nil) {
        [toRestore addObject:rootViewController];
    }
    
    id firstResponder = [keyWindow tmlFindFirstResponder];
    if (firstResponder != nil) {
        [toRestore addObject:firstResponder];
    }
    
    for (id obj in toRestore) {
        if (obj == self) {
            continue;
        }
        [obj restoreTMLLocalizations];
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

- (void)removeLocalizationData {
    [[TMLBundleManager defaultManager] removeAllBundles];
    [self setCurrentBundle:nil];
}

@end
