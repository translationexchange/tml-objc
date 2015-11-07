//
//  TMLAPIResponse.m
//  Demo
//
//  Created by Pasha on 11/5/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TMLAPIResponse.h"
#import "TMLLanguage.h"
#import "TMLTranslation.h"

NSString * const TMLAPIResponsePaginationKey = @"pagination";
NSString * const TMLAPIResponseCurrentPageKey = @"current_page";
NSString * const TMLAPIResponseResultsPerPageKey = @"per_page";
NSString * const TMLAPIResponseTotalResultsKey = @"total_count";
NSString * const TMLAPIResponseTotalPagesKey = @"total_pages";
NSString * const TMLAPIResponsePageLinksKey = @"links";
NSString * const TMLAPIResponseFirstPageLinkKey = @"first";
NSString * const TMLAPIResponseLastPageLinkKey = @"last";
NSString * const TMLAPIResponseNextPageLinkKey = @"next";
NSString * const TMLAPIResponseCurrentPageLinkKey = @"self";

NSString * const TMLAPIResponseResultsKey = @"results";
NSString * const TMLAPIResponseResultsTranslationsKey = @"translations";

NSString * const TMLAPIResponseTranslationLabelKey = @"label";
NSString * const TMLAPIResponseTranslationLocaleKey = @"locale";
NSString * const TMLAPIResponseTranslationContextKey = @"context";

NSString * const TMLAPIResponseLanguageEnglishNameKey = @"english_name";
NSString * const TMLAPIResponseLanguageFlagURLKey = @"flag_url";
NSString * const TMLAPIResponseLanguageIDKey = @"id";
NSString * const TMLAPIResponseLanguageLocaleKey = @"locale";
NSString * const TMLAPIResponseLanguageNativeNameKey = @"native_name";
NSString * const TMLAPIResponseLanguageRTLKey = @"right_to_left";
NSString * const TMLAPIResponseLanguageStatusKey = @"status";

@interface TMLAPIResponse()
@property (readwrite, nonatomic) NSDictionary *userInfo;
@end

@implementation TMLAPIResponse

#pragma mark - Init

- (instancetype)initFromResponseResultObject:(id)resultObject {
    if (self = [super init]) {
        if ([resultObject isKindOfClass:[NSDictionary class]] == YES) {
            self.userInfo = (NSDictionary *)resultObject;
        }
    }
    return self;
}

#pragma mark - Results
- (id)results {
    return self.userInfo[TMLAPIResponseResultsKey];
}

- (NSDictionary<NSString *,TMLTranslation *> *)resultsAsTranslations {
    if ([self.results isKindOfClass:[NSDictionary class]] == NO) {
        return nil;
    }
    NSDictionary *results = self.results;
    NSMutableDictionary *translations = [NSMutableDictionary dictionary];
    for (NSString *hash in results) {
        NSMutableArray *infos = [results[hash] mutableCopy];
        for (NSInteger i=0; i<infos.count; i++) {
            NSDictionary *info = infos[i];
            TMLTranslation *translation = [[TMLTranslation alloc] init];
            translation.label = info[TMLAPIResponseTranslationLabelKey];
            translation.locale = info[TMLAPIResponseTranslationLocaleKey];
            translation.context = info[TMLAPIResponseTranslationContextKey];
            [infos replaceObjectAtIndex:i withObject:translation];
        }
        translations[hash] = infos;
    }
    return translations;
}

- (NSArray<TMLLanguage *> *)resultsAsLanguages {
    if ([self.results isKindOfClass:[NSArray class]] == NO) {
        return nil;
    }
    NSArray *results = self.results;
    NSMutableArray *languages = [NSMutableArray array];
    for (NSDictionary *info in results) {
        TMLLanguage *language = [[TMLLanguage alloc] init];
        language.languageID = [info[TMLAPIResponseLanguageIDKey] integerValue];
        language.locale = info[TMLAPIResponseLanguageLocaleKey];
        language.englishName = info[TMLAPIResponseLanguageEnglishNameKey];
        language.nativeName = info[TMLAPIResponseLanguageNativeNameKey];
        language.rightToLeft = info[TMLAPIResponseLanguageRTLKey];
        language.flagUrl = [NSURL URLWithString:info[TMLAPIResponseLanguageFlagURLKey]];
        language.status = info[TMLAPIResponseLanguageStatusKey];
        [languages addObject:language];
    }
    return languages;
}

@end
