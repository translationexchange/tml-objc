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
#import "TMLConfiguration.h"
#import "TMLLanguage.h"

@interface TMLAPIBundle()
@property(strong, nonatomic) NSOperationQueue *syncQueue;
@property(strong, nonatomic) NSArray *sources;
@property (readwrite, nonatomic) NSArray *languages;
@property (readwrite, nonatomic) TMLApplication *application;
@property (readwrite, nonatomic) NSDictionary *translations;
@end

@implementation TMLAPIBundle

@dynamic sources, languages, application, translations;

- (NSURL *)sourceURL {
    return [[[TML sharedInstance] configuration] apiURL];
}

- (NSOperationQueue *)syncQueue {
    if (_syncQueue == nil) {
        _syncQueue = [[NSOperationQueue alloc] init];
    }
    return _syncQueue;
}

- (BOOL)isStaticBundle {
    return NO;
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

#pragma mark - Translations

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

- (void)synchronize:(void (^)(NSError *error))completion {
    [self synchronizeApplicationData:^(NSError *error) {
        NSArray *locales;
        if (error == nil) {
            locales = self.locales;
        }
        if (locales.count > 0) {
            [self synchronizeLocales:locales completion:completion];
        }
        else if (completion != nil) {
            completion(error);
        }
    }];
}

- (void)synchronizeApplicationData:(void (^)(NSError *error))completion {
    void(^finalize)(NSError *) = ^(NSError *err) {
        if (completion != nil) {
            completion(err);
        }
    };
    
    NSOperationQueue *syncQueue = self.syncQueue;
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    __block NSInteger count = 0;
    count++;
    [syncQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getCurrentApplicationWithOptions:@{TMLAPIOptionsIncludeDefinition: @YES}
                                 completionBlock:^(TMLApplication *application, TMLAPIResponse *response, NSError *error) {
                                     NSError *fileError;
                                     if (application != nil) {
                                         self.application = application;
                                         NSData *writeData = [[response.userInfo tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                                         [self writeResourceData:writeData
                                                  toRelativePath:TMLBundleApplicationFilename
                                                           error:&fileError];
                                     }
                                     count--;
                                     if (count == 0) {
                                         finalize((error) ? error : fileError);
                                     }
                                 }];
    }]];
    
    count++;
    [syncQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
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
               count--;
               if (count == 0) {
                   finalize((error) ? error: fileError);
               }
           }];
    }]];
}

- (void)synchronizeLocales:(NSArray *)locales completion:(void (^)(NSError *))completion {
    if (locales.count == 0) {
        if (completion != nil) {
            completion(nil);
        }
        return;
    }
    
    void(^finalize)(NSError *) = ^(NSError *err) {
        if (completion != nil) {
            completion(err);
        }
    };
    
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    NSOperationQueue *syncQueue = self.syncQueue;
    __block NSInteger count = 0;
    
    for (NSString *aLocale in locales) {
        NSString *locale = [aLocale lowercaseString];
        // fetch translations
        count++;
        [syncQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            [client getTranslationsForLocale:locale
                                      source:nil
                                     options:nil
                             completionBlock:^(NSDictionary<NSString *,TMLTranslation *> *translations, TMLAPIResponse *response, NSError *error) {
                                 count--;
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
                                 
                                 if (count == 0) {
                                     finalize((error) ? error : fileError);
                                 }
                             }];
        }]];
        
        // fetch language definition
        count++;
        [syncQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            [client getLanguageForLocale:locale
                                 options:@{TMLAPIOptionsIncludeDefinition: @YES}
                         completionBlock:^(TMLLanguage *language, TMLAPIResponse *response, NSError *error) {
                             count--;
                             NSError *fileError;
                             
                             if (language != nil) {
                                 [self addLanguage:language];
                                 NSData *writeData = [[response.userInfo tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                                 NSString *relativePath = [locale stringByAppendingPathComponent:TMLBundleLanguageFilename];
                                 [self writeResourceData:writeData
                                          toRelativePath:relativePath
                                                   error:&fileError];
                             }
                             
                             if (count == 0) {
                                 finalize((error) ? error : fileError);
                             }
                         }];
        }]];
    }
}

@end
