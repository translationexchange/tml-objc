//
//  UIResponder+TML.m
//  TMLKit
//
//  Created by Pasha on 12/10/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "NSAttributedString+TML.h"
#import "NSObject+TML.h"
#import "TML.h"
#import "TMLTranslationKey.h"
#import "UIResponder+TML.h"

@implementation UIResponder (TML)

- (NSArray *)tmlTranslationKeys {
    NSMutableArray *translationKeys = [NSMutableArray array];
    NSSet *keyPaths = [self tmlLocalizedKeyPaths];
    for (NSString *keyPath in keyPaths) {
        // first lookup the key in the registry
        NSDictionary *registry = [self tmlRegistry];
        NSDictionary *payload = registry[keyPath];
        TMLTranslationKey *translationKey = payload[TMLRegistryTranslationKeyName];
        if (translationKey != nil) {
            [translationKeys addObject:translationKey.key];
        }
        // if nothing in the registry, lookup translation key by localized string
        else {
            NSMutableArray *labelsToMatch = [NSMutableArray array];
            id label = [self valueForKeyPath:keyPath];
            if ([label isKindOfClass:[NSAttributedString class]] == YES) {
                [labelsToMatch addObject:[label tmlAttributedString:nil]];
                [labelsToMatch addObject:[(NSAttributedString *)label string]];
            }
            else if ([label isKindOfClass:[NSString class]] == YES) {
                [labelsToMatch addObject:label];
            }
            
            NSMutableArray *localesToCheck = [NSMutableArray array];
            NSString *currentLocale = [TML currentLocale];
            if (currentLocale != nil) {
                [localesToCheck addObject:currentLocale];
            }
            NSString *defaultLocale = [TML defaultLocale];
            if (defaultLocale != nil && [defaultLocale isEqualToString:currentLocale] == NO) {
                [localesToCheck addObject:defaultLocale];
            }
            
            NSArray *matchingKeys = nil;
            for (NSString *searchLabel in labelsToMatch) {
                for (NSString *locale in localesToCheck) {
                    matchingKeys = [[TML sharedInstance] translationKeysForString:searchLabel
                                                                           locale:locale];
                    if (matchingKeys.count > 0) {
                        break;
                    }
                }
            }
            
            if (matchingKeys.count > 0) {
                [translationKeys addObjectsFromArray:matchingKeys];
            }
        }
    }
    return [translationKeys copy];
}

@end
