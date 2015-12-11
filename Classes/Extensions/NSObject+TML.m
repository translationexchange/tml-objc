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

#import "NSObject+TML.h"
#import "TML.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLTranslationKey.h"
#import <objc/runtime.h>

NSString * const TMLRegistryTranslationKeyName = @"translationKey";
NSString * const TMLRegistryTokensKeyName = @"tokens";
NSString * const TMLRegistryOptionsKeyName = @"options";

@implementation NSObject (TML)

+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(awakeFromNib));
    Method ours = class_getInstanceMethod(self, @selector(tmlAwakeFromNib));
    method_exchangeImplementations(original, ours);
    
    original = class_getInstanceMethod(self, @selector(valueForKeyPath:));
    ours = class_getInstanceMethod(self, @selector(tmlValueForKeyPath:));
    method_exchangeImplementations(original, ours);
    
    original = class_getInstanceMethod(self, @selector(setValue:forKeyPath:));
    ours = class_getInstanceMethod(self, @selector(tmlSetValue:forKeyPath:));
    method_exchangeImplementations(original, ours);
}

- (void) localizeWithTML {
    // Subclasses should handle this
}

- (void)tmlAwakeFromNib {
    [self tmlAwakeFromNib];
    if ([[TML sharedInstance] configuration].localizeNIBStrings == YES) {
        NSString *accessibilityLabel = self.accessibilityLabel;
        if (accessibilityLabel != nil) {
            self.accessibilityLabel = TMLLocalizedString(accessibilityLabel, @"accessibilityLabel");
        }
        [self localizeWithTML];
    }
}

- (id)tmlValueForKeyPath:(NSString *)keyPath {
    return [self tmlValueForKeyPath:keyPath];
}

- (void)tmlSetValue:(id)value forKeyPath:(NSString *)keyPath {
    [self tmlSetValue:value forKeyPath:keyPath];
}


- (NSMutableDictionary *)tmlRegistry {
    NSMutableDictionary *registry = objc_getAssociatedObject(self, @"_tmlRegistry");
    if (registry == nil) {
        registry = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @"_tmlRegistry", registry, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return registry;
}

- (void)registerTMLTranslationKey:(TMLTranslationKey *)translationKey
                           tokens:(NSDictionary *)tokens
                          options:(NSDictionary *)options
                   restorationKey:(NSString *)restorationKey
{
    NSMutableDictionary *registry = [self tmlRegistry];
    
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[TMLRegistryTranslationKeyName] = translationKey;
    if (tokens != nil) {
        payload[TMLRegistryTokensKeyName] = tokens;
    }
    if (options != nil) {
        payload[TMLRegistryOptionsKeyName] = options;
    }
    
    registry[restorationKey] = payload;
}

- (void)restoreTMLLocalizations {
    NSMutableDictionary *registry = [self tmlRegistry];
    for (NSString *restorationKey in registry) {
        NSDictionary *payload = registry[restorationKey];
        if (payload == nil) {
            continue;
        }
        TMLTranslationKey *translationKey = payload[TMLRegistryTranslationKeyName];
        if (translationKey == nil) {
            continue;
        }
        NSDictionary *tokens = payload[TMLRegistryTokensKeyName];
        NSDictionary *options = payload[TMLRegistryOptionsKeyName];
        id result = [[[TML sharedInstance] currentLanguage] translate:translationKey.label
                                                          description:translationKey.keyDescription
                                                               tokens:tokens
                                                              options:options];
        @try {
            [self setValue:result forKeyPath:restorationKey];
        }
        @catch (NSException *exception) {
            TMLError(@"Error restoring translation key: '%@' with restorationKey: '%@': %@", translationKey.key, restorationKey, exception);
        }
    }
}

@end
