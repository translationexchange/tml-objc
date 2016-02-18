/*
 *  Copyright (c) 2015 Translation Exchange, Inc. All rights reserved.
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

#import "NSAttributedString+TML.h"
#import "NSObject+TML.h"
#import "TML.h"
#import "TMLAttributedDecorationTokenizer.h"
#import "TMLBundle.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLTranslationKey.h"
#import <objc/runtime.h>

const NSString * TMLLocalizedStringsRegistryKey = @"TMLLocalizedStringsRegistryKey";
const NSString * TMLReusableLocalizedStringsRegistryKey = @"TMLReusableLocalizedStringsRegistryKey";

void ensureArrayIndex(NSMutableArray *array, NSInteger index) {
    if (array.count > index) {
        return;
    }
    for (NSInteger i=array.count; i<=index; i++) {
        [array setObject:[NSNull null] atIndexedSubscript:i];
    }
}

@interface NSObject() <TMLReusableLocalization>
@end

@implementation NSObject (TML)

+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(awakeFromNib));
    Method ours = class_getInstanceMethod(self, @selector(tmlAwakeFromNib));
    method_exchangeImplementations(original, ours);
}

- (void)tmlAwakeFromNib {
    [self tmlAwakeFromNib];
    if ([[TML sharedInstance] configuration].localizeNIBStrings == YES) {
        [self localizeWithTML];
    }
}

#pragma mark - Automatic Localization Support

- (NSSet *)tmlLocalizableKeyPaths {
    return nil;
}

/**
 *  Special case for handling table section objects we'd get from NIBs...
 *  We handle them because they contain strings that will be used to populate labels at a later stage
 */
- (void) localizeTableSectionsWithTML {
    NSSet *keyPaths = [NSSet setWithArray:@[@"headerTitle", @"footerTitle"]];
    for (NSString *keyPath in keyPaths) {
        NSString *newValue = [[self valueForKeyPath:keyPath] uppercaseString];
        if (newValue == nil) {
            continue;
        }
        NSString *localizedString = TMLLocalizedString(newValue);
        [self setValue:localizedString forKeyPath:keyPath];
        NSMutableDictionary *reuseInfo = [NSMutableDictionary dictionary];
        reuseInfo[TMLLocalizedStringInfoKey] = localizedString;
        TMLTranslationKey *translationKey = [[TMLTranslationKey alloc] initWithLabel:newValue description:nil];
        translationKey.locale = TMLDefaultLocale();
        reuseInfo[TMLTranslationKeyInfoKey] = translationKey;
        [self registerTMLInfo:reuseInfo forReuseIdentifier:keyPath];
    }
}

- (void) localizeWithTML {
    NSString *classString = NSStringFromClass(self.class);
    if ([classString hasSuffix:@"UITableViewSection"] == YES) {
        [self localizeTableSectionsWithTML];
        return;
    }
    else if ([classString hasSuffix:@"UITableView"] == YES) {
        [[TML sharedInstance] registerObjectWithReusableLocalizedStrings:self];
    }
    
    NSSet *keyPaths = [self tmlLocalizableKeyPaths];
    for (NSString *keyPath in keyPaths) {
        id localizableString = nil;
        @try {
            localizableString = [self valueForKey:keyPath];
        }
        @catch (NSException *e) {
            TMLDebug(@"Could not get value for keyPath '%@': %@", keyPath, e);
        }
        
        NSMutableDictionary *reuseInfo = nil;
        if ([localizableString isKindOfClass:[NSAttributedString class]] == YES) {
            NSDictionary *tokens = nil;
            NSAttributedString *attributedString = (NSAttributedString *)localizableString;
            localizableString = [attributedString tmlAttributedString:&tokens];
            NSAttributedString *localizedString = TMLLocalizedAttributedString(localizableString, tokens);
            [self setValue:localizedString forKey:keyPath];
            
            reuseInfo = [NSMutableDictionary dictionary];
            reuseInfo[TMLLocalizedStringInfoKey] = localizedString;
            TMLTranslationKey *translationKey = [[TMLTranslationKey alloc] initWithLabel:localizableString description:nil];
            translationKey.locale = TMLDefaultLocale();
            reuseInfo[TMLTranslationKeyInfoKey] = translationKey;
            if (tokens != nil) {
                reuseInfo[TMLTokensInfoKey] = tokens;
            }
            NSDictionary *options = @{TMLTokenFormatOptionName: TMLAttributedTokenFormatString};
            reuseInfo[TMLOptionsInfoKey] = options;
        }
        else if ([localizableString isKindOfClass:[NSString class]] == YES) {
            NSString *localizedString = TMLLocalizedString(localizableString);
            [self setValue:localizedString forKey:keyPath];
            reuseInfo = [NSMutableDictionary dictionary];
            reuseInfo[TMLLocalizedStringInfoKey] = localizedString;
            TMLTranslationKey *translationKey = [[TMLTranslationKey alloc] initWithLabel:localizableString description:nil];
            translationKey.locale = TMLDefaultLocale();
            reuseInfo[TMLTranslationKeyInfoKey] = translationKey;
        }
        
        if (reuseInfo != nil) {
            [self registerTMLInfo:reuseInfo forReuseIdentifier:keyPath];
        }
    }
}

