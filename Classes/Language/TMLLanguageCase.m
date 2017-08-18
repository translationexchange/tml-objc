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


#import "TMLLanguageCase.h"
#import "TMLLanguageCaseRule.h"
#import "TMLLanguage.h"
#import "TMLAPISerializer.h"

@implementation TMLLanguageCase

- (id)copyWithZone:(NSZone *)zone {
    TMLLanguageCase *aCopy = [[TMLLanguageCase alloc] init];
    aCopy.language = [self.language copyWithZone:zone];
    aCopy.application = [self.application copyWithZone:zone];
    aCopy.keyword = [self.keyword copyWithZone:zone];
    aCopy.latinName = [self.latinName copyWithZone:zone];
    aCopy.nativeName = [self.nativeName copyWithZone:zone];
    aCopy.caseDescription = [self.caseDescription copyWithZone:zone];
    aCopy.rules = [self.rules copyWithZone:zone];
    return aCopy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToLanguageCase:(TMLLanguageCase *)object];
}

- (BOOL)isEqualToLanguageCase:(TMLLanguageCase *)languageCase {
    return ((self.language == languageCase.language
             || [self.language isEqualToLanguage:languageCase.language] == YES)
            && (self.application == languageCase.application
                || [self.application isEqualToString:languageCase.application] == YES)
            && (self.caseDescription == languageCase.caseDescription
                || [self.caseDescription isEqualToString:languageCase.caseDescription] == YES)
            && (self.latinName == languageCase.latinName
                || [self.latinName isEqualToString:languageCase.latinName] == YES)
            && (self.nativeName == languageCase.nativeName
                || [self.nativeName isEqualToString:languageCase.nativeName] == YES)
            && (self.rules == languageCase.rules
                || [self.rules isEqualToArray:languageCase.rules] == YES));
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.application forKey:@"application"];
    [aCoder encodeObject:self.keyword forKey:@"keyword"];
    [aCoder encodeObject:self.latinName forKey:@"latin_name"];
    [aCoder encodeObject:self.nativeName forKey:@"native_name"];
    [aCoder encodeObject:self.caseDescription forKey:@"description"];
    [aCoder encodeObject:self.rules forKey:@"rules"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.application = [aDecoder decodeObjectForKey:@"application"];
    self.keyword = [aDecoder decodeObjectForKey:@"keyword"];
    self.latinName = [aDecoder decodeObjectForKey:@"latin_name"];
    self.nativeName = [aDecoder decodeObjectForKey:@"native_name"];
    self.caseDescription = [aDecoder decodeObjectForKey:@"description"];
    NSArray *rules = [aDecoder decodeObjectForKey:@"rules"];
    if (rules.count > 0 && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        rules = [TMLAPISerializer materializeObject:rules withClass:[TMLLanguageCaseRule class]];
    }
    self.rules = rules;
}

- (NSObject *) findMatchingRule: (NSString *) value {
    return [self findMatchingRule:value forObject:nil];
}

- (NSObject *) findMatchingRule: (NSString *) value forObject: (NSObject *) object {
    for (TMLLanguageCaseRule *rule in self.rules) {
        NSNumber *result = [rule evaluate:value forObject:object];
        if ([result isEqual: @YES])
            return rule;
    }
    
    return nil;
}

- (NSString *) apply: (NSString *) value {
    return [self apply:value forObject:nil];
}

- (NSString *) apply: (NSString *) value forObject: (NSObject *) object {
    NSArray *elements;
    
    if ([self.application isEqualToString:@"phrase"]) {
        elements = @[value];
    } else {
        NSString *pattern = @"\\s\\/,;:"; // split by space, comma, ;, : and /
        NSString *tempSeparator = @"%|%";
        NSString *cleanedValue = [value stringByReplacingOccurrencesOfString: pattern
                                                                  withString: tempSeparator
                                                                     options: NSRegularExpressionSearch
                                                                       range: NSMakeRange(0, value.length)];
        elements = [cleanedValue componentsSeparatedByString: tempSeparator];
    }

    // TODO: use RegEx to split words and assemble them right back
    // The current solution will not work for Палиграф Палиграфович -> Палиграфа Палиграфаович

    NSString *transformedValue = [NSString stringWithString:value];
    for (NSString *element in elements) {
        TMLLanguageCaseRule *rule = (TMLLanguageCaseRule *) [self findMatchingRule:element forObject:object];
        if (rule == nil)
            continue;
        
        NSString *adjustedValue = [rule apply:element];
        transformedValue = [transformedValue stringByReplacingOccurrencesOfString: element
                                                                       withString: adjustedValue
                                                                          options: 0
                                                                            range: NSMakeRange(0, transformedValue.length)];
    }
    
    return transformedValue;
}

@end
