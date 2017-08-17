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
#import "TMLGlobals.h"

@interface TMLConfiguration : NSObject

@property(nonatomic, strong) NSURL * _Nullable apiBaseURL;

@property(nonatomic, strong) NSURL * _Nullable translationCenterBaseURL;

@property(nonatomic, strong) NSURL * _Nullable gatewayBaseURL;

@property(nonatomic, strong) NSURL * _Nullable cdnBaseURL;

@property(nonnull, readonly) NSURL *cdnURL;

@property(nonatomic, readwrite) NSString * _Nullable accessToken;

@property(nonatomic, readonly) NSString * _Nullable applicationKey;

@property(nonatomic, strong) NSString * _Nullable defaultLocale;

@property(nonatomic, strong) NSString * _Nullable currentLocale;

@property(nonatomic, strong) NSString * _Nullable previousLocale;

@property(nonatomic, strong) NSString * _Nullable defaultSourceName;

@property(nonatomic, strong) NSMutableDictionary * _Nullable contextRules;

@property(nonatomic, strong) NSMutableDictionary * _Nullable defaultTokens;

@property(nonatomic, strong) NSMutableDictionary * _Nullable defaultLocalization;

@property(nonatomic, assign) BOOL localizeNIBStrings;

@property(nonatomic, assign) BOOL disallowTranslation;

#pragma mark - Automatic reloading
/**
 *  If YES, TMLKit will automatically reload UITableView instances when it's updating reusable localized strings
 * 
 *  Deprecated in favor of automaticallyReloadDataViews;
 */
@property (nonatomic, assign) BOOL automaticallyReloadTableViewsWithReusableLocalizedStrings __deprecated_msg("Use automaticallyReloadDataBackedViews instead");
/**
 *  If YES, TMLKit will automatically reload instances instances of data-backed views, UITableView and UICollectionView,
 *  when it's updating reusable localized strings.
 */
@property (nonatomic, assign) BOOL automaticallyReloadDataBackedViews;

#pragma mark - Submitting translaton keys
/**
 *  If YES, no translation keys will be submitted to the server, under any circumstances.
 *  This is a general safety switch for flooding server with data.
 */
@property (nonatomic, assign) BOOL neverSubmitNewTranslationKeys;


/**
 * Default timeout interval for network operations
 */
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForRequest;

#pragma mark -
- (instancetype)initWithApplicationKey:(NSString *)applicationKey
                           accessToken:(NSString *)accessToken __deprecated;
- (instancetype)initWithApplicationKey:(NSString *)applicationKey;
@property(readonly, nonatomic, getter=isValidConfiguration) BOOL validConfiguration;

- (NSString *) deviceLocale;

#pragma mark -

- (id) variableMethodForContext:(NSString *)keyword
                andVariableName:(NSString *)varName;
- (void) setVariableMethod:(id)method
                forContext:(NSString *)keyword
           andVariableName:(NSString *)varName;

#pragma mark - Default Tokens

- (id) defaultTokenValueForName:(NSString *)name;
- (id) defaultTokenValueForName:(NSString *)name
                           type:(TMLTokenType)type;
- (id) defaultTokenValueForName:(NSString *)name
                           type:(TMLTokenType)type
                         format:(TMLTokenFormat)format;

- (void) setDefaultTokenValue:(id)value
                      forName:(NSString *)name;
- (void) setDefaultTokenValue:(id)value
                      forName:(NSString *)name
                         type:(TMLTokenType)type;
- (void) setDefaultTokenValue:(id)value
                      forName:(NSString *)name
                         type:(TMLTokenType)type
                       format:(TMLTokenFormat)format;

#pragma mark - Dates
- (NSString *) customDateFormatForKey:(NSString *)key;
- (NSString *) dateTokenNameForKey:(NSString *)key;
- (NSObject *) dateValueForToken:(NSString *)token
                          inDate:(NSDate *)date;

#pragma mark - Analytics
@property (assign, nonatomic) BOOL analyticsEnabled;

#pragma mark - UI Customizations
@property (assign, nonatomic) BOOL translationAlertUsesBlur;

@end
