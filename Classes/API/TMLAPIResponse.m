//
//  TMLAPIResponse.m
//  Demo
//
//  Created by Pasha on 11/5/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSObject+tmlJSON.h"
#import "TMLAPIResponse.h"
#import "TMLAPISerializer.h"
#import "TMLLanguage.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"

NSString * const TMLAPIResponseErrorDomain = @"TMLAPIResponseErrorDomain";

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
NSString * const TMLAPIResponseResultsLanguagesKey = @"languages";
NSString * const TMLAPIResponseResultsTranslationKeysKey = @"languages";

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

NSString * const TMLAPIResponseStatusKey = @"status";
NSString * const TMLAPIResponseStatusOK = @"ok";
NSString * const TMLAPIResponseStatusError = @"error";

NSString * const TMLAPIResponseTranslatorKey = @"translator";

NSString * const TMLAPIResponseErrorDescriptionKey = @"error";
NSString * const TMLAPIResponseErrorCodeKey = @"code";

@interface TMLAPIResponse()
@property (readwrite, nonatomic) NSDictionary *userInfo;
@end

@implementation TMLAPIResponse

#pragma mark - Init

- (instancetype)initWithData:(NSData *)data {
    if (self = [super init]) {
        NSDictionary *userInfo = [data tmlJSONObject];
        self.userInfo = (NSDictionary *)userInfo;
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    TMLAPIResponse *copy = [[TMLAPIResponse alloc] init];
    copy.userInfo = self.userInfo;
    return copy;
}

#pragma mark - Results
- (id)results {
    return self.userInfo[TMLAPIResponseResultsKey];
}

- (NSDictionary *)resultsAsTranslations {
    id results = self.results;
    if (results == nil) {
        results = self.userInfo[TMLAPIResponseResultsTranslationsKey];
    }
    
    if ([results isKindOfClass:[NSDictionary class]] == NO) {
        return nil;
    }

    NSMutableDictionary *translations = [NSMutableDictionary dictionary];
    for (NSString *hash in (NSDictionary *)results) {
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

- (NSArray *)resultsAsLanguages {
    id results = self.results;
    if (results == nil) {
        results = self.userInfo[TMLAPIResponseResultsLanguagesKey];
    }
    
    if ([results isKindOfClass:[NSArray class]] == NO) {
        return nil;
    }
    
    NSMutableArray *languages = [NSMutableArray array];
    for (NSDictionary *info in (NSArray *)results) {
        TMLLanguage *language = [[TMLLanguage alloc] init];
        language.languageID = [info[TMLAPIResponseLanguageIDKey] integerValue];
        language.locale = info[TMLAPIResponseLanguageLocaleKey];
        language.englishName = info[TMLAPIResponseLanguageEnglishNameKey];
        language.nativeName = info[TMLAPIResponseLanguageNativeNameKey];
        language.rightToLeft = [info[TMLAPIResponseLanguageRTLKey] boolValue];
        language.flagUrl = [NSURL URLWithString:info[TMLAPIResponseLanguageFlagURLKey]];
        language.status = info[TMLAPIResponseLanguageStatusKey];
        [languages addObject:language];
    }
    return languages;
}

- (NSArray *)resultsAsTranslationKeys {
    id results = self.results;
    if (results == nil) {
        results = self.userInfo[TMLAPIResponseResultsTranslationKeysKey];
    }
    else {
        results = [TMLAPISerializer materializeObject:results withClass:[TMLTranslationKey class]];
    }
    if ([results isKindOfClass:[NSArray class]] == NO) {
        return nil;
    }
    return results;
}

#pragma mark - Pagination

- (NSDictionary *)paginationInfo {
    return self.userInfo[TMLAPIResponsePaginationKey];
}

- (BOOL)isPaginated {
    NSDictionary *paginationInfo = [self paginationInfo];
    if (paginationInfo != nil && [paginationInfo[TMLAPIResponseTotalPagesKey] integerValue] > 1) {
        return YES;
    }
    return NO;
}

- (NSInteger)currentPage {
    NSDictionary *paginationInfo = [self paginationInfo];
    return [paginationInfo[TMLAPIResponseCurrentPageKey] integerValue];
}

- (NSInteger)totalPages {
    NSDictionary *paginationInfo = [self paginationInfo];
    return [paginationInfo[TMLAPIResponseTotalPagesKey] integerValue];
}

- (NSInteger)resultsPerPage {
    NSDictionary *paginationInfo = [self paginationInfo];
    return [paginationInfo[TMLAPIResponseResultsPerPageKey] integerValue];
}

- (NSInteger)totalResults {
    NSDictionary *paginationInfo = [self paginationInfo];
    return [paginationInfo[TMLAPIResponseTotalResultsKey] integerValue];
}

#pragma mark - Status

- (NSString *)status {
    id status = self.userInfo[TMLAPIResponseStatusKey];
    if ([[NSNull null] isEqual:status] == YES) {
        status = nil;
    }
    if (status != nil && [status isKindOfClass:[NSString class]] == NO) {
        status = [NSString stringWithFormat:@"%@", status];
    }
    return status;
}

- (BOOL)isSuccessfulResponse {
    // if we spot results in the response - we can assume - it's a successful response
    id results = self.results;
    if (results != nil) {
        return YES;
    }
    
    // not all responses contain results, some may contain arbitrary data, but some will contain "status"
    NSString *status = [self.status lowercaseString];
    if (status != nil) {
        return [status isEqualToString:TMLAPIResponseStatusOK];
    }
    
    return self.userInfo != nil;
}

#pragma mark - Merging

- (TMLAPIResponse *)responseByMergingWithResponse:(TMLAPIResponse *)response {
    if (response == nil) {
        return self;
    }
    id results = self.results;
    id responseResults = response.results;
    id newResults = nil;
    if ([results isKindOfClass:[NSArray class]] == YES
        && [responseResults isKindOfClass:[NSArray class]] == YES) {
        NSMutableArray *newArray = [(NSArray *)results mutableCopy];
        [newArray addObjectsFromArray:responseResults];
        newResults = [newArray copy];
    }
    else if ([results isKindOfClass:[NSDictionary class]] == YES
             && [responseResults isKindOfClass:[NSDictionary class]] == YES) {
        NSMutableDictionary *newDict = [(NSDictionary *)results mutableCopy];
        for (id key in responseResults) {
            newDict[key] = responseResults[key];
        }
        newResults = [newDict copy];
    }
    else if (results == nil && responseResults != nil) {
        newResults = responseResults;
    }
    else if (responseResults == nil && results != nil) {
        newResults = results;
    }
    
    TMLAPIResponse *copy = [self copy];
    if (newResults != nil) {
        copy.userInfo = @{TMLAPIResponseResultsKey: newResults};
    }
    return copy;
}

#pragma mark - Errors
- (NSError *)error {
    NSString *status = self.status;
    NSError *anError = nil;
    if ([status isEqualToString:TMLAPIResponseStatusError] == YES) {
        NSDictionary *userInfo = self.userInfo;
        NSInteger code = [userInfo[TMLAPIResponseErrorCodeKey] integerValue];
        NSString *description = userInfo[TMLAPIResponseErrorDescriptionKey];
        anError = [NSError errorWithDomain:TMLAPIResponseErrorDomain
                                      code:code
                                  userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    return anError;
}

@end