- (void)generateTMLLocalizationRegistry {
    NSSet *localizableKeyPaths = [self tmlLocalizableKeyPaths];
    for (NSString *keyPath in localizableKeyPaths) {
        id value = nil;
        @try {
            value = [self valueForKeyPath:keyPath];
        }
        @catch(NSException *e) {
            TMLError(@"Exception getting value for keyPath '%@': %@", keyPath, e);
        }
        NSString *tmlString = nil;
        NSDictionary *tokens = nil;
        if ([value isKindOfClass:[NSAttributedString class]] == YES) {
            tmlString = [(NSAttributedString *)value tmlAttributedString:&tokens];
        }
        else if ([value isKindOfClass:[NSString class]] == YES) {
            tmlString = value;
        }
        TMLTranslationKey *translationKey = nil;
        TML *tml = [TML sharedInstance];
        NSDictionary *allTranslationKeys = [tml.currentBundle translationKeys];
        NSSet *allLocales = [NSSet setWithArray:@[[tml currentLocale], [tml previousLocale], [tml defaultLocale]]];
        if (tmlString != nil && allTranslationKeys.count > 0) {
            NSArray *matchingKeys = nil;
            for (NSString *locale in allLocales) {
                matchingKeys = [tml translationKeysMatchingString:tmlString locale:locale];
                if (matchingKeys.count > 0) {
                    break;
                }
            }
            for (NSString *key in matchingKeys) {
                TMLTranslationKey *candidateKey = allTranslationKeys[key];
                if (candidateKey != nil) {
                    translationKey = candidateKey;
                    break;
                }
            }
        }
        if (translationKey != nil) {
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            info[TMLTranslationKeyInfoKey] = translationKey;
            if (tokens != nil) {
                info[TMLTokensInfoKey] = tokens;
            }
            [self registerTMLInfo:info forReuseIdentifier:keyPath];
        }
    }
}

#pragma mark - Localization Reuse

