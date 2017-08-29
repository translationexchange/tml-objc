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


#import "NSObject+TMLJSON.h"
#import "NSString+TML.h"
#import "TML.h"
#import "TMLAPIResponse.h"
#import "TMLAPISerializer.h"
#import "TMLApplication.h"
#import "TMLBundle.h"
#import "TMLBundleManager.h"
#import "TMLLanguage.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"

NSString * const TMLBundleVersionFilename = @"snapshot.json";
NSString * const TMLBundleApplicationFilename = @"application.json";
NSString * const TMLBundleTranslatorFilename = @"translator.json";
NSString * const TMLBundleSourcesFilename = @"sources.json";
NSString * const TMLBundleTranslationsFilename = @"translations.json";
NSString * const TMLBundleTranslationKeysFilename = @"translation_keys.json";
NSString * const TMLBundleLanguageFilename = @"language.json";
NSString * const TMLBundleSourcesRelativePath = @"sources";

NSString * const TMLBundleVersionKey = @"version";
NSString * const TMLBundleURLKey = @"url";
NSString * const TMLBundleBaseURLKey = @"cdn_url";

NSString * const TMLBundleErrorDomain = @"TMLBundleErrorDomain";
NSString * const TMLBundleErrorResourcePathKey = @"resourcePath";
NSString * const TMLBundleErrorsKey = @"errors";

@interface TMLBundle()
@property (readwrite, nonatomic) NSString *version;
@property (readwrite, nonatomic) NSString *path;
@property (readwrite, nonatomic) NSArray *languages;
@property (readwrite, nonatomic) NSMutableDictionary *translations;
@property (readwrite, nonatomic) NSArray *availableLocales;
@property (readwrite, nonatomic) NSMutableDictionary *availableLanguages;
@property (readwrite, nonatomic) NSArray *locales;
@property (readwrite, nonatomic) TMLApplication *application;
@property (readwrite, nonatomic) NSArray *sources;
@property (readwrite, nonatomic) NSDictionary *translationKeys;
@property (readwrite, nonatomic) NSURL *sourceURL;
@property (readwrite, nonatomic) NSURL *baseURL;
@end

@implementation TMLBundle

