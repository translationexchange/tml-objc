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
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLTranslationKey.h"
#import <objc/runtime.h>

NSString * const TMLRegistryTranslationKeyName = @"translationKey";
NSString * const TMLRegistryTokensKeyName = @"tokens";
NSString * const TMLRegistryOptionsKeyName = @"options";

void ensureArrayIndex(NSMutableArray *array, NSInteger index) {
    if (array.count > index) {
        return;
    }
    for (NSInteger i=array.count; i<=index; i++) {
        [array setObject:[NSNull null] atIndexedSubscript:i];
    }
}

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

- (NSArray *)tmlLocalizedKeyPaths {
    return @[@"accessibilityLabel", @"accessibilityHint", @"accessibilityValue"];
}

- (void) localizeWithTML {
    NSArray *keyPaths = [self tmlLocalizedKeyPaths];
    for (id keyPath in keyPaths) {
        id localizableString = nil;
        @try {
            localizableString = [self valueForKey:keyPath];
        }
        @catch (NSException *e) {
            TMLDebug(@"Could not get value for keyPath '%@': %@", keyPath, e);
        }
        
        if ([localizableString isKindOfClass:[NSAttributedString class]] == YES) {
            NSDictionary *tokens = nil;
            NSString *tmlAttributedString = [localizableString tmlAttributedString:&tokens];
            [self setValue:TMLLocalizedAttributedString(tmlAttributedString, tokens, keyPath) forKey:keyPath];
        }
        else if ([localizableString isKindOfClass:[NSString class]] == YES) {
            [self setValue:TMLLocalizedString(localizableString, keyPath) forKey:keyPath];
        }
    }
}

- (void)tmlAwakeFromNib {
    [self tmlAwakeFromNib];
    if ([[TML sharedInstance] configuration].localizeNIBStrings == YES) {
        [self localizeWithTML];
    }
}

- (id)tmlValueForKeyPath:(NSString *)keyPath {
    if ([TML sharedInstance].configuration.allowCollectionKeyPaths == NO) {
        return [self tmlValueForKeyPath:keyPath];
    }
    
    NSRange indexRange = [keyPath rangeOfString:@"["];
    if (indexRange.location == NSNotFound) {
        return [self tmlValueForKeyPath:keyPath];
    }
    NSArray *parts = [keyPath componentsSeparatedByString:@"."];
    id currentObject = self;
    NSInteger length = 0;
    for (NSString *part in parts) {
        length += part.length + (int)!!length;
        if (length > indexRange.location) {
            NSArray *indexParts = [part componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
            NSString *key = indexParts[0];
            currentObject = [self valueForKey:key];
            if ([currentObject isKindOfClass:[NSArray class]] == YES) {
                for (NSInteger i=1; i<indexParts.count; i+=2) {
                    id val = [indexParts objectAtIndex:i];
                    if ([val isKindOfClass:[NSString class]] == YES
                        && [(NSString *)val length] > 0) {
                        NSInteger index = [indexParts[i] integerValue];
                        currentObject = [currentObject objectAtIndex:index];
                    }
                }
            }
        }
        else {
            currentObject = [self valueForKey:part];
        }
    }
    return currentObject;
}

- (void)tmlSetValue:(id)value forKeyPath:(NSString *)keyPath {
    if ([TML sharedInstance].configuration.allowCollectionKeyPaths == NO) {
        [self tmlSetValue:value forKeyPath:keyPath];
        return;
    }
    
    NSRange indexRange = [keyPath rangeOfString:@"["];
    if (indexRange.location == NSNotFound) {
        [self tmlSetValue:value forKeyPath:keyPath];
        return;
    }
    NSArray *parts = [keyPath componentsSeparatedByString:@"."];
    id currentObject = self;
    id previousObject = self;
    id previousKey = nil;
    NSInteger length = 0;
    for (NSString *part in parts) {
        length += part.length + (int)!!length;
        if (length > indexRange.location) {
            NSArray *indexParts = [part componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
            NSString *key = indexParts[0];
            previousObject = currentObject;
            previousKey = key;
            currentObject = [[currentObject valueForKey:key] mutableCopy];
            if (currentObject == nil) {
                currentObject = [NSMutableArray array];
            }
            [previousObject setValue:currentObject forKey:previousKey];
            if ([currentObject isKindOfClass:[NSArray class]] == NO) {
                return;
            }
            for (NSInteger i=1; i<indexParts.count; i+=2) {
                BOOL isLast = (i+2) >= indexParts.count;
                NSInteger index = [indexParts[i] integerValue];
                if (isLast == NO) {
                    previousObject = currentObject;
                    previousKey = [NSNumber numberWithInteger:index];
                    if ([(NSArray *)currentObject count] > index) {
                        currentObject = [[currentObject objectAtIndex:index] mutableCopy];
                    }
                    else {
                        currentObject = nil;
                    }
                    if (currentObject == nil) {
                        currentObject = [NSMutableArray array];
                    }
                    if ([currentObject isKindOfClass:[NSArray class]] == NO) {
                        return;
                    }
                    ensureArrayIndex(previousObject, index);
                    [(NSMutableArray *)previousObject setObject:currentObject atIndexedSubscript:index];
                }
                else {
                    ensureArrayIndex(currentObject, index);
                    [currentObject setObject:value atIndexedSubscript:index];
                    if (previousObject != nil && [previousKey isKindOfClass:[NSNumber class]] == YES) {
                        [previousObject setObject:currentObject atIndex:[previousKey integerValue]];
                    }
                    else if (previousKey != nil && previousKey != nil) {
                        [previousObject setValue:currentObject forKey:previousKey];
                    }
                }
            }
        }
        else {
            currentObject = [self valueForKey:part];
        }
    }
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
    self.accessibilityLanguage = [TML currentLocale];
    
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
