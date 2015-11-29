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

#import <Foundation/Foundation.h>

@interface TMLConfiguration : NSObject

@property(nonatomic, strong) NSURL *apiURL;

@property(nonatomic, readwrite) NSString *accessToken;

@property(nonatomic, readwrite) NSString *applicationKey;

@property(nonatomic, strong) NSString *defaultLocale;

@property(nonatomic, strong) NSString *currentLocale;

@property(nonatomic, strong) NSMutableDictionary *contextRules;

@property(nonatomic, strong) NSMutableDictionary *defaultTokens;

@property(nonatomic, strong) NSMutableDictionary *defaultLocalization;

@property(nonatomic, strong) NSObject *viewingUser;

@property(nonatomic, assign, getter=isTranslationEnabled) BOOL translationEnabled;

@property(nonatomic) BOOL inContextTranslatorEnabled;

- (instancetype)initWithApplicationKey:(NSString *)applicationKey
                           accessToken:(NSString *)accessToken;
@property(readonly, nonatomic, getter=isValidConfiguration) BOOL validConfiguration;

- (id) variableMethodForContext:(NSString *) keyword andVariableName: (NSString *) varName;
- (void) setVariableMethod: (id) method forContext:(NSString *) keyword andVariableName: (NSString *) varName;

- (id) defaultTokenValueForName: (NSString *) name;
- (id) defaultTokenValueForName: (NSString *) name type: (NSString *) type;
- (id) defaultTokenValueForName: (NSString *) name type: (NSString *) type format: (NSString *) format;

- (void) setDefaultTokenValue: (id) value forName: (NSString *) name;
- (void) setDefaultTokenValue: (id) value forName: (NSString *) name type: (NSString *) type;
- (void) setDefaultTokenValue: (id) value forName: (NSString *) name type: (NSString *) type format: (NSString *) format;

- (NSString *) deviceLocale;

- (NSString *) customDateFormatForKey: (NSString *) key;
- (NSString *) dateTokenNameForKey: (NSString *) key;
- (NSObject *) dateValueForToken: (NSString *) token inDate: (NSDate *) date;

@end
