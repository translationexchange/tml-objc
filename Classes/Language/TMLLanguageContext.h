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

@class TMLLanguage, TMLLanguageContextRule;

@interface TMLLanguageContext : TMLModel

// Reference back to the language it belongs to
@property(nonatomic, strong) TMLLanguage *language;

// Unique key identifying the context => num, gender, list, etc..
@property(nonatomic, strong) NSString *keyword;

// Description of the context
@property(nonatomic, strong) NSString *contextDescription;

// List of available rule keys. num => [one, few, many, other]
@property(nonatomic, strong) NSArray *keys;

@property(nonatomic, strong) NSString *defaultKey;

// Expression indicating which tokens belong to this context
@property(nonatomic, strong) NSString *tokenExpression;

// Compiled token expression
@property(nonatomic, strong) NSRegularExpression *tokenRegularExpression;

// List of variable names that an object must support for the context
@property(nonatomic, strong) NSArray *variableNames;

// Mapping of parameters to rules
@property(nonatomic, strong) NSObject <NSCopying>*tokenMapping;

// Hash of all the rules for the context => {one: rule, few: rule, ...}
@property(nonatomic, strong) NSDictionary *rules;

// Fallback rule for the context
@property(nonatomic, strong) TMLLanguageContextRule *fallbackRule;

// Checks whether the case is applicable to the token with a given name
- (BOOL) isApplicableToTokenName: (NSString *) tokenName;

// Extracts variable values from an object
- (NSDictionary *) vars: (NSObject *) object;

// Find the matching rule for the object
- (NSObject *) findMatchingRule: (NSObject *) object;


@end
