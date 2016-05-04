//
//  TMLTranslatorUser.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TMLTranslator.h"

NSString * const TMLTranslatorIDKey = @"id";
NSString * const TMLTranslatorUserIDKey = @"user_id";
NSString * const TMLTranslatorLevelKey = @"level";
NSString * const TMLTranslatorRankKey = @"rank";
NSString * const TMLTranslatorVotingPowerKey = @"voting_power";

@implementation TMLTranslator

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeInteger:self.translatorID forKey:TMLTranslatorIDKey];
    [aCoder encodeInteger:self.userID forKey:TMLTranslatorUserIDKey];
    
    [aCoder encodeInteger:self.level forKey:TMLTranslatorLevelKey];
    [aCoder encodeInteger:self.rank forKey:TMLTranslatorRankKey];
    [aCoder encodeInteger:self.votingPower forKey:TMLTranslatorVotingPowerKey];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    [super decodeWithCoder:aDecoder];
    
    self.translatorID = [aDecoder decodeIntegerForKey:TMLTranslatorIDKey];
    self.userID = [aDecoder decodeIntegerForKey:TMLTranslatorUserIDKey];
    
    self.level = [aDecoder decodeObjectForKey:TMLTranslatorLevelKey];
    self.rank = [aDecoder decodeObjectForKey:TMLTranslatorRankKey];
    self.votingPower = [aDecoder decodeIntegerForKey:TMLTranslatorVotingPowerKey];
}

@end
