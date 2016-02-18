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
#import "TMLDataToken.h"
#import "TMLLanguage.h"
#import "TMLLanguageCase.h"
#import <objc/runtime.h>

void * const TMLCompiledTokenExpressionKey = "TMLCompiledTokenExpressionKey";

@interface TMLDataToken ()
@property (nonatomic, strong, readwrite) NSString *stringRepresentation;
@end

@implementation TMLDataToken

+ (NSString *) pattern {
    return @"(\\{[^_:][\\w]*(:[\\w]+)*(::[\\w]+)*\\})";
}

+ (NSRegularExpression *) expression {
    NSRegularExpression *regex = objc_getAssociatedObject(self, TMLCompiledTokenExpressionKey);
    if (regex == nil) {
        NSError *error = NULL;
        regex = [NSRegularExpression
                 regularExpressionWithPattern: [self pattern]
                 options: NSRegularExpressionCaseInsensitive
                 error: &error];
        if (regex == nil) {
            TMLError(@"Error creating data token regexp: %@", error);
            objc_setAssociatedObject(self, TMLCompiledTokenExpressionKey, [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        else {
            objc_setAssociatedObject(self, TMLCompiledTokenExpressionKey, regex, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    if ([[NSNull null] isEqual:regex] == YES) {
        regex = nil;
    }
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

#pragma mark - Init

- (id) initWithString:(NSString *)string {
    if (self = [super init]) {
        [self parseFromString:string];
        self.stringRepresentation = string;
    }
    return self;
}

#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone {
    TMLDataToken *aCopy = [[TMLDataToken alloc] init];
    aCopy.name = [self.name copyWithZone:zone];
    aCopy.caseKeys = [self.caseKeys copyWithZone:zone];
    aCopy.contextKeys = [self.contextKeys copyWithZone:zone];
    return aCopy;
}

#pragma mark - Equality

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
    return ((self.name == dataToken.name
                || [self.name isEqualToString:dataToken.name] == YES)
            && (self.caseKeys == dataToken.caseKeys
                || [self.caseKeys isEqualToSet:dataToken.caseKeys] == YES)
            && (self.contextKeys == dataToken.contextKeys
                || [self.contextKeys isEqualToSet:dataToken.contextKeys] == YES));
}

#pragma mark - Sanitizing

- (NSString *) sanitizeValue:(NSString *)value {
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSSet *) sanitizeValues:(NSArray *)values {
    NSMutableSet *newValues = [NSMutableSet set];
    for (NSString *value in values) {
        [newValues addObject: [self sanitizeValue:value]];
    }
    return newValues;
}

#pragma mark - Parsing

- (void) parseFromString:(NSString *)string {
    [self reset];
    NSString *nameWithoutParens = [string stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"{}"]];
    
    NSMutableArray *parts = [NSMutableArray arrayWithArray: [nameWithoutParens componentsSeparatedByString:@"::"]];
    NSString *nameWithoutCaseKeys = [parts objectAtIndex:0];
    [parts removeObjectAtIndex:0];
    self.caseKeys = [self sanitizeValues:parts];
    
    parts = [NSMutableArray arrayWithArray: [nameWithoutCaseKeys componentsSeparatedByString:@":"]];
    self.name = [self sanitizeValue: [parts objectAtIndex:0]];
    [parts removeObjectAtIndex:0];
    self.contextKeys = [self sanitizeValues:parts];
}

#pragma mark - Representation

- (void)reset {
    _stringRepresentation = nil;
}

- (NSString *)stringRepresentation {
    if (_stringRepresentation == nil) {
        NSMutableString *result = [[NSMutableString alloc] init];
        [result appendString:@"{"];
        [result appendString:self.name];
        NSArray *contextKeys = [self.contextKeys allObjects];
        if (contextKeys.count > 0) {
            [result appendFormat:@":%@", [contextKeys componentsJoinedByString:@":"]];
        }
        NSArray *caseKeys = [self.caseKeys allObjects];
        if (caseKeys.count > 0) {
            [result appendFormat:@"::%@", [caseKeys componentsJoinedByString:@"::"]];
        }
        [result appendString:@"}"];
        _stringRepresentation = [result copy];
    }
    return _stringRepresentation;
}

#pragma mark - Accessors

- (void)setCaseKeys:(NSSet *)caseKeys {
    if (_caseKeys == caseKeys
        || [_caseKeys isEqualToSet:caseKeys] == YES) {
        return;
    }
    [self reset];
    _caseKeys = caseKeys;
}

- (void)setContextKeys:(NSSet *)contextKeys {
    if (_contextKeys == contextKeys
        || [_contextKeys isEqualToSet:contextKeys] == YES) {
        return;
    }
    [self reset];
    _contextKeys = contextKeys;
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
    NSArray *contextKeys = [self.contextKeys allObjects];
    if (contextKeys.count > 0) {
        return [language contextByKeyword:[contextKeys firstObject]];
    }
    
    return [language contextByTokenName:self.name];;
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

- (NSString *) tokenValue:(NSDictionary *)tokens {
    return [self tokenValue:tokens tokenFormat:TMLAttributedTokenFormat];
}

- (NSString *) tokenValue:(NSDictionary *)tokens
                tokenFormat:(TMLTokenFormat)tokenFormat
{

    // token not provided, fallback onto default, if available
    if ([tokens objectForKey:self.name] == nil) {
        NSString *tokenObject = (NSString *) [[[TML sharedInstance] configuration] defaultTokenValueForName:self.name
                                                                                                       type:TMLDataTokenType
                                                                                                     format:tokenFormat];
        if (tokenObject != nil) return tokenObject;
        return [self stringRepresentation];
    }

    NSObject *tokenObject = [tokens objectForKey:self.name];
 
    // provided as [object, value]
    if ([tokenObject isKindOfClass:NSArray.class]) {
        NSArray *tokenArrayObject = (NSArray *) tokenObject;
        
        // array must have 2 elements, object and value
        if ([tokenArrayObject count] != 2) {
            TMLDebug(@"{%@: array substitution value is not provided}", self.name);
            return [self stringRepresentation];
        }
        
        // @[user, user.name] or @[user, @"Michael"] or @[@1000, @"1,000"]
        if ([[tokenArrayObject objectAtIndex:1] isKindOfClass: NSString.class]) {
            return [tokenArrayObject objectAtIndex:1];
        }
        
        TMLDebug(@"{%@: unsupported array method}", self.name);
        return [self stringRepresentation];
    }
    
    if ([tokenObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *tokenDictionaryObject = (NSDictionary *) tokenObject;
        
        // @{@"object": @{@"gender": @"male"}, @"value": @"Michael"}
        if ([tokenDictionaryObject objectForKey:@"value"]) {
            return [tokenDictionaryObject objectForKey:@"value"];
        }
        
        if (![[tokenDictionaryObject objectForKey:@"object"] isKindOfClass: NSDictionary.class]) {
            TMLDebug(@"{%@: object attribute is missing or invalid}", self.name);
            return [self stringRepresentation];
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

        TMLDebug(@"{%@: substitution property/value is not provided", self.name);
        return [self stringRepresentation];
    }
    
    return [tokenObject description];
}

- (NSObject *) tokenObjectFromTokens: (NSDictionary *) tokens {
    return [self.class tokenObjectForName:self.name fromTokens:tokens];
}

- (NSString *) applyLanguageCaseWithKey:(NSString *)caseKey
                                  value:(NSString *)value
                                 object:(NSObject *)object
                               language:(TMLLanguage *)language
{
    TMLLanguageCase *lcase = [language languageCaseByKeyword:caseKey];
    if (lcase == nil)
        return value;
    return [lcase apply:value forObject:object];;
}

- (NSString *) applyLanguageCasesToValue:(NSString *)tokenValue
                              fromObject:(NSObject *)tokenObject
                             forLanguage:(TMLLanguage *)language
{
    if ([self.caseKeys count] > 0) {
        for (NSString *caseKey in self.caseKeys) {
            tokenValue = [self applyLanguageCaseWithKey:caseKey
                                                  value:tokenValue
                                                 object:tokenObject
                                               language:language];
        }
    }

    return tokenValue;
}

- (NSString *) substituteInLabel:(NSString *)translatedLabel
                          tokens:(NSDictionary *)tokens
                        language:(TMLLanguage *)language
{
    NSString *tokenValue = [self tokenValue:tokens];
    
    if ([tokenValue isEqualToString: self.stringRepresentation])
        return translatedLabel;
    
    tokenValue = [self applyLanguageCasesToValue:tokenValue
                                      fromObject:[self tokenObjectFromTokens: tokens]
                                     forLanguage:language];
    return [translatedLabel stringByReplacingOccurrencesOfString:self.stringRepresentation withString:tokenValue];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"<%@:%@: %p>", [self class], self.stringRepresentation, self];
}

@end
