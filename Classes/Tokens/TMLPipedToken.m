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
 # Piped Token Form 
 #
 # {count | message}   - will not include count value: "messages"
 # {count | message, messages}
 # {count:number | message, messages}
 # {user:gender | he, she, he/she}
 # {now:date | did, does, will do}
 # {users:list | all male, all female, mixed genders}
 #
 # {count || message, messages}  - will include count:  "5 messages"
 #
 ***********************************************************************/
#import "TML.h"
#import "TMLLanguageCase.h"
#import "TMLLanguageContext.h"
#import "TMLLanguageContextRule.h"
#import "TMLPipedToken.h"

@implementation TMLPipedToken

+ (NSString *) pattern {
    return @"(\\{[^_:|][\\w]*(:[\\w]+)*(::[\\w]+)*\\s*\\|\\|?[^{^}]+\\})";
}

- (void) parse {
    NSString *nameWithoutParens = [self.fullName stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"{}"]];
    
    NSMutableArray *parts = [NSMutableArray arrayWithArray: [nameWithoutParens componentsSeparatedByString:@"|"]];
    NSString *nameWithoutPipes = [parts objectAtIndex:0];
    
    parts = [NSMutableArray arrayWithArray: [nameWithoutPipes componentsSeparatedByString:@"::"]];
    NSString *nameWithoutCaseKeys = [parts objectAtIndex:0];
    [parts removeObjectAtIndex:0];
    self.caseKeys = [self.class sanitizeValues: parts];
    
    parts = [NSMutableArray arrayWithArray: [nameWithoutCaseKeys componentsSeparatedByString:@":"]];
    self.shortName = [self.class sanitizeValue: [parts objectAtIndex:0]];
    [parts removeObjectAtIndex:0];
    self.contextKeys = [self.class sanitizeValues: parts];
    
    self.separator = ([self.fullName rangeOfString:@"||"].length > 0 ? @"||" : @"|");
    
    NSMutableArray *pipedParams = [NSMutableArray array];
    NSArray *pipedParts = [nameWithoutParens componentsSeparatedByString:self.separator];
    if ([pipedParts count] > 0) {
        pipedParts = [[pipedParts objectAtIndex:1] componentsSeparatedByString:@","];
        for (NSString *part in pipedParts) {
            [pipedParams addObject: [self.class sanitizeValue:part]];
        }
    }
    self.parameters = pipedParams;
}

- (BOOL) isValueDisplayedInTranslation {
    return ([self.separator isEqualToString:@"||"]);
}


/**
 * token:      {count|| one: message, many: messages}
 * results in: {"one": "message", "many": "messages"}
 *
 * token:      {count|| message}
 * transform:  [{"one": "{$0}", "other": "{$0::plural}"}, {"one": "{$0}", "other": "{$1}"}]
 * results in: {"one": "message", "other": "messages"}
 *
 * token:      {count|| message, messages}
 * transform:  [{"one": "{$0}", "other": "{$0::plural}"}, {"one": "{$0}", "other": "{$1}"}]
 * results in: {"one": "message", "other": "messages"}
 *
 * token:      {user| Dorogoi, Dorogaya}
 * transform:  ["unsupported", {"male": "{$0}", "female": "{$1}", "other": "{$0}/{$1}"}]
 * results in: {"male": "Dorogoi", "female": "Dorogaya", "other": "Dorogoi/Dorogaya"}
 *
 * token:      {actors:|| likes, like}
 * transform:  ["unsupported", {"one": "{$0}", "other": "{$1}"}]
 * results in: {"one": "likes", "other": "like"}
 *
 */
