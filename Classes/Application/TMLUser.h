//
//  TMLUser.h
//  TMLKit
//
//  Created by Pasha on 5/4/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <TMLKit/TMLKit.h>
#import "TMLBasicUser.h"

extern NSString * const TMLUserGenderKey;
extern NSString * const TMLUserLocaleKey;
extern NSString * const TMLUserRoleKey;
extern NSString * const TMLUserTranslatorKey;

@class TMLTranslator;

@interface TMLUser : TMLBasicUser
@property (strong, nonatomic) NSString *gender;
@property (strong, nonatomic) NSString *locale;
@property (strong, nonatomic) NSString *role;
@property (strong, nonatomic) TMLTranslator *translator;
@end
