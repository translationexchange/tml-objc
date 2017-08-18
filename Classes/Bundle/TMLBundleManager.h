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

@class TMLBundle, TMLAPIBundle;

extern NSString * const TMLBundleManagerErrorDomain;

typedef NS_ENUM(NSInteger, TMLBundleManagerErrorCode) {
    TMLBundleManagerInvalidApplicationKeyError = 1,
    TMLBundleManagerInvalidVersionError,
    TMLBundleManagerInvalidData,
    TMLBundleManagerIncompleteData,
    TMLBundleManagerUnsupportedArchive,
    TMLBundleManagerHTTPError
};

extern NSString * const TMLBundleManagerFilenameKey;
extern NSString * const TMLBundleManagerVersionKey;
extern NSString * const TMLBundleManagerURLKey;
extern NSString * const TMLBundleManagerPathKey;
extern NSString * const TMLBundleManagerErrorCodeKey;

extern NSString * const TMLBundleChangeInfoBundleKey;
extern NSString * const TMLBundleChangeInfoErrorsKey;

typedef void (^TMLBundleInstallBlock)(TMLBundle *bundle, NSError *error);

@interface TMLBundleManager : NSObject

+ (instancetype)defaultManager;


#pragma mark - Installation

@property (nonatomic, assign) NSUInteger maximumBundlesToKeep;

- (void) installBundleFromPath:(NSString *)aPath
               completionBlock:(TMLBundleInstallBlock)completionBlock;

- (void) installBundleFromURL:(NSURL *)aURL completionBlock:(TMLBundleInstallBlock)completionBlock;

- (void) installPublishedBundleWithVersion:(NSString *)version
                                   baseURL:(NSURL *)baseURL
                                   locales:(NSArray *)locales
                           completionBlock:(TMLBundleInstallBlock)completionBlock;

- (void) cleanup;
- (void) cleanupUsingApplicationKey:(NSString *)applicationKey;

#pragma mark - Query
- (NSArray *) installedBundles;
- (NSArray *) installedBundlesForApplicationKey:(NSString *)applicationKey;

- (TMLBundle *)bundleWithVersion:(NSString *)version applicationKey:(NSString *)applicationKey;
- (BOOL) isBundleInstalledWithVersion:(NSString *)version applicationKey:(NSString *)applicationKey;

- (TMLAPIBundle *)apiBundleForApplicationKey:(NSString *)applicationKey;
- (TMLBundle *)mainBundleForApplicationKey:(NSString *)appcalitionKey;
- (void)setMainBundle:(TMLBundle *)bundle forApplicationKey:(NSString *)applicationKey;

#pragma mark - Fetching

- (void) fetchPublishedBundleInfo:(NSURL *)baseURL
                       completion:(void(^)(NSDictionary *info, NSError *error))completionBlock;
- (void) fetchPublishedResources:(NSArray *)resourcePaths
                       forBundle:(TMLBundle *)bundle
                 completionBlock:(void(^)(BOOL success, NSArray *paths, NSArray *errors))completionBlock;
- (void) fetchPublishedResources:(NSArray *)resourcePaths
                         baseURL:(NSURL *)baseURL
                 destinationPath:(NSString *)destinationPath
                 completionBlock:(void(^)(BOOL success, NSArray *paths, NSArray *errors))completionBlock;

#pragma mark - Removing

- (void)removeAllBundles;


@end
