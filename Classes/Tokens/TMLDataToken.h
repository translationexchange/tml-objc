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

#import <Foundation/Foundation.h>
#import "TMLModel.h"
#import "TMLConfiguration.h"

extern void * const TMLCompiledTokenExpressionKey;

@class TMLLanguage, TMLLanguageContext;

@interface TMLDataToken : TMLModel

// Full name of the token
@property (nonatomic, strong, readonly) NSString *stringRepresentation;

// Short name of the token
@property (nonatomic, strong) NSString *name;

// Array of language case keywords for the token
@property (nonatomic, strong) NSSet *caseKeys;

// Array of language context keywords for the token
@property (nonatomic, strong) NSSet *contextKeys;

// Regular expression pattern for the token
// TODO: compile and store as static
+ (NSString *) pattern;

+ (NSRegularExpression *) expression;

// Returns the token object from the token map
+ (NSObject *) tokenObjectForName:(NSString *)name fromTokens:(NSDictionary *)tokens;

- (id) initWithString:(NSString *)string;

- (BOOL) isEqualToDataToken:(TMLDataToken *)dataToken;

- (void) parseFromString:(NSString *)string;

- (NSSet *) sanitizeValues:(NSArray *)values;
- (NSString *) sanitizeValue:(NSString *)value;

- (TMLLanguageContext *) contextForLanguage:(TMLLanguage *)language;

- (NSString *) tokenValue:(NSDictionary *)tokens;

- (NSString *) tokenValue:(NSDictionary *)tokens
              tokenFormat:(TMLTokenFormat)tokenFormat;

- (NSString *) applyLanguageCasesToValue:(NSString *)tokenValue
                              fromObject:(NSObject *)tokenObject
                             forLanguage:(TMLLanguage *)language;

- (NSString *) substituteInLabel:(NSString *)translatedLabel
                          tokens:(NSDictionary *)tokens
                        language:(TMLLanguage *)language;

@end
