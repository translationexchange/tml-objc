//
//  TMLAPIBundle.m
//  Demo
//
//  Created by Pasha on 11/20/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLAPIBundle.h"
#import "TMLAPIClient.h"
#import "TMLProject.h"
#import "TMLBundleManager.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLSource.h"
#import "TMLTranslationKey.h"

@interface TMLAPIBundle() {
    BOOL _needsSync;
    NSMutableArray *_syncErrors;
    NSInteger _syncOperationCount;
}
@property (strong, nonatomic) NSArray *sources;
@property (readwrite, nonatomic) NSArray *languages;
@property (readwrite, nonatomic) TMLProject *application;
@property (readwrite, nonatomic) NSDictionary *translations;
@property (readwrite, nonatomic) NSMutableDictionary *addedTranslations;
@property (strong, nonatomic) NSOperationQueue *syncQueue;
@end

@implementation TMLAPIBundle

@dynamic sources, languages, application, translations;

- (NSURL *)sourceURL {
    return [[[TML sharedInstance] configuration] apiURL];
}

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
                       completion:(void (^)(NSError *))completion
{
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    [client getTranslationsForLocale:aLocale
                              source:nil
                             options:nil
                     completionBlock:^(NSDictionary *translations, TMLAPIResponse *response, NSError *error) {
                         if (translations != nil) {
                             [self setTranslations:translations forLocale:aLocale];
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
        TMLWarn(@"Tried to register missing translation for translationKey with empty label");
        return;
    }
    
    NSMutableDictionary *addedTranslations = self.addedTranslations;
    if (addedTranslations == nil) {
        addedTranslations = [NSMutableDictionary dictionary];
    }
    
    @synchronized(_addedTranslations) {
        NSString *effectiveSourceKey = sourceKey;
        if (effectiveSourceKey == nil) {
            effectiveSourceKey = TMLSourceDefaultKey;
        }
        
        NSMutableSet *keys = addedTranslations[effectiveSourceKey];
        if (keys == nil) {
            keys = [NSMutableSet set];
        }
        
        [keys addObject:translationKey];
        addedTranslations[effectiveSourceKey] = keys;
        self.addedTranslations = addedTranslations;
    }
    
}

- (void)removeAddedTranslations:(NSDictionary *)translations {
    @synchronized(_addedTranslations) {
        if (_addedTranslations.count == 0) {
            return;
        }
        
        for (NSString *source in translations) {
            NSMutableSet *keys = [_addedTranslations[source] mutableCopy];
            for (TMLTranslationKey *key in translations[source]) {
                [keys removeObject:key];
            }
            _addedTranslations[source] = keys;
        }
    }
}

- (void)setAddedTranslations:(NSMutableDictionary *)addedTranslations {
    if (_addedTranslations == addedTranslations
        || [_addedTranslations isEqualToDictionary:addedTranslations] == YES) {
        return;
    }
    _addedTranslations = addedTranslations;
    [self didAddTranslations];
}

- (void)didAddTranslations {
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

-(void)setNeedsSync {
    _needsSync = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(sync)
                                               object:nil];
    [self performSelector:@selector(sync)
               withObject:nil
               afterDelay:3.0];
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
        [[TMLBundleManager defaultManager] notifyBundleMutation:TMLBundleSyncDidStartNotification
                                                         bundle:self
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
    
    TML *tml = [TML sharedInstance];
    NSString *defaultLocale = [[tml defaultLanguage] locale];
    if (defaultLocale == nil) {
        defaultLocale = tml.configuration.defaultLocale;
    }
    if (defaultLocale != nil && [locales containsObject:defaultLocale] == NO) {
        [locales addObject:defaultLocale];
    }
    
    NSString *currentLocale = [[tml currentLanguage] locale];
    if (currentLocale == nil) {
        currentLocale = tml.configuration.currentLocale;
    }
    if (currentLocale != nil && [locales containsObject:currentLocale] == NO) {
        [locales addObject:currentLocale];
    }
    
    if (locales.count > 0) {
        [self syncLocales:locales];
    }
    [self syncAddedTranslations];
    syncQueue.suspended = NO;
}

- (void)syncMetaData {
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getCurrentApplicationWithOptions:@{TMLAPIOptionsIncludeDefinition: @YES}
                                 completionBlock:^(TMLProject *application, TMLAPIResponse *response, NSError *error) {
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
}

- (void)syncLocales:(NSArray *)locales {
    if (locales.count == 0) {
        return;
    }
    
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    for (NSString *aLocale in locales) {
        NSString *locale = [aLocale lowercaseString];
        // fetch translation
        [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
            [client getTranslationsForLocale:locale
                                      source:nil
                                     options:nil
                             completionBlock:^(NSDictionary<NSString *,TMLTranslation *> *translations, TMLAPIResponse *response, NSError *error) {
                                 NSError *fileError;
                                 if (translations != nil) {
                                     [self setTranslations:translations forLocale:locale];
                                     NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.userInfo};
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

- (void)syncAddedTranslations {
    if (_addedTranslations.count == 0) {
        return;
    }
    NSMutableDictionary *missingTranslations = self.addedTranslations;
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [[[TML sharedInstance] apiClient] registerTranslationKeysBySourceKey:missingTranslations
                                                             completionBlock:^(BOOL success, NSError *error) {
                                                                 if (success == YES) {
                                                                     [self removeAddedTranslations:missingTranslations];
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
    
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    [bundleManager notifyBundleMutation:TMLBundleContentsChangedNotification
                                 bundle:self
                                 errors:errors];
    
    if (_syncOperationCount == 0) {
        if (_needsSync == YES) {
            [self performSelector:@selector(sync) withObject:nil afterDelay:3.0];
        }
        [bundleManager notifyBundleMutation:TMLBundleSyncDidFinishNotification
                                     bundle:self
                                     errors:_syncErrors];
    }
}

#pragma mark -

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:API: %p>", [self class], self];
}

@end
