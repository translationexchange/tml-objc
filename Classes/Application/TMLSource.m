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

#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLConfiguration.h"
#import "TMLSource.h"
#import "TMLTranslation.h"

NSString * const TMLSourceDefaultKey = @"TML";

@implementation TMLSource

+ (instancetype)defaultSource {
    TMLSource *source = [[TMLSource alloc] init];
    source.key = TMLSourceDefaultKey;
    return source;
}

- (id)copyWithZone:(NSZone *)zone {
    TMLSource *aCopy = [[TMLSource alloc] init];
    aCopy.translations = [self.translations copyWithZone:zone];
    aCopy.sourceID = self.sourceID;
    aCopy.key = [self.key copyWithZone:zone];
    aCopy.created = [self.created copyWithZone:zone];
    aCopy.updated = [self.updated copyWithZone:zone];
    aCopy.displayName = [self.displayName copyWithZone:zone];
    aCopy.sourceName = [self.sourceName copyWithZone:zone];
    aCopy.type = [self.type copyWithZone:zone];
    aCopy.state = [self.state copyWithZone:zone];
    return aCopy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.sourceID forKey:@"id"];
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.created forKey:@"created_at"];
    [aCoder encodeObject:self.updated forKey:@"updated_at"];
    [aCoder encodeObject:self.displayName forKey:@"display_name"];
    [aCoder encodeObject:self.sourceName forKey:@"source"];
    [aCoder encodeObject:self.type forKey:@"type"];
    [aCoder encodeObject:self.state forKey:@"state"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.sourceID = [aDecoder decodeIntegerForKey:@"id"];
    self.key = [aDecoder decodeObjectForKey:@"key"];
    self.created = [aDecoder decodeObjectForKey:@"created_at"];
    self.updated = [aDecoder decodeObjectForKey:@"updated_at"];
    self.displayName = [aDecoder decodeObjectForKey:@"display_name"];
    self.sourceName = [aDecoder decodeObjectForKey:@"source"];
    self.type = [aDecoder decodeObjectForKey:@"type"];
    self.state = [aDecoder decodeObjectForKey:@"state"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@>", NSStringFromClass([self class]), self.key];
}

- (BOOL)isEqualToSource:(TMLSource *)source {
    return [self.key isEqualToString:source.key];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    
    return [self isEqualToSource:(TMLSource *)object];
}

- (NSUInteger)hash {
    return [self.key hash];
}

- (void) updateTranslations:(NSDictionary *)translationInfo forLocale:(NSString *)locale {
    NSMutableDictionary *newTranslations = [self.translations mutableCopy];
    newTranslations[locale]=translationInfo;
    self.translations = (NSDictionary *)newTranslations;
}

- (void) loadTranslationsForLocale:(NSString *)locale
                   completionBlock:(void(^)(BOOL success))completionBlock
{
    [[[TML sharedInstance] apiClient] getTranslationsForLocale:locale source:self options:@{TMLAPIOptionsIncludeAll: @YES} completionBlock:^(NSDictionary<NSString *,TMLTranslation *> *newTranslations, TMLAPIResponse *response, NSError *error) {
        BOOL success = NO;
        if (newTranslations != nil) {
            success = YES;
            [self updateTranslations:newTranslations forLocale:locale];
        }
        if (completionBlock != nil) {
            completionBlock(success);
        }
    }];
}

- (NSArray *) translationsForKey:(NSString *) translationKey inLanguage: (NSString *) locale {
    if (!self.translations && ![self.translations objectForKey:locale]) return nil;
    return [[self.translations objectForKey:locale] objectForKey:translationKey];
}

@end