- (instancetype)initWithContentsOfDirectory:(NSString *)path {
    if (self = [super init]) {
        self.path = path;
        
        TMLDebug(@"Bundle root path: %@", self.path);
        
        _translations = [NSMutableDictionary dictionary];
        _availableLanguages = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    else if ([object isKindOfClass:[TMLBundle class]] == NO) {
        return NO;
    }
    return [self isEqualToBundle:object];
}

- (BOOL)isEqualToBundle:(TMLBundle *)bundle {
    return [self.version isEqualToString:bundle.version] && [self.path isEqualToString:bundle.path];
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@%@", self.version, self.path] hash];
}

- (BOOL)isMutable {
    return NO;
}

- (void)resetData {
    self.languages = nil;
    self.sources = nil;
    self.application = nil;
    self.version = nil;
    self.sourceURL = nil;
    self.baseURL = nil;
    self.availableLocales = nil;
    self.translationKeys = nil;
    self.translations = nil;
}

- (void)reloadVersionInfo {
    NSString *path = [self.path stringByAppendingPathComponent:TMLBundleVersionFilename];
    NSData *versionData = [NSData dataWithContentsOfFile:path];
    NSDictionary *versionInfo = [versionData tmlJSONObject];
    if (versionInfo == nil) {
        TMLWarn(@"Cannot find bundle version at path: %@", path);
        return;
    }
    self.version = versionInfo[TMLBundleVersionKey];
    self.sourceURL = [NSURL URLWithString:versionInfo[TMLBundleURLKey]];
    self.baseURL = [NSURL URLWithString:versionInfo[TMLBundleBaseURLKey]];
}

- (void)reloadApplicationData {
    NSString *path = [self.path stringByAppendingPathComponent:TMLBundleApplicationFilename];
    NSData *applicationData = [NSData dataWithContentsOfFile:path];
    NSDictionary *applicationInfo = [applicationData tmlJSONObject];
    if (applicationInfo == nil) {
        TMLWarn(@"Cannot find application info at path: %@", path);
        return;
    }
    self.application = [TMLAPISerializer materializeObject:applicationInfo
                                                 withClass:[TMLApplication class]];
}

- (void)reloadSourcesData {
    NSString *path = [self.path stringByAppendingPathComponent:TMLBundleSourcesFilename];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *sources = [data tmlJSONObject];
    if (sources == nil) {
        TMLWarn(@"Cannot find sources defintion at path: %@", path);
        self.sources = @[];
    }
    else {
        self.sources = sources;
    }
}

- (void)reloadTranslationKeysData {
    NSString *path = [self.path stringByAppendingPathComponent:TMLBundleTranslationKeysFilename];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    TMLDebug(@"Loading keys resources from %@", path);
    
    NSDictionary *keysHash = [data tmlJSONObject][TMLAPIResponseResultsKey];
    if (keysHash == nil) {
        TMLWarn(@"Cannot find translation keys definition at path: %@", path);
        self.translationKeys = @{};
        return;
    }
    
    NSMutableDictionary *translationKeys = [NSMutableDictionary dictionary];
    NSArray *keys = [keysHash allKeys];
    
    for (NSString *key in keys) {
        NSDictionary *data = [keysHash objectForKey:key];
        TMLTranslationKey *translationKey = [[TMLTranslationKey alloc] init];
        translationKey.key = key;
        translationKey.label = [data objectForKey:@"label"];
        translationKey.keyDescription = [data objectForKey:@"description"];
        translationKey.locale = [data objectForKey:@"locale"];
        if ([data objectForKey:@"level"])
            translationKey.level = [[data objectForKey:@"level"] intValue];
        [translationKeys setObject:translationKey forKey:key];
    }
    
    self.translationKeys = translationKeys;
}

- (void)reloadAvailableLocales {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.path error:&error];
    NSMutableArray *locales = [NSMutableArray array];
    if (contents == nil) {
        TMLError(@"Error listing available bundle locales: %@", error);
    }
    else {
        BOOL isDir = NO;
        for (NSString *path in contents) {
            if ([fileManager fileExistsAtPath:[self.path stringByAppendingPathComponent:path] isDirectory:&isDir] == YES
                && isDir == YES) {
                [locales addObject:[path lastPathComponent]];
            }
        }
    }
    self.availableLocales = locales;
}

#pragma mark - Accessors

- (NSString *)version {
    if (_version == nil) {
        [self reloadVersionInfo];
    }
    return _version;
}

- (NSURL *)sourceURL {
    if (_sourceURL == nil) {
        [self reloadVersionInfo];
    }
    return _sourceURL;
}

- (NSURL *)baseURL {
    if (_baseURL == nil) {
        [self reloadVersionInfo];
    }
    return _baseURL;
}

- (TMLApplication *)application {
    if (_application == nil) {
        [self reloadApplicationData];
    }
    return _application;
}

- (NSArray *)sources {
    if (_sources == nil) {
        [self reloadSourcesData];
    }
    return _sources;
}

- (NSDictionary *)translationKeys {
    if (_translationKeys == nil) {
        [self reloadTranslationKeysData];
    }
    return _translationKeys;
}

- (NSArray *)availableLocales {
    if (_availableLocales == nil) {
        [self reloadAvailableLocales];
    }
    return _availableLocales;
}

- (NSArray *)locales {
    NSArray *langs = self.languages;
    return [langs valueForKeyPath:@"locale"];
}

- (NSArray *)languages {
    TMLApplication *app = self.application;
    return app.languages;
}

#pragma mark - Languages

- (NSString *)matchLocale:(NSString *)locale {
    NSArray *allLocales = [[[self application] languages] valueForKeyPath:@"locale"];
    NSString *ourLocale = [locale lowercaseString];
    NSArray *parts = [ourLocale componentsSeparatedByString:@"-"];
    NSString *lang = parts[0];
    NSString *result = nil;
    for (NSString *l in allLocales) {
        NSString *matchingLocale = [l lowercaseString];
        if ([matchingLocale isEqualToString:ourLocale] == YES) {
            result = l;
            break;
        }
        else if ([matchingLocale isEqualToString:lang] == YES) {
            result = l;
        }
    }
    return result;
}

