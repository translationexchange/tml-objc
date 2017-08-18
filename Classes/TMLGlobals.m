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

#import "TMLGlobals.h"

NSString * const TMLAbstractInvocationException = @"TMLAbstractInvocation";

void TMLAbstractInvocation(SEL selector,id object) {
    [NSException raise:TMLAbstractInvocationException
                format:@"[%@ %@] forwards to an abstract invocation",
     NSStringFromClass([object class]),
     NSStringFromSelector(selector)
     ];
}

NSString * const TMLNotYetImplementedException = @"TMLNotYetImplemented";

void TMLNotYetImplemented(SEL selector, id object) {
    [NSException raise:TMLNotYetImplementedException
                format:@"[%@ %@] Is not yet implemented",
     NSStringFromClass([object class]),
     NSStringFromSelector(selector)];
}

NSString * const TMLAlternativeInstantiationException = @"TMLAlternativeInstantiation";
void TMLUseAlternativeInstantiationMethod(SEL selector, id object) {
    [NSException raise:TMLAlternativeInstantiationException
                format:@"Use -[%@ %@] instantiation method",
     [object class],
     NSStringFromSelector(selector)
     ];
}


#pragma mark - Notification Constants
NSString * const TMLLanguageChangedNotification = @"TMLLanguageChangedNotification";
NSString * const TMLLocalizationDataChangedNotification = @"TMLLocalizationDataChangedNotification";
NSString * const TMLDidStartSyncNotification = @"TMLDidStartSyncNotification";
NSString * const TMLDidFinishSyncNotification = @"TMLDidFinishSyncNotification";
NSString * const TMLLocalizationUpdatesInstalledNotification = @"TMLLocalizationUpdatesInstalledNotification";
NSString * const TMLLocalizationUpdatesFailedNotification = @"TMLLocalizationUpdatesFailedNotification";

#pragma mark - UserInfo Constants
NSString * const TMLPreviousLocaleUserInfoKey = @"TMLPreviousLocaleUserInfoKey";
NSString * const TMLTokensInfoKey = @"tokens";
NSString * const TMLOptionsInfoKey = @"options";
NSString * const TMLTranslationKeyInfoKey = @"translationKey";
NSString * const TMLSourceInfoKey = @"source";
NSString * const TMLLocalizedStringInfoKey = @"localizedString";

#pragma mark - Options
NSString * const TMLSourceOptionName = @"source";
NSString * const TMLLocaleOptionName = @"locale";
NSString * const TMLLevelOptionName = @"level";
NSString * const TMLTokenFormatOptionName = @"tokenFormat";
NSString * const TMLReuseIdentifierOptionName = @"reuseIdentifier";
NSString * const TMLSenderOptionName = @"sender";

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
