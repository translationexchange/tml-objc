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

#import "NSString+TmlAdditions.h"
#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLAPISerializer.h"
#import "TMLApplication.h"
#import "TMLAttributedDecorationTokenizer.h"
#import "TMLConfiguration.h"
#import "TMLDataTokenizer.h"
#import "TMLLanguage.h"
#import "TMLPostOffice.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"

@interface TMLApplication()
@property(nonatomic, readwrite) TMLConfiguration *configuration;

@end

@implementation TMLApplication

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.applicationID forKey:@"id"];
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.secret forKey:@"secret"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.defaultLocale forKey:@"defaultLocale"];
    [aCoder encodeInteger:self.threshold forKey:@"threshold"];
    [aCoder encodeObject:self.features forKey:@"features"];
    [aCoder encodeObject:self.tools forKey:@"tools"];
    [aCoder encodeObject:self.languages forKey:@"languages"];
    [aCoder encodeObject:self.sources forKey:@"sources"];
    [aCoder encodeObject:self.defaultLanguage forKey:@"default_language"];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.applicationID = [aDecoder decodeIntegerForKey:@"id"];
    self.key = [aDecoder decodeObjectForKey:@"key"];
    self.secret = [aDecoder decodeObjectForKey:@"secret"];
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.defaultLocale = [aDecoder decodeObjectForKey:@"defaultLocale"];
    self.threshold = [aDecoder decodeIntegerForKey:@"threshold"];
    self.features = [aDecoder decodeObjectForKey:@"features"];
    NSArray *languages = [aDecoder decodeObjectForKey:@"languages"];
    if (languages != nil && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        languages = [TMLAPISerializer materializeObject:languages
                                              withClass:[TMLLanguage class]];
    }
    self.languages = languages;
    id defaultLanguage = [aDecoder decodeObjectForKey:@"default_language"];
    if (defaultLanguage != nil && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        defaultLanguage = [TMLAPISerializer materializeObject:defaultLanguage
                                                    withClass:[TMLLanguage class]];
    }
    self.defaultLanguage = defaultLanguage;
    
    NSArray *sources = [aDecoder decodeObjectForKey:@"sources"];
    if (sources.count > 0 && [aDecoder isKindOfClass:[TMLAPISerializer class]] == YES) {
        sources = [TMLAPISerializer materializeObject:sources
                                            withClass:[TMLSource class]];
    }
    self.sources = sources;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    return [self isEqualToApplication:(TMLApplication *)object];
}

- (BOOL)isEqualToApplication:(TMLApplication *)application {
    return self.applicationID == application.applicationID;
}

#pragma mark - Languages

- (TMLLanguage *) languageForLocale:(NSString *)locale {
    TMLLanguage *result = nil;
    for (TMLLanguage *lang in self.languages) {
        if ([lang.locale isEqualToString:locale] == YES) {
            result = lang;
            break;
        }
    }
    return result;
}

#pragma mark - Sources

- (TMLSource *) sourceForKey:(NSString *)sourceKey {
    if (sourceKey == nil)
        return nil;
    
    TMLSource *result = nil;
    for (TMLSource *source in self.sources) {
        if ([source.key isEqualToString:sourceKey] == YES) {
            result = source;
        }
    }
    
    return result;
}

@end
