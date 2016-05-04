//
//  TMLUser.m
//  TMLKit
//
//  Created by Pasha on 5/4/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TMLUser.h"
#import "TMLTranslator.h"

NSString * const TMLUserGenderKey = @"gender";
NSString * const TMLUserLocaleKey = @"locale";
NSString * const TMLUserRoleKey = @"role";
NSString * const TMLUserTranslatorKey = @"translator";

@implementation TMLUser

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.gender forKey:TMLUserGenderKey];
    [aCoder encodeObject:self.locale forKey:TMLUserLocaleKey];
    [aCoder encodeObject:self.role forKey:TMLUserRoleKey];
    [aCoder encodeObject:self.translator forKey:TMLUserTranslatorKey];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    [super decodeWithCoder:aDecoder];
    self.gender = [aDecoder decodeObjectForKey:TMLUserGenderKey];
    self.locale = [aDecoder decodeObjectForKey:TMLUserLocaleKey];
    id translator = [aDecoder decodeObjectForKey:TMLUserTranslatorKey];
    if (translator != nil && [translator isKindOfClass:[TMLTranslator class]] == NO) {
        translator = [TMLAPISerializer materializeObject:translator withClass:[TMLTranslator class]];
    }
    self.translator = translator;
}

@end
