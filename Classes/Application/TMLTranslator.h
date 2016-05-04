//
//  TMLTranslatorUser.h
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMLBasicUser.h"

extern NSString * const TMLTranslatorIDKey;
extern NSString * const TMLTranslatorUserIDKey;
extern NSString * const TMLTranslatorLevelKey;
extern NSString * const TMLTranslatorRankKey;
extern NSString * const TMLTranslatorVotingPowerKey;

@interface TMLTranslator : TMLBasicUser

@property (assign, nonatomic) NSInteger translatorID;

@property (assign, nonatomic) NSInteger level;
@property (assign, nonatomic) NSInteger rank;
@property (assign, nonatomic) NSInteger votingPower;

- (BOOL)isEqualToTranslator:(TMLTranslator *)translator;

@end