- (TMLLanguage *)languageForLocale:(NSString *)locale {
    NSString *applicableLocale = [self matchLocale:locale];
    if (applicableLocale == nil) {
        return nil;
    }
    TMLLanguage *lang = _availableLanguages[applicableLocale];
    if (lang == nil) {
        [self loadLocalLanguageForLocale:applicableLocale];
    }
    lang = _availableLanguages[applicableLocale];
    return lang;
}

- (void)loadLocalLanguageForLocale:(NSString *)locale {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *languageFilePath = [[self.path stringByAppendingPathComponent:locale] stringByAppendingPathComponent:TMLBundleLanguageFilename];
    if ([fileManager fileExistsAtPath:languageFilePath] == NO) {
        TMLDebug(@"Cannot find %@ for locale '%@'", TMLBundleLanguageFilename, locale);
        return;
    }
    NSData *data = [NSData dataWithContentsOfFile:languageFilePath];
    if (data == nil) {
        TMLError(@"Failed to load %@ for locale '%@'", TMLBundleLanguageFilename, locale);
        return;
    }
    TMLLanguage *lang = [TMLAPISerializer materializeData:data withClass:[TMLLanguage class]];
    if (lang == nil) {
        TMLError(@"Failed to materialize %@ for locale '%@'", TMLBundleLanguageFilename, locale);
    }
    else {
        _availableLanguages[locale] = lang;
    }
}

#pragma mark - Translations

- (NSString *)translationsPathForLocale:(NSString *)locale {
    return [[self.path stringByAppendingPathComponent:locale] stringByAppendingPathComponent:TMLBundleTranslationsFilename];
}

