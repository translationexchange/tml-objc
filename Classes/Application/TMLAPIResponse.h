//
//  TMLAPIResponse.h
//  Demo
//
//  Created by Pasha on 11/5/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMLTranslation, TMLLanguage;

@interface TMLAPIResponse : NSObject

#pragma mark - Init

- (instancetype) initFromResponseResultObject:(id)resultObject;

#pragma mark - Results
@property (readonly, nonatomic) NSDictionary *userInfo;
@property (readonly, nonatomic) id results;

- (NSDictionary<NSString *,TMLTranslation *>*) resultsAsTranslations;
- (NSArray<TMLLanguage *>*) resultsAsLanguages;

@end
