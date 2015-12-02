//
//  TMLGlobals.m
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TMLGlobals.h"

void TMLAbstractInvocation(SEL selector,id object) {
    [NSException raise:NSInvalidArgumentException
                format:@"[%@ %@] forwards to an abstract invocation",
     NSStringFromClass([object class]),
     NSStringFromSelector(selector)
     ];
}


#pragma mark - Notification Constants
NSString * const TMLLanguageChangedNotification = @"TMLLanguageChangedNotification";
NSString * const TMLLocalizationDataChangedNotification = @"TMLLocalizationDataChangedNotification";
NSString * const TMLDidStartSyncNotification = @"TMLDidStartSyncNotification";
NSString * const TMLDidFinishSyncNotification = @"TMLDidFinishSyncNotification";
NSString * const TMLLocalizationUpdatesInstalledNotification = @"TMLLocalizationUpdatesInstalledNotification";

#pragma mark - UserInfo Constants
NSString * const TMLPreviousLocaleUserInfoKey = @"TMLPreviousLocaleUserInfoKey";

#pragma mark - Options
NSString * const TMLSourceOptionName = @"source";
NSString * const TMLLocaleOptionName = @"locale";
NSString * const TMLLevelOptionName = @"level";
NSString * const TMLTokenFormatOptionName = @"tokenFormat";

#pragma mark - Tokens
NSString * const TMLViewingUserTokenName = @"viewing_user";

NSString * const TMLDataTokenTypeString = @"data";
NSString * const TMLDecorationTokenTypeString = @"decoration";
NSString * const TMLHTMLTokenFormatString = @"html";
NSString * const TMLAttributedTokenFormatString = @"attributed";

NSString * NSStringFromTokenType(TMLTokenType type) {
    if (type == TMLDecorationTokenType) {
        return TMLDecorationTokenTypeString;
    }
    return TMLDataTokenTypeString;
}

NSString * NSStringFromTokenFormat(TMLTokenFormat format) {
    if (format == TMLAttributedTokenFormat) {
        return TMLAttributedTokenFormatString;
    }
    return TMLHTMLTokenFormatString;
}