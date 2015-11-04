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
#import "TmlBase.h"
#import "TmlApplication.h"

@class TmlLanguageContext;
@class TmlLanguageCase;

@interface TmlLanguage : TmlBase

// Holds reference to the application it belongs to
@property(nonatomic, weak) TmlApplication *application;

// Language locale based on Tml notation
@property(nonatomic, strong) NSString *locale;

// Language name in English
@property(nonatomic, strong) NSString *englishName;

// Language name in the native form
@property(nonatomic, strong) NSString *nativeName;

// Whether the language rtl or ltr
@property(nonatomic, strong) NSNumber *rightToLeft;

// Url of the language flag image
@property(nonatomic, strong) NSString *flagUrl;

// Hash of all language contexts
@property(nonatomic, strong) NSDictionary *contexts;

// Hash of all language cases
@property(nonatomic, strong) NSDictionary *cases;

+ (TmlLanguage *) defaultLanguage;

- (NSString *) name;

- (NSString *) fullName;

// Returns language context based on the keyword
- (TmlLanguageContext *) contextByKeyword: (NSString *) keyword;

// Returns language context based on the token name
- (TmlLanguageContext *) contextByTokenName: (NSString *) tokenName;

// Returns language case based on the keyword
- (TmlLanguageCase *) languageCaseByKeyword: (NSString *) keyword;

// Languages are loaded without definition by default, this will tell if the language has definition or it needs to be loaded
- (BOOL) hasDefinitionData;

// Check if the language is application default
- (BOOL) isDefault;

// If browser is used, this will give HTML direction
- (NSString *) htmlDirection;

// If browser is used, this will give HTML alignment
- (NSString *) htmlAlignmentWithLtrDefault: (NSString *) defaultAlignment;

// Retrieves value from options, then block, then defaults
- (NSObject *) valueFromOptions: (NSDictionary *) options forKey: (NSString *) key withDefault: (NSObject *) defaultValue;

// Generates new translation key
- (NSObject *) translationKeyWithKey: (NSString *) key label: (NSString *) label description:(NSString *) description options: (NSDictionary *) options;
    
// Translation method
- (NSObject *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options;

@end
