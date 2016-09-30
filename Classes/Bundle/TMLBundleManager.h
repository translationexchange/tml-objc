//
//  TMLBundleManager.h
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

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
