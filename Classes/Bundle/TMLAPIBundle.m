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
#import "TML.h"
#import "TMLAPIBundle.h"
#import "TMLAPIClient.h"
#import "TMLAPIResponse.h"
#import "TMLApplication.h"
#import "TMLBundleManager.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLSource.h"
#import "TMLTranslationKey.h"

@interface TMLBundle()
- (void)resetData;
@end

@interface TMLAPIBundle() {
    BOOL _needsSync;
    NSMutableArray *_syncErrors;
    NSInteger _syncOperationCount;
}
@property (strong, nonatomic) NSArray *sources;
@property (readwrite, nonatomic) NSArray *languages;
@property (readwrite, nonatomic) TMLApplication *application;
@property (readwrite, nonatomic) NSDictionary *translations;
@property (readwrite, nonatomic) NSDictionary *translationKeys;
@property (readwrite, nonatomic) NSMutableDictionary *addedTranslationKeys;
@property (strong, nonatomic) NSOperationQueue *syncQueue;
@end

@implementation TMLAPIBundle

@dynamic sources, languages, application, translations, translationKeys;

- (BOOL)isMutable {
    return YES;
}

#pragma mark - Languages

- (void)addLanguage:(TMLLanguage *)language {
    NSMutableArray *newLanguages = [NSMutableArray arrayWithObject:language];
    NSArray *existingLanguages = self.languages;
    for (TMLLanguage *lang in existingLanguages) {
        if ([lang.locale isEqualToString:language.locale] == NO) {
            [newLanguages addObject:lang];
        }
    }
    self.languages = newLanguages;
}

#pragma mark - Locales

/**
 *  Cleans up bundle by removing locales that are not in the list of effective locales
 *
 *  @param locales Effective locales
 */
- (void)cleanupLocales:(NSArray *)locales {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.path error:&error];
    if (error != nil) {
        TMLError(@"Error cleaning up locales of the API bundle: %@", error);
        return;
    }
    BOOL isDir = NO;
    for (NSString *path in contents) {
        NSString *fullPath = [self.path stringByAppendingPathComponent:path];
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] == NO
            || isDir == NO) {
            continue;
        }
        if ([locales containsObject:path] == YES) {
            continue;
        }
        if ([fileManager removeItemAtPath:fullPath error:&error] == NO) {
            TMLError(@"Error cleaning up locale '%@' of API bundle: %@", path, error);
        }
    }
}

#pragma mark - Translations
- (void)loadTranslationsForLocale:(NSString *)aLocale
                       completion:(void (^)(NSError *))completion {
    [self loadTranslationsForLocale:aLocale
                requireLanguageData:YES
                         completion:completion];
}