- (BOOL)hasLocaleTranslationsForLocale:(NSString *)locale {
    if (_translations[locale] != nil) {
        return YES;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *basePath = [self.path stringByAppendingPathComponent:locale];
    
    NSString *languageFilePath = [basePath stringByAppendingPathComponent:TMLBundleLanguageFilename];
    NSString *translationsFilePath = [basePath stringByAppendingPathComponent:TMLBundleTranslationsFilename];
    return ([fileManager fileExistsAtPath:languageFilePath] == YES
            && [fileManager fileExistsAtPath:translationsFilePath] == YES);
}

- (NSDictionary *)translationsForLocale:(NSString *)locale {
    NSDictionary *translations = _translations[locale];
    if (translations == nil) {
        [self loadLocalTranslationsForLocale:locale];
        translations = _translations[locale];
    }
    return translations;
}

- (void)addTranslation:(TMLTranslation *)translation locale:(NSString *)locale {
    if (self.isMutable == NO) {
        return;
    }
    if (_translations[locale] == nil) {
        [self loadLocalTranslationsForLocale:locale];
    }
    NSMutableDictionary *translations = [_translations[locale] mutableCopy];
    NSArray *all = translations[translation.translationKey];
    if (all == nil) {
        all = [NSArray arrayWithObject:translation];
    }
    else {
        all = [[NSArray arrayWithObject:translation] arrayByAddingObjectsFromArray:all];
    }
    translations[translation.translationKey] = all;
    _translations[locale] = translations;
}

- (void)loadLocalTranslationsForLocale:(NSString *)aLocale {
    NSString *locale = aLocale;
    NSArray *availableLocales = self.availableLocales;
    NSString *translationsPath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([availableLocales containsObject:locale] == YES) {
        translationsPath = [self translationsPathForLocale:locale];
        if ([fileManager fileExistsAtPath:translationsPath] == NO) {
            translationsPath = nil;
        }
    }
    if (translationsPath != nil) {
        NSMutableDictionary *translations = [NSMutableDictionary dictionary];
        NSData *data = [NSData dataWithContentsOfFile:translationsPath];
        NSDictionary *info = [data tmlJSONObject];
        if (info[TMLAPIResponseResultsKey] != nil) {
            info = info[TMLAPIResponseResultsKey];
        }
        
        for (NSString *key in info) {
            NSArray *translationsList = nil;
            if ([info[key] isKindOfClass:[NSArray class]] == YES) {
                translationsList = info[key];
            }
            else if ([info[key] isKindOfClass:[NSDictionary class]] == YES) {
                translationsList = info[key][TMLAPIResponseResultsTranslationsKey];
            }
            if (translationsList.count > 0) {
                NSArray *newTranslations = [TMLAPISerializer materializeObject:translationsList
                                                                     withClass:[TMLTranslation class]];
                translations[key] = newTranslations;
            }
            // associate translations with translation key and locale
            for (TMLTranslation *translation in translations[key]) {
                translation.locale = aLocale;
                translation.translationKey = key;
            }
        }
        
        if (_translations == nil) {
            _translations = [NSMutableDictionary dictionary];
        }
        _translations[locale] = [translations copy];
    }
}

- (void)loadTranslationsForLocale:(NSString *)aLocale
                       completion:(void(^)(NSError *error))completion
{
    NSString *locale = aLocale;
    NSDictionary *loadedTranslations = [self translationsForLocale:locale];
    if (loadedTranslations != nil) {
        if (completion != nil) {
            completion(nil);
        }
        return;
    }
    
    NSMutableArray *paths = [NSMutableArray array];
    NSArray *sources = [self sources];
    [paths addObject:[locale stringByAppendingPathComponent:TMLBundleLanguageFilename]];
    [paths addObject:[locale stringByAppendingPathComponent:TMLBundleTranslationsFilename]];
    for (NSString *source in sources) {
        [paths addObject:[[locale stringByAppendingPathComponent:TMLBundleSourcesRelativePath] stringByAppendingPathComponent:[source stringByAppendingPathExtension:@"json"]]];
    }
    
    [[TMLBundleManager defaultManager] fetchPublishedResources:paths
                                                     forBundle:self
                                               completionBlock:^(BOOL success, NSArray *paths, NSArray *errors) {
                                                       if (success == YES && paths.count > 0) {
                                                           [self installResources:paths completion:completion];
                                                       }
                                                       else if (completion != nil) {
                                                           NSDictionary *errorInfo = @{
                                                                                       TMLBundleErrorsKey: errors
                                                                                       };
                                                           NSError *ourError = [NSError errorWithDomain:TMLBundleErrorDomain
                                                                                                   code:TMLBundleMissingResources
                                                                                               userInfo:errorInfo];
                                                           completion(ourError);
                                                       }
                                               }];
}

#pragma mark - Translation Keys

- (NSArray *)translationKeysMatchingString:(NSString *)string
                                    locale:(NSString *)locale
{
    if (string == nil) {
        return nil;
    }
    
    NSMutableArray *foundKeys = [NSMutableArray array];
    NSDictionary *translationKeys = self.translationKeys;
    for (NSString *key in translationKeys) {
        TMLTranslationKey *translationKey = translationKeys[key];
        if ([string isEqualToString:translationKey.label] == YES
            && [locale isEqualToString:translationKey.locale] == YES) {
            [foundKeys addObject:translationKey.key];
        }
    }
    
    if (foundKeys.count == 0) {
        NSDictionary *translations = [self translationsForLocale:locale];
        for (NSString *key in translations) {
            for (TMLTranslation *translation in translations[key]) {
                if ([translation.label isEqualToString:string] == NO) {
                    continue;
                }
                [foundKeys addObject:key];
            }
        }
    }
    return (foundKeys.count > 0) ? [foundKeys copy] : nil;
}

#pragma mark - Synchronization

- (void)loadCompleteBundle:(void(^)(NSError *error))completion {
    NSURL *url = self.sourceURL;
    TMLBundleManager *manager = [TMLBundleManager defaultManager];
    [manager installBundleFromURL:url completionBlock:^(TMLBundle *bundle, NSError *error) {
        if (bundle != nil) {
            TMLInfo(@"Bundle successfully synchronized: %@", bundle.path);
        }
        else {
            TMLError(@"Bundle failed to synchronize: %@", error);
        }
        if (completion != nil) {
            completion(error);
        }
    }];
}

- (void)loadMetaData:(void(^)(NSError *error))completion {
    NSArray *paths = @[
                       TMLBundleApplicationFilename,
                       TMLBundleSourcesFilename,
                       TMLBundleVersionFilename
                       ];
    
    [[TMLBundleManager defaultManager] fetchPublishedResources:paths
                                                       baseURL:[self baseURL]
                                               destinationPath:nil
                                               completionBlock:^(BOOL success, NSArray *paths, NSArray *errors) {
                                                   [self installResources:paths completion:^(NSError *error) {
                                                       if (completion != nil) {
                                                           completion(error);
                                                       }
                                                   }];
                                               }];
}

#pragma mark - Resources

- (void)installResources:(NSArray *)resourcePaths
              completion:(void(^)(NSError *))completion
{
    if (resourcePaths.count == 0) {
        if (completion != nil) {
            completion(nil);
        }
        return;
    }
    
    __block NSInteger count = 0;
    NSString *version = self.version;
    __block NSMutableArray *allErrors = [NSMutableArray array];
    
    for (NSString *path in resourcePaths) {
        NSArray *pathComponents = [path pathComponents];
        NSInteger index = [pathComponents indexOfObject:version];
        NSString *relativePath = nil;
        if (index < pathComponents.count - 1) {
            relativePath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(index+1, pathComponents.count - index - 1)]];
        }
        if (relativePath == nil) {
            NSError *installError = [NSError errorWithDomain:TMLBundleErrorDomain
                                                        code:TMLBundleInvalidResourcePath
                                                    userInfo:@{
                                                               TMLBundleErrorResourcePathKey: path
                                                               }];
            [allErrors addObject:installError];
            continue;
        }
        [self installResourceFromPath:path
                        withRelativeBundlePath:relativePath
                               completionBlock:^(NSString *path, NSError *error) {
                                   count++;
                                   if (error != nil) {
                                       [allErrors addObject:error];
                                   }
                                   if (count == resourcePaths.count) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self resetData];
                                           [self notifyBundleMutation:TMLLocalizationDataChangedNotification errors:allErrors];
                                           if (completion != nil) {
                                               completion((allErrors.count > 0) ? [allErrors firstObject] : nil);
                                           }
                                       });
                                   }
                               }];
    }
}

