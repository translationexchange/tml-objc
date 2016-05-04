//
//  TMLAPIResponse.h
//  Demo
//
//  Created by Pasha on 11/5/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TMLAPIResponseErrorDomain;

extern NSString * const TMLAPIResponsePaginationKey;
extern NSString * const TMLAPIResponseCurrentPageKey;
extern NSString * const TMLAPIResponseResultsPerPageKey;
extern NSString * const TMLAPIResponseTotalResultsKey;
extern NSString * const TMLAPIResponseTotalPagesKey;
extern NSString * const TMLAPIResponsePageLinksKey;
extern NSString * const TMLAPIResponseFirstPageLinkKey;
extern NSString * const TMLAPIResponseLastPageLinkKey;
extern NSString * const TMLAPIResponseNextPageLinkKey;
extern NSString * const TMLAPIResponseCurrentPageLinkKey;

extern NSString * const TMLAPIResponseResultsKey;
extern NSString * const TMLAPIResponseResultsTranslationsKey;
extern NSString * const TMLAPIResponseResultsLanguagesKey;
extern NSString * const TMLAPIResponseResultsTranslationKeysKey;

extern NSString * const TMLAPIResponseTranslationLabelKey;
extern NSString * const TMLAPIResponseTranslationLocaleKey;
extern NSString * const TMLAPIResponseTranslationContextKey;

extern NSString * const TMLAPIResponseLanguageEnglishNameKey;
extern NSString * const TMLAPIResponseLanguageFlagURLKey;
extern NSString * const TMLAPIResponseLanguageIDKey;
extern NSString * const TMLAPIResponseLanguageLocaleKey;
extern NSString * const TMLAPIResponseLanguageNativeNameKey;
extern NSString * const TMLAPIResponseLanguageRTLKey;
extern NSString * const TMLAPIResponseLanguageStatusKey;

extern NSString * const TMLAPIResponseStatusKey;
extern NSString * const TMLAPIResponseStatusOK;
extern NSString * const TMLAPIResponseStatusError;

extern NSString * const TMLAPIResponseTranslatorKey;

extern NSString * const TMLAPIResponseErrorDescriptionKey;
extern NSString * const TMLAPIResponseErrorCodeKey;

@class TMLTranslation, TMLLanguage;

@interface TMLAPIResponse : NSObject <NSCopying>

#pragma mark - Init

- (instancetype) initWithData:(NSData *)data;

#pragma mark - Results
@property (readonly, nonatomic) NSDictionary *userInfo;
@property (readonly, nonatomic) id results;
- (NSDictionary *) resultsAsTranslations;
- (NSArray *) resultsAsLanguages;
- (NSArray *)resultsAsTranslationKeys;

#pragma mark - Pagination
@property (readonly, nonatomic, getter=isPaginated) BOOL paginated;
@property (readonly, nonatomic) NSInteger currentPage;
@property (readonly, nonatomic) NSInteger totalPages;
@property (readonly, nonatomic) NSInteger resultsPerPage;
@property (readonly, nonatomic) NSInteger totalResults;

#pragma mark - Status
@property (readonly, nonatomic) NSString *status;
@property (readonly, nonatomic, getter=isSuccessfulResponse) BOOL successfulResponse;

#pragma mark - Merging
- (TMLAPIResponse *)responseByMergingWithResponse:(TMLAPIResponse *)response;

#pragma mark - Errors
@property (readonly, nonatomic) NSError *error;

@end