- (void)loadTranslationsForLocale:(NSString *)aLocale
              requireLanguageData:(BOOL)requireLanguageData
                       completion:(void (^)(NSError *))completion
{
    
    TMLDebug(@"Loading translations for locale %@", aLocale);
    
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    
    NSString *languageFilePath = [[[self path] stringByAppendingPathComponent:aLocale] stringByAppendingPathComponent:TMLBundleLanguageFilename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:languageFilePath] == NO && requireLanguageData == YES) {
        [client getLanguageForLocale:aLocale
                             options:nil
                     completionBlock:^(TMLLanguage *language, TMLAPIResponse *response, NSError *error) {
                         NSError *fileError;
                         if (language != nil) {
                             [self addLanguage:language];
                             NSData *writeData = [[response.userInfo tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *relativePath = [aLocale stringByAppendingPathComponent:TMLBundleLanguageFilename];
                             [self writeResourceData:writeData
                                      toRelativePath:relativePath
                                               error:&fileError];
                         }
                         [self loadTranslationsForLocale:aLocale requireLanguageData:NO completion:completion];
                     }];
        return;
    }
    
    [client getTranslationsForLocale:aLocale
                              source:nil
                             options:nil
                     completionBlock:^(NSDictionary *translations, TMLAPIResponse *response, NSError *error) {
                         if (translations != nil) {
                             [self setTranslations:translations forLocale:aLocale];
                             NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.results};
                             NSData *writeData = [[jsonObj tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *relativePath = [aLocale stringByAppendingPathComponent:TMLBundleTranslationsFilename];
                             
                             NSError *fileError;
                             [self writeResourceData:writeData
                                      toRelativePath:relativePath
                                               error:&fileError];
                             if (error == nil && fileError != nil) {
                                 error = fileError;
                             }
                         }
                         if (completion != nil) {
                             completion(error);
                         }
    }];
}

- (void)setTranslations:(NSDictionary *)translations forLocale:(NSString *)locale {
    NSMutableDictionary *allTranslations = [self.translations mutableCopy];
    if (allTranslations == nil) {
        allTranslations = [NSMutableDictionary dictionary];
    }
    
    if (translations.count == 0
        && allTranslations[locale] != nil) {
        allTranslations[locale] = nil;
    }
    else {
        allTranslations[locale] = translations;
    }
    
    self.translations = allTranslations;
}

- (void)addTranslationKey:(TMLTranslationKey *)translationKey
                forSource:(NSString *)sourceKey
{
    if (translationKey.label.length == 0) {
        return;
    }
    
    NSMutableDictionary *addedTranslationKeys = [self.addedTranslationKeys mutableCopy];
    if (addedTranslationKeys == nil) {
        addedTranslationKeys = [NSMutableDictionary dictionary];
    }
    
    @synchronized(self) {
        NSString *effectiveSourceKey = sourceKey;
        if (effectiveSourceKey == nil) {
            effectiveSourceKey = [[TML sharedInstance] currentSource];
        }
        
        NSMutableSet *keys = [addedTranslationKeys[effectiveSourceKey] mutableCopy];
        if (keys == nil) {
            keys = [NSMutableSet set];
        }
        
        [keys addObject:translationKey];
        addedTranslationKeys[effectiveSourceKey] = keys;
        self.addedTranslationKeys = addedTranslationKeys;
    }
}

- (void)removeAddedTranslationKeys:(NSDictionary *)translationKeys {
    @synchronized(self) {
        if (_addedTranslationKeys.count == 0) {
            return;
        }
        
        for (NSString *source in translationKeys) {
            NSMutableSet *keys = [_addedTranslationKeys[source] mutableCopy];
            for (TMLTranslationKey *key in translationKeys[source]) {
                [keys removeObject:key];
            }
            _addedTranslationKeys[source] = keys;
        }
    }
}

- (void)setAddedTranslationKeys:(NSMutableDictionary *)addedTranslationKeys {
    if ([_addedTranslationKeys isEqualToDictionary:addedTranslationKeys] == YES) {
        return;
    }
    _addedTranslationKeys = addedTranslationKeys;
    [self didAddTranslationKeys];
}

- (void)didAddTranslationKeys {
    if (TMLSharedConfiguration().neverSubmitNewTranslationKeys == YES) {
        return;
    }
    [self setNeedsSync];
}

#pragma mark - Resource handling

- (BOOL)writeResourceData:(NSData *)data
           toRelativePath:(NSString *)relativeResourcePath
                    error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *destinationPath = [self.path stringByAppendingPathComponent:relativeResourcePath];
    NSString *destinationDir = [destinationPath stringByDeletingLastPathComponent];
    NSError *fileError = nil;
    if ([fileManager fileExistsAtPath:destinationDir] == NO) {
        if ([fileManager createDirectoryAtPath:destinationDir
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&fileError] == NO) {
            TMLError(@"Error creating resource directory: %@", fileError);
        }
    }
    if (fileError == nil
        && [data writeToFile:destinationPath options:NSDataWritingAtomic error:&fileError] == NO){
        TMLError(@"Error write resource data: %@", fileError);
    }
    if (error != nil && fileError != nil) {
        *error = fileError;
    }
    return (fileError != nil);
}

#pragma mark - Sync

- (BOOL)isSyncing {
    return _syncOperationCount > 0;
}

-(void)setNeedsSync {
    _needsSync = YES;
    if (self.syncEnabled == NO) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(sync)
                                               object:nil];
    
    NSTimeInterval delay = 0.;
    NSArray *availableLocales = [self availableLocales];
    if (availableLocales.count > 0
        && [availableLocales containsObject:TMLCurrentLocale()] == YES) {
        delay = 3.;
    }
    [self performSelector:@selector(sync)
               withObject:nil
               afterDelay:delay];
}

- (NSOperationQueue *)syncQueue {
    if (_syncQueue == nil) {
        _syncQueue = [[NSOperationQueue alloc] init];
    }
    return _syncQueue;
}