- (void) installResourceFromPath:(NSString *)resourcePath
          withRelativeBundlePath:(NSString *)relativeBundlePath
                 completionBlock:(void(^)(NSString *path, NSError *error))completionBlock
{
    NSString *bundleRootPath = [self path];
    NSString *destinationPath = [bundleRootPath stringByAppendingPathComponent:relativeBundlePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *destinationRoot = [destinationPath stringByDeletingLastPathComponent];
    NSError *error;
    if ([fileManager fileExistsAtPath:destinationRoot] == NO) {
        if ([fileManager createDirectoryAtPath:destinationRoot
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error] == NO){
            TMLError(@"Error creating installation directory for resource '%@': %@", relativeBundlePath, error);
        }
    }
    if (error == nil
        && [resourcePath isEqualToString:destinationPath] == NO) {
        if ([fileManager fileExistsAtPath:destinationPath] == YES) {
            if([fileManager removeItemAtPath:destinationPath error:&error] == NO) {
                TMLError(@"Error removing existing resource at path '%@': %@", error);
            }
        }
        if ([fileManager moveItemAtPath:resourcePath toPath:destinationPath error:&error] == NO) {
            TMLError(@"Error installing resource '%@' : %@", relativeBundlePath, error);
        }
    }
    if (completionBlock != nil) {
        completionBlock((error) ? nil : destinationPath, error);
    }
}

#pragma mark -
- (BOOL)isValid {
    NSString *ourPath = [self path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = @[TMLBundleApplicationFilename, TMLBundleSourcesFilename];
    for (NSString *fileName in fileNames) {
        NSString *path = [ourPath stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:path] == NO) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Notifications
- (void) notifyBundleMutation:(NSString *)mutationType
                       errors:(NSArray *)errors
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[TMLBundleChangeInfoBundleKey] = self;
    if (errors.count > 0) {
        info[TMLBundleChangeInfoErrorsKey] = errors;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:mutationType
                                                        object:nil
                                                      userInfo:info];
}

#pragma mark -
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%@: %p>", [self class], self.version, self];
}

@end
