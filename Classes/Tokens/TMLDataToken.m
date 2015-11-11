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

/***********************************************************************
 #
 # Data Token Forms:
 #
 # {count}
 # {count:number}
 # {user:gender}
 # {today:date}
 # {user_list:list}
 # {long_token_name}
 # {user1}
 # {user1:user}
 # {user1:user::pos}
 #
 # Data tokens can be associated with any rules through the :dependency
 # notation or using the nameing convetnion of the token suffix, defined
 # in the tr8n configuration file
 #
 ***********************************************************************/

#import "TML.h"
#import "TMLConfiguration.h"
#import "TMLDataToken.h"
#import "TMLLanguage.h"
#import "TMLLanguageCase.h"

@interface TMLDataToken ()

@end

@implementation TMLDataToken

+ (NSString *) pattern {
    return @"(\\{[^_:][\\w]*(:[\\w]+)*(::[\\w]+)*\\})";
}

+ (NSRegularExpression *) expression {
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern: [self pattern]
                                  options: NSRegularExpressionCaseInsensitive
                                  error: &error];
    return regex;
}

+ (NSObject *) tokenObjectForName: (NSString *) name fromTokens: (NSDictionary *) tokens {
    if (tokens == nil)
        return nil;

    NSObject *object = [tokens objectForKey: name];

    if (object == nil)
        return nil;

    // If object is an array, the first element must always indicate an object
    // @[user,...]
    if ([object isKindOfClass:NSArray.class]) {
        NSArray *array = (NSArray *) object;
        return [array objectAtIndex:0];
    }
    
    // If object is a dictionary, the object is passed as an "object" attribute
    // @{@"object": user}
    if ([object isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictionary = (NSDictionary *) object;
        return [dictionary objectForKey: @"object"];
    }
    
    return object;
}

- (id) initWithName: (NSString *) newFullName {
    return [self initWithName:newFullName inLabel:newFullName];
}

- (id) initWithName: (NSString *) newFullName inLabel: (NSString *) newLabel {
    if (self = [super init]) {
        self.label = newLabel;
        self.fullName = newFullName;
        [self parse];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    TMLDataToken *aCopy = [[TMLDataToken alloc] init];
    aCopy.label = [self.label copyWithZone:zone];
    aCopy.fullName = [self.fullName copyWithZone:zone];
    aCopy.shortName = [self.shortName copyWithZone:zone];
    aCopy.caseKeys = [self.caseKeys copyWithZone:zone];
    aCopy.contextKeys = [self.contextKeys copyWithZone:zone];
    return aCopy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToDataToken:(TMLDataToken *)object];
}

- (BOOL)isEqualToDataToken:(TMLDataToken *)dataToken {
    return ([self.label isEqualToString:dataToken.label] == YES
            && [self.fullName isEqualToString:dataToken.fullName] == YES
            && [self.shortName isEqualToString:dataToken.shortName] == YES
            && [self.caseKeys isEqualToArray:dataToken.caseKeys] == YES
            && [self.contextKeys isEqualToArray:dataToken.contextKeys] == YES);
}

+ (NSString *) sanitizeValue: (NSString *) value {
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (NSArray *) sanitizeValues: (NSArray *) values {
    NSMutableArray *newValues = [NSMutableArray array];
    for (NSString *value in values) {
        [newValues addObject: [self sanitizeValue:value]];
    }
    return newValues;
}

- (void) parse {
    NSString *nameWithoutParens = [self.fullName stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"{}"]];
    
    NSMutableArray *parts = [NSMutableArray arrayWithArray: [nameWithoutParens componentsSeparatedByString:@"::"]];
    NSString *nameWithoutCaseKeys = [parts objectAtIndex:0];
    [parts removeObjectAtIndex:0];
    self.caseKeys = [self.class sanitizeValues: parts];
    
    parts = [NSMutableArray arrayWithArray: [nameWithoutCaseKeys componentsSeparatedByString:@":"]];
    self.shortName = [self.class sanitizeValue: [parts objectAtIndex:0]];
    [parts removeObjectAtIndex:0];
    self.contextKeys = [self.class sanitizeValues: parts];
}

- (NSString *) nameWithOptions: (NSDictionary *) options {
    NSMutableString *result = [NSMutableString stringWithString:self.shortName];
    
    if ([[options valueForKey:@"context_keys"] isEqual: @YES] && [self.contextKeys count] > 0) {
        [result appendFormat:@":%@", [self.contextKeys componentsJoinedByString:@":"]];
    }

    if ([[options valueForKey:@"case_keys"] isEqual: @YES] && [self.caseKeys count] > 0) {
        [result appendFormat:@"::%@", [self.caseKeys componentsJoinedByString:@"::"]];
    }
    
    if ([[options valueForKey:@"parens"] isEqual: @YES]) {
        result = [NSMutableString stringWithFormat:@"{%@}", result];
    }

    return result;
}

/**
 * For transform tokens, we can only use the first context key, if it is not mapped in the context itself.
 *
 * {user:gender | male: , female: ... }
 *
 * It is not possible to apply multiple context rules on a single token at the same time:
 *
 * {user:gender:value | .... hah?}
 *
 * It is still possible to setup dependencies on multiple contexts.
 *
 * {user:gender:value}   - just not with transform tokens
 */

- (TMLLanguageContext *) contextForLanguage: (TMLLanguage *) language {
    if ([self.contextKeys count] > 0) {
        return [language contextByKeyword:[self.contextKeys objectAtIndex:0]];
    }
    
    return [language contextByTokenName:self.shortName];;
}

/**
 * Returns a value from values hash.
 *
 * Token objects can be passed using any of the following forms:
 *
 * - if an object is passed without a substitution value, it will use toString() to get the value
 *
 *     [TML translate: @"Hello {user}" withTokens: @{@"user": current_user}]
 *     [TML translate: @"{count||message}" withTokens: @{@"count": @1}]
 *
 * - if object is an array, the second value is the substitution value:
 *
 *     [TML translate: @"Hello {user}" withTokens: @{@"user": @[user, @"Michael"]}]
 *     [TML translate: @"Hello {user}" withTokens: @{@"user": @[user, user.name]}]
 *
 * - The parameter can be a dictionary that may contain an "object" and value/attribute/property element (mostly for JSON support):
 *
 *     [TML translate: @"Hello {user}" withTokens: @{@"user": @{@"object": @{@"gender": @"male"}, @"value": @"Michael"}}]
 *     [TML translate: @"Hello {user}" withTokens: @{@"user": @{@"object": @{@"gender": @"male", @"name": @"Michael"}, @"property": @"name"}}]
 *
 */

- (NSString *) tokenValue: (NSDictionary *) tokens {
    return [self tokenValue:tokens withOptions:@{@"tokenizer": @"html"}];
}

- (NSString *) tokenValue: (NSDictionary *) tokens withOptions: (NSDictionary *) options {

    // token not provided, fallback onto default, if available
    if ([tokens objectForKey:self.shortName] == nil) {
        NSString *tokenObject = (NSString *) [[TML configuration] defaultTokenValueForName: self.shortName type:@"data" format: ([[options objectForKey:@"tokenizer"] isEqual: @"attributed"] ? @"attributed" : @"html")];
        if (tokenObject != nil) return tokenObject;
        return [self description];
    }

    NSObject *tokenObject = [tokens objectForKey:self.shortName];
 
    // provided as [object, value]
    if ([tokenObject isKindOfClass:NSArray.class]) {
        NSArray *tokenArrayObject = (NSArray *) tokenObject;
        
        // array must have 2 elements, object and value
        if ([tokenArrayObject count] != 2) {
            TMLDebug(@"{%@ in %@: array substitution value is not provided}", self.shortName, self.label);
            return [self description];
        }
        
        // @[user, user.name] or @[user, @"Michael"] or @[@1000, @"1,000"]
        if ([[tokenArrayObject objectAtIndex:1] isKindOfClass: NSString.class]) {
            return [tokenArrayObject objectAtIndex:1];
        }
        
        TMLDebug(@"{%@ in %@: unsupported array method}", self.shortName, self.label);
        return [self description];
    }
    
    if ([tokenObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *tokenDictionaryObject = (NSDictionary *) tokenObject;
        
        // @{@"object": @{@"gender": @"male"}, @"value": @"Michael"}
        if ([tokenDictionaryObject objectForKey:@"value"]) {
            return [tokenDictionaryObject objectForKey:@"value"];
        }
        
        if (![[tokenDictionaryObject objectForKey:@"object"] isKindOfClass: NSDictionary.class]) {
            TMLDebug(@"{%@ in %@: object attribute is missing or invalid}", self.shortName, self.label);
            return [self description];
        }
        
        NSDictionary *object = [tokenDictionaryObject objectForKey:@"object"];

        // @{@"object": @{@"gender": @"male", @"name": @"Michael"}, @"attribute": @"name"}
        if ([tokenDictionaryObject objectForKey:@"attribute"]) {
            return [object objectForKey:[tokenDictionaryObject objectForKey:@"attribute"]];
        }
        
        // @{@"object": @{@"gender": @"male", @"name": @"Michael"}, @"property": @"name"}
        if ([tokenDictionaryObject objectForKey:@"property"]) {
            return [object objectForKey:[tokenDictionaryObject objectForKey:@"property"]];
        }

        TMLDebug(@"{%@ in %@: substitution property/value is not provided", self.shortName, self.label);
        return [self description];
    }
    
    return [tokenObject description];
}

- (NSObject *) tokenObjectFromTokens: (NSDictionary *) tokens {
    return [self.class tokenObjectForName:self.shortName fromTokens:tokens];
}

- (NSString *) applyLanguageCaseWithKey: (NSString *) caseKey value: (NSString *) value object: (NSObject *) object language: (TMLLanguage *) language options: (NSDictionary *) options {
    TMLLanguageCase *lcase = [language languageCaseByKeyword:caseKey];
    if (lcase == nil)
        return value;
    return [lcase apply:value forObject:object];;
}

- (NSString *) applyLanguageCasesToValue: (NSString *) tokenValue fromObject: (NSObject *) tokenObject forLanguage: (TMLLanguage *) language andOptions: (NSDictionary *) options {
    if ([self.caseKeys count] > 0) {
        for (NSString *caseKey in self.caseKeys) {
            tokenValue = [self applyLanguageCaseWithKey:caseKey value:tokenValue object:tokenObject language:language options:options];
        }
    }

    return tokenValue;
}

- (NSString *) substituteInLabel: (NSString *) translatedLabel usingTokens: (NSDictionary *) tokens forLanguage: (TMLLanguage *) language withOptions: (NSDictionary *) options {
    NSString *tokenValue = [self tokenValue:tokens withOptions:options];
    
    if ([tokenValue isEqualToString: self.fullName])
        return translatedLabel;
    
    tokenValue = [self applyLanguageCasesToValue:tokenValue fromObject:[self tokenObjectFromTokens: tokens] forLanguage:language andOptions:options];
    return [translatedLabel stringByReplacingOccurrencesOfString:self.fullName withString:tokenValue];
}

- (NSString *) description {
    return self.fullName;
}

@end