- (NSMutableDictionary *)tmlRegistry {
    NSMutableDictionary *registry = objc_getAssociatedObject(self, @"_tmlRegistry");
    if (registry == nil) {
        registry = [NSMutableDictionary dictionary];
        registry[TMLLocalizedStringsRegistryKey] = [NSMutableDictionary dictionary];
        registry[TMLReusableLocalizedStringsRegistryKey] = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @"_tmlRegistry", registry, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return registry;
}

- (void)registerTMLTranslationKey:(TMLTranslationKey *)translationKey forLocalizedString:(id)string {
    NSMutableDictionary *registry = [self tmlRegistry][TMLLocalizedStringsRegistryKey];
    if (string == nil) {
        [registry removeObjectForKey:string];
    }
    else {
        registry[string] = translationKey;
    }
    [[TML sharedInstance] registerObjectWithLocalizedStrings:self];
}

- (TMLTranslationKey *)registeredTranslationKeyForLocalizedString:(id)string {
    NSMutableDictionary *registry = [self tmlRegistry][TMLLocalizedStringsRegistryKey];
    return registry[string];
}

- (void)registerTMLInfo:(NSDictionary *)info forReuseIdentifier:(NSString *)reuseIdentifier {
    NSMutableDictionary *registry = [self tmlRegistry][TMLReusableLocalizedStringsRegistryKey];
    if (info == nil) {
        [registry removeObjectForKey:reuseIdentifier];
    }
    else {
        registry[reuseIdentifier] = info;
    }
    [[TML sharedInstance] registerObjectWithReusableLocalizedStrings:self];
}

- (BOOL)hasTMLInfoForReuseIdentifier:(NSString *)reuseIdentifier {
    return [self tmlInfoForReuseIdentifier:reuseIdentifier] != nil;
}

- (NSDictionary *)tmlInfoForReuseIdentifier:(NSString *)reuseIdentifier {
    NSMutableDictionary *registry = [self tmlRegistry][TMLReusableLocalizedStringsRegistryKey];
    return registry[reuseIdentifier];
}

- (void)updateReusableTMLStrings {
    // TODO: this should probably be getting set elsewhere
    self.accessibilityLanguage = TMLCurrentLocale();
    
    NSMutableDictionary *registry = [self tmlRegistry][TMLReusableLocalizedStringsRegistryKey];
    for (NSString *reuseIdentifier in registry) {
        NSMutableDictionary *info = [registry[reuseIdentifier] mutableCopy];
        if (info == nil) {
            continue;
        }
        
        TMLTranslationKey *translationKey = info[TMLTranslationKeyInfoKey];
        if (translationKey == nil
            || translationKey.label == nil) {
            continue;
        }
        
        TMLSource *source = info[TMLSourceInfoKey];
        NSDictionary *tokens = info[TMLTokensInfoKey];
        NSDictionary *options = info[TMLOptionsInfoKey];
        id result = [[[TML sharedInstance] currentLanguage] translateKey:translationKey
                                                                  source:source
                                                                  tokens:tokens
                                                                 options:options];
        
        if (!result) {
            continue;
        }
        
        // sanity check for return type
        NSString *tokenFormat = options[TMLTokenFormatOptionName];
        if ([tokenFormat isEqualToString:TMLAttributedTokenFormatString] == YES
            && [result isKindOfClass:[NSString class]] == YES) {
            TMLWarn(@"Expected attributed string, but got regular string");
            if (tokens != nil) {
                TMLAttributedDecorationTokenizer *tokenizer = [[TMLAttributedDecorationTokenizer alloc] initWithLabel:result andAllowedTokenNames:[tokens allKeys]];
                result = [tokenizer substituteTokensInLabelUsingData:tokens];
            }
        }
        else if (tokenFormat == nil && [result isKindOfClass:[NSAttributedString class]] == YES) {
            result = [(NSAttributedString *)result string];
        }
        
        info[TMLLocalizedStringInfoKey] = result;
        [self updateTMLLocalizedStringWithInfo:info forReuseIdentifier:reuseIdentifier];
    }
}

- (void)updateTMLLocalizedStringWithInfo:(NSDictionary *)info
                   forReuseIdentifier:(NSString *)reuseIdentifier
{
    id currentValue = nil;
    @try {
        currentValue = [self valueForKeyPath:reuseIdentifier];
    }
    @catch (NSException *e){
        TMLDebug(@"Cannot automatically update property %@.%@. Cannot retrieve current value: %@", NSStringFromClass([self class]), reuseIdentifier, e);
        return;
    }
    
    id newValue = info[TMLLocalizedStringInfoKey];
    if (newValue != nil) {
        @try {
            [self setValue:newValue forKeyPath:reuseIdentifier];
        }
        @catch (NSException *e) {
            TMLDebug(@"Cannot automatically update property %@.%@. Cannot set new value: %@", NSStringFromClass([self class]), reuseIdentifier, e);
        }
    }
}

@end