- (void)addSyncOperation:(NSOperation *)syncOperation {
    NSOperationQueue *syncQueue = self.syncQueue;
    [syncQueue addOperation:syncOperation];
    _syncOperationCount++;
    if (_syncOperationCount == 1) {
        [self notifyBundleMutation:TMLDidStartSyncNotification
                            errors:nil];
    }
}

- (void)cancelSync {
    if (_syncOperationCount == 0) {
        return;
    }
    NSOperationQueue *syncQueue = self.syncQueue;
    [syncQueue cancelAllOperations];
    _syncOperationCount = 0;
}

- (void)sync {
    if (self.syncEnabled == NO) {
        [self setNeedsSync];
        return;
    }
    if (_syncOperationCount > 0) {
        return;
    }
    
    _needsSync = NO;
    
    NSOperationQueue *syncQueue = self.syncQueue;
    syncQueue.suspended = YES;
    
    [self syncMetaData];
    NSMutableArray *locales = [self.availableLocales mutableCopy];
    if (locales == nil) {
        locales = [NSMutableArray array];
    }
    
    NSString *defaultLocale = TMLDefaultLocale();
    if (defaultLocale != nil && [locales containsObject:defaultLocale] == NO) {
        [locales addObject:defaultLocale];
    }
    
    NSString *currentLocale = TMLCurrentLocale();
    if (currentLocale != nil && [locales containsObject:currentLocale] == NO) {
        [locales addObject:currentLocale];
    }
    
    if (locales.count > 0) {
        [self syncLocales:locales];
    }
    [self syncAddedTranslationKeys];
    syncQueue.suspended = NO;
}

- (void)syncCurrentLocaleOnly {
    NSString *currentLocale = TMLCurrentLocale();
    [self syncLocales:@[currentLocale]];
    
    self.syncQueue.suspended = NO;
}

- (void)syncMetaData {
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getTranslatorInfo:^(TMLTranslator *translator, TMLAPIResponse *response, NSError *error) {
            NSError *fileError;
            if (translator != nil) {
                TMLSharedConfiguration().currentTranslator = translator;
            }
            NSMutableArray *errors = [NSMutableArray array];
            if (error != nil) {
                [errors addObject:error];
            }
            if (fileError != nil) {
                [errors addObject:fileError];
            }
            
            [self didFinishSyncOperationWithErrors:errors];
        }];
        
    }]];
    
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getCurrentApplicationWithOptions:@{TMLAPIOptionsIncludeDefinition: @YES}
                                 completionBlock:^(TMLApplication *application, TMLAPIResponse *response, NSError *error) {
                                     NSError *fileError;
                                     if (application != nil) {
                                         self.application = application;
                                         NSArray *appLocales = [application.languages valueForKeyPath:@"locale"];
                                         [self cleanupLocales:appLocales];
                                         NSData *writeData = [[response.userInfo tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                                         [self writeResourceData:writeData
                                                  toRelativePath:TMLBundleApplicationFilename
                                                           error:&fileError];
                                     }
                                     NSMutableArray *errors = [NSMutableArray array];
                                     if (error != nil) {
                                         [errors addObject:error];
                                     }
                                     if (fileError != nil) {
                                         [errors addObject:fileError];
                                     }
                                     
                                     [self didFinishSyncOperationWithErrors:errors];
                                 }];
    }]];
    
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getSources:nil
           completionBlock:^(NSArray *sources, TMLAPIResponse *response, NSError *error) {
               NSError *fileError;
               if (sources != nil) {
                   self.sources = sources;
                   NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.results};
                   [self writeResourceData:[[jsonObj tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding]
                            toRelativePath:TMLBundleSourcesFilename
                                     error:&fileError];
               }
               NSMutableArray *errors = [NSMutableArray array];
               if (error != nil) {
                   [errors addObject:error];
               }
               if (fileError != nil) {
                   [errors addObject:fileError];
               }
               
               [self didFinishSyncOperationWithErrors:errors];
           }];
    }]];
    
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getTranslationKeysWithOptions:nil
                              completionBlock:^(NSDictionary *translationKeys, TMLAPIResponse *response, NSError *error) {
                                  NSError *fileError;
                                  if (translationKeys != nil) {
                                      self.translationKeys = translationKeys;
                                      NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.results};
                                      [self writeResourceData:[[jsonObj tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding]
                                               toRelativePath:TMLBundleTranslationKeysFilename
                                                        error:&fileError];
                                  }
                                  NSMutableArray *errors = [NSMutableArray array];
                                  if (error != nil) {
                                      [errors addObject:error];
                                  }
                                  if (fileError != nil) {
                                      [errors addObject:fileError];
                                  }
                                  [self didFinishSyncOperationWithErrors:errors];
                              }];
    }]];
}