- (NSDictionary *) generateValueMapForContext: (TMLLanguageContext *) context {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    
    NSString *firstParam = [self.parameters objectAtIndex:0];
    if ([firstParam rangeOfString:@":"].length > 0) {
        for (NSString *param in self.parameters) {
            NSArray *keyValue = [param componentsSeparatedByString:@":"];
            [values setObject:[self.class sanitizeValue: [keyValue objectAtIndex:1]] forKey:[self.class sanitizeValue: [keyValue objectAtIndex:0]]];
        }
        return values;
    }

    NSObject *tokenMapping = context.tokenMapping;
    
    if (tokenMapping == nil) {
        // TODO: add error condition
        return nil;
    }
    
    // Unsupported
    if ([tokenMapping isKindOfClass:NSString.class]) {
        // TODO: add error condition
        return nil;
    }

    // Array
    if ([tokenMapping isKindOfClass:NSArray.class]) {
        NSArray *tokenMappingArray = (NSArray *) tokenMapping;
        if ([self.parameters count] > [tokenMappingArray count])
            return nil;
        
        tokenMapping = [tokenMappingArray objectAtIndex:[self.parameters count]-1];
        if ([tokenMapping isKindOfClass:NSString.class])
            return nil;
    }
    
    // Dictionary
    if ([tokenMapping isKindOfClass:NSDictionary.class]) {
        NSDictionary *tokenMappingDictionary = (NSDictionary *) tokenMapping;
        for (NSString *key in [tokenMappingDictionary allKeys]) {
            NSString *value = [tokenMappingDictionary objectForKey:key];
            [values setObject:value forKey:key];
            
            NSError *error = NULL;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"\\{\\$\\d(::[\\w]+)*\\}" options: NSRegularExpressionCaseInsensitive error: &error];
            NSArray *tokens = [regex matchesInString: value options: 0 range: NSMakeRange(0, [value length])];
            
            for (NSTextCheckingResult *match in tokens) {
                NSString *tkey = [value substringWithRange:[match range]];
                NSString *tokenWithoutParens = [tkey stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"{}"]];
                NSMutableArray *parts = [NSMutableArray arrayWithArray:[tokenWithoutParens componentsSeparatedByString:@"::"]];
                NSString *indexValue = [self.class sanitizeValue: [parts objectAtIndex:0]];
                int index = [[indexValue stringByReplacingOccurrencesOfString:@"$" withString:@""] intValue];
                
                if ([self.parameters count] < index)
                    return nil;
                
                NSString *val = [self.parameters objectAtIndex:index];
                [parts removeObjectAtIndex:0];
                
                for (NSString *caseKey in parts) {
                    TMLLanguageCase *lcase = [context.language languageCaseByKeyword:caseKey];
                    if (lcase == nil)
                        return nil;
                    
                    val = [lcase apply:val];
                }

                [values setObject:[[values objectForKey:key] stringByReplacingOccurrencesOfString:tkey withString:val] forKey:key];
            }
        }
    }
    
    return values;
}

- (NSString *) placeholderName {
    return [NSString stringWithFormat:@"#%@#", self.shortName];
}

- (NSString *) substituteInLabel: (NSString *) translatedLabel usingTokens: (NSDictionary *) tokens forLanguage: (TMLLanguage *) language withOptions: (NSDictionary *) options {
    NSObject *object = [tokens objectForKey:self.shortName];
    
    if (object == nil) {
        TMLDebug(@"{%@: missing value for %@}", translatedLabel, self.shortName);
        return translatedLabel;
    }
    
    if ([self.parameters count] == 0) {
        TMLDebug(@"{%@: missing piped params for %@}", translatedLabel, self.shortName);
        return translatedLabel;
    }
    
    TMLLanguageContext *context = [self contextForLanguage:language];
    if (context == nil) {
        TMLDebug(@"{%@: context not available for %@}", translatedLabel, self.shortName);
        return translatedLabel;
    }
    
    NSDictionary *valueMap = [self generateValueMapForContext:context];
    
    if (valueMap == nil) {
        TMLDebug(@"{%@: invalid context or piped params for %@}", translatedLabel, self.shortName);
        return translatedLabel;
    }
    
    TMLLanguageContextRule *rule = (TMLLanguageContextRule *) [context findMatchingRule:object];

    if (rule == nil) {
        TMLDebug(@"{%@: no context rule matched for %@}", translatedLabel, self.shortName);
        return translatedLabel;
    }
    
    NSString *value = [valueMap objectForKey:rule.keyword];
    if (value == nil) {
        TMLLanguageContextRule *fallbackRule = (TMLLanguageContextRule *) context.fallbackRule;
        if (fallbackRule && [valueMap objectForKey:fallbackRule.keyword]) {
            value = [valueMap objectForKey:fallbackRule.keyword];
        }
    }
    
    if (value == nil) {
        TMLDebug(@"{%@: no value selected for %@}", translatedLabel, self.shortName);
        return translatedLabel;
    }

    NSMutableString *replacementValue = [NSMutableString string];

    if ([self isValueDisplayedInTranslation]) {
        [replacementValue appendString:[self tokenValue: tokens withOptions:options]];
        [replacementValue appendString: @" "];
    } else {
        value = [value stringByReplacingOccurrencesOfString: [self placeholderName] withString: [self tokenValue: tokens withOptions:options]];
    }
    [replacementValue appendString: value];
    
    return [translatedLabel stringByReplacingOccurrencesOfString:self.fullName withString:replacementValue];
}


@end
