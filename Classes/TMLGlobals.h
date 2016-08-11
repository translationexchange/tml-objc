//
//  TMLGlobals.h
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TMLBundleIdentifier @"com.translationexchange.TMLKit"

#define TMLRaiseAbstractInvocation() TMLAbstractInvocation(_cmd, self)
#define TMLRaiseAlternativeInstantiationMethod(selector) TMLUseAlternativeInstantiationMethod(selector, self);
#define TMLRaiseUnconfiguredIncovation() TMLUnconfiguredIncovation(_cmd, self)
#define TMLRaiseAlreadyConfigured() TMLAlreadyConfigured(_cmd, self)
#define TMLIsNilNull(arg) (arg == nil || [[NSNull null] isEqual: arg]) 

void TMLAbstractInvocation(SEL selector,id object);
void TMLUseAlternativeInstantiationMethod(SEL selector, id object);
void TMLUnconfiguredIncovation(SEL selector, id object);
void TMLAlreadyConfigured(SEL selector, id object);

#pragma mark - Notifications
extern NSString * const TMLLanguageChangedNotification;
extern NSString * const TMLLocalizationDataChangedNotification;
extern NSString * const TMLDidStartSyncNotification;
extern NSString * const TMLDidFinishSyncNotification;
extern NSString * const TMLLocalizationUpdatesInstalledNotification;
extern NSString * const TMLLocalizationUpdatesFailedNotification;

#pragma mark - UserInfo Keys
extern NSString * const TMLPreviousLocaleUserInfoKey;
extern NSString * const TMLTokensInfoKey;
extern NSString * const TMLOptionsInfoKey;
extern NSString * const TMLTranslationKeyInfoKey;
extern NSString * const TMLSourceInfoKey;
extern NSString * const TMLLocalizedStringInfoKey;

#pragma mark - Options
extern NSString * const TMLSourceOptionName;
extern NSString * const TMLLocaleOptionName;
extern NSString * const TMLLevelOptionName;
extern NSString * const TMLTokenFormatOptionName;
extern NSString * const TMLReuseIdentifierOptionName;
extern NSString * const TMLSenderOptionName;

#pragma mark - Tokens
extern NSString * const TMLViewingUserTokenName;

extern NSString * const TMLDataTokenTypeString;
extern NSString * const TMLDecorationTokenTypeString;
extern NSString * const TMLHTMLTokenFormatString;
extern NSString * const TMLAttributedTokenFormatString;


typedef NS_ENUM(NSInteger, TMLTokenType) {
    TMLDataTokenType = 1,
    TMLDecorationTokenType
};

typedef NS_ENUM(NSInteger, TMLTokenFormat) {
    TMLHTMLTokenFormat = 1,
    TMLAttributedTokenFormat
};

NSString * NSStringFromTokenType(TMLTokenType type);
NSString * NSStringFromTokenFormat(TMLTokenFormat format);