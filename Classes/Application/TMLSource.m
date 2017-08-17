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

#import "TML.h"
#import "TMLAPIResponse.h"
#import "TMLSource.h"

NSString * const TMLSourceDefaultKey = @"TML";

@implementation TMLSource

+ (instancetype)defaultSource {
    static TMLSource *source;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        source = [[TMLSource alloc] init];
        source.key = TMLSourceDefaultKey;
    });
    return source;
}

- (id)copyWithZone:(NSZone *)zone {
    TMLSource *aCopy = [[TMLSource alloc] init];
    aCopy.translations = [self.translations copyWithZone:zone];
    aCopy.sourceID = self.sourceID;
    aCopy.key = [self.key copyWithZone:zone];
    aCopy.path = [self.path copyWithZone:zone];
    return aCopy;
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

- (BOOL)isEqualToSource:(TMLSource *)source {
    return (self.sourceID == source.sourceID
            && (self.key == source.key
                || [self.key isEqualToString:source.key] == YES)
            && (self.path == source.path
                || [self.path isEqualToString:source.path] == YES));
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.sourceID forKey:@"id"];
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.path forKey:@"path"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.sourceID = [aDecoder decodeIntegerForKey:@"id"];
    self.key = [aDecoder decodeObjectForKey:@"key"];
    self.path = [aDecoder decodeObjectForKey:@"path"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@>", NSStringFromClass([self class]), self.key];
}

- (NSUInteger)hash {
    return [self.key hash];
}

- (void) updateTranslations:(NSDictionary *)translationInfo forLocale:(NSString *)locale {
    NSMutableDictionary *newTranslations = [self.translations mutableCopy];
    newTranslations[locale]=translationInfo;
    self.translations = (NSDictionary *)newTranslations;
}

- (NSArray *) translationsForKey:(NSString *) translationKey inLanguage: (NSString *) locale {
    if (!self.translations && ![self.translations objectForKey:locale]) return nil;
    return [[self.translations objectForKey:locale] objectForKey:translationKey];
}

@end
