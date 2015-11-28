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
#import "TMLModel.h"

@class TMLLanguage, TMLLanguageContext;

@interface TMLDataToken : TMLModel

// Original label from where the token was extracted
@property (nonatomic, strong) NSString *label;

// Full name of the token
@property (nonatomic, strong) NSString *fullName;

// Short name of the token
@property (nonatomic, strong) NSString *shortName;

// Array of language case keywords for the token
@property (nonatomic, strong) NSArray *caseKeys;

// Array of language context keywords for the token
@property (nonatomic, strong) NSArray *contextKeys;

// Regular expression pattern for the token
// TODO: compile and store as static
+ (NSString *) pattern;

+ (NSRegularExpression *) expression;

// Returns the token object from the token map
+ (NSObject *) tokenObjectForName: (NSString *) name fromTokens: (NSDictionary *) tokens;

+ (NSString *) sanitizeValue: (NSString *) value;

+ (NSArray *) sanitizeValues: (NSArray *) values;

// Initialized a new token
- (id) initWithName: (NSString *) newFullName;

// Initialized a new token
- (id) initWithName: (NSString *) newFullName inLabel: (NSString *) newLabel;

- (BOOL)isEqualToDataToken:(TMLDataToken *)dataToken;

// Parsing token data
- (void) parse;

// Returns name based on various options
- (NSString *) nameWithOptions: (NSDictionary *) options;

- (TMLLanguageContext *) contextForLanguage: (TMLLanguage *) language;

- (NSString *) tokenValue: (NSDictionary *) tokens;

- (NSString *) tokenValue: (NSDictionary *) tokens withOptions: (NSDictionary *) options;

- (NSString *) applyLanguageCasesToValue:(NSString *)tokenValue
                              fromObject:(NSObject *)tokenObject
                             forLanguage:(TMLLanguage *)language;

- (NSString *) substituteInLabel:(NSString *)translatedLabel
                     usingTokens:(NSDictionary *)tokens
                     forLanguage:(TMLLanguage *)language
                     withOptions:(NSDictionary *)options;

@end