- (void)syncLocales:(NSArray *)locales {
    if (locales.count == 0) {
        return;
    }
    
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    for (NSString *aLocale in locales) {
        NSString *locale = aLocale;
        // fetch translation
        [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
            [client getTranslationsForLocale:locale
                                      source:nil
                                     options:nil
                             completionBlock:^(NSDictionary *translations, TMLAPIResponse *response, NSError *error) {
                                 NSError *fileError;
                                 if (translations != nil) {
                                     [self setTranslations:translations forLocale:locale];
                                     NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.results};
                                     NSData *writeData = [[jsonObj tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                                     NSString *relativePath = [locale stringByAppendingPathComponent:TMLBundleTranslationsFilename];
                                     
                                     [self writeResourceData:writeData
                                              toRelativePath:relativePath
                                                       error:&fileError];
                                 }
                                 NSMutableArray *errors = [NSMutableArray array];
                                 if (error != nil) {
                                     [errors addObject:error];
                                 }
                                 if (fileError != nil) {
                                     [errors addObject:fileError];
                                 }
                                 [self didFinishSyncOperationWithErrors:errors];
                             }];
        }]];
        
        // fetch language definition
        [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
            [client getLanguageForLocale:locale
                                 options:@{TMLAPIOptionsIncludeDefinition: @YES}
                         completionBlock:^(TMLLanguage *language, TMLAPIResponse *response, NSError *error) {
                             NSError *fileError;
                             if (language != nil) {
                                 [self addLanguage:language];
                                 NSData *writeData = [[response.userInfo tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                                 NSString *relativePath = [locale stringByAppendingPathComponent:TMLBundleLanguageFilename];
                                 [self writeResourceData:writeData
                                          toRelativePath:relativePath
                                                   error:&fileError];
                             }
                             
                             NSMutableArray *errors = [NSMutableArray array];
                             if (error != nil) {
                                 [errors addObject:error];
                             }
                             if (fileError != nil) {
                                 [errors addObject:fileError];
                             }
                             
                             [self didFinishSyncOperationWithErrors:errors];
                         }];
        }]];
    }
}

- (void)syncAddedTranslationKeys {
    if (TMLSharedConfiguration().neverSubmitNewTranslationKeys == YES) {
        return;
    }
    if (_addedTranslationKeys.count == 0) {
        return;
    }
    NSMutableDictionary *missingTranslations = self.addedTranslationKeys;
    BOOL hasKeys = NO;
    for (NSString *source in missingTranslations) {
        NSArray *value = missingTranslations[source];
        if (value.count > 0) {
            hasKeys = YES;
            break;
        }
    }
    if (hasKeys == NO) {
        return;
    }
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [[[TML sharedInstance] apiClient] registerTranslationKeysBySourceKey:missingTranslations
                                                             completionBlock:^(BOOL success, NSError *error) {
                                                                 if (success == YES) {
                                                                     [self removeAddedTranslationKeys:missingTranslations];
                                                                 }
                                                                 NSArray *errors = (error != nil) ? @[error] : nil;
                                                                 [self didFinishSyncOperationWithErrors:errors];
                                                             }];
    }]];
}

- (void)didFinishSyncOperationWithErrors:(NSArray *)errors {
    _syncOperationCount--;
    if (_syncOperationCount < 0) {
        TMLWarn(@"Unbalanced call to %s", __PRETTY_FUNCTION__);
        _syncOperationCount = 0;
    }
    if (_syncErrors == nil) {
        _syncErrors = [NSMutableArray array];
    }
    if (errors.count > 0) {
        [_syncErrors addObjectsFromArray:errors];
    }
    
    [self notifyBundleMutation:TMLLocalizationDataChangedNotification
                        errors:errors];
    
    if (_syncOperationCount == 0) {
        [self resetData];
        if (_needsSync == YES) {
            [self performSelector:@selector(sync) withObject:nil afterDelay:3.0];
        }
        [self notifyBundleMutation:TMLDidFinishSyncNotification
                            errors:_syncErrors];
    }
}

#pragma mark -

- (NSString *)version {
    return @"API";
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:API: %p>", [self class], self];
}

@end
