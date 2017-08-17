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
- (NSDictionary *)resultsAsTranslationKeys;

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
