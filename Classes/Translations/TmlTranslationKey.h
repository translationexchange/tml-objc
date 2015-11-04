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
#import "TmlLanguage.h"


@interface TmlTranslationKey : TmlBase

// Reference to the application where the key came from
@property(nonatomic, weak) TmlApplication *application;

// Unique key (md5 hash) identifying this translation key
@property(nonatomic, strong) NSString *key;

// Text to be translated
@property(nonatomic, strong) NSString *label;

// Description of the text to be translated
@property(nonatomic, strong) NSString *description;

// Locale of the text to be translated
@property(nonatomic, strong) NSString *locale;

// Level of the key
@property(nonatomic, strong) NSNumber *level;

// List of translations ordered by precedence
@property(nonatomic, strong) NSArray *translations;

// Holds all data tokens found in the translation key
@property(nonatomic, strong) NSArray *dataTokens;

// Holds all decoration tokens found in the translation key
@property(nonatomic, strong) NSArray *decorationTokens;

// Generates unique hash key for the translation key using label
+ (NSString *) generateKeyForLabel: (NSString *) label;

// Generates unique hash key for the translation key using label and description
+ (NSString *) generateKeyForLabel: (NSString *) label andDescription: (NSString *) description;

// Returns YES if there are translations available for the key
- (BOOL) hasTranslations;

- (NSDictionary *) toDictionary;

// Translation methods
- (NSObject *) translateToLanguage: (TmlLanguage *) language;
- (NSObject *) translateToLanguage: (TmlLanguage *) language withTokens: (NSDictionary *) tokens;
- (NSObject *) translateToLanguage: (TmlLanguage *) language withTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options;

@end
