//
//  TMLBundleManager.h
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

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

extern NSString * const TMLBundleContentsChangedNotification;
extern NSString * const TMLBundleSyncDidStartNotification;
extern NSString * const TMLBundleSyncDidFinishNotification;
extern NSString * const TMLBundleInstallationDidFinishNotification;

extern NSString * const TMLBundleChangeInfoBundleKey;
extern NSString * const TMLBundleChangeInfoErrorsKey;

typedef void (^TMLBundleInstallBlock)(NSString *path, NSError *error);

@interface TMLBundleManager : NSObject

+ (instancetype) defaultManager;

#pragma mark - Installation

@property (nonatomic, assign) NSUInteger maximumBundlesToKeep;
- (void) installBundleFromPath:(NSString *)aPath completionBlock:(TMLBundleInstallBlock)completionBlock;
- (void) installBundleFromURL:(NSURL *)aURL completionBlock:(TMLBundleInstallBlock)completionBlock;
- (void) installPublishedBundleWithVersion:(NSString *)version
                                   locales:(NSArray *)locales
                           completionBlock:(TMLBundleInstallBlock)completionBlock;
- (void) installResourceFromPath:(NSString *)resourcePath
          withRelativeBundlePath:(NSString *)relativeBundlePath
               intoBundleVersion:(NSString *)bundleVersion
                 completionBlock:(void(^)(NSString *path, NSError *error))completionBlock;

- (void) cleanup;

#pragma mark - Query

- (NSArray *) installedBundles;

#pragma mark - Fetching

- (void) fetchPublishedBundleInfo:(void(^)(NSDictionary *info, NSError *error))completionBlock;
- (void) fetchPublishedResources:(NSArray *)resourcePaths
                   bundleVersion:(NSString *)bundleVersion
                   baseDirectory:(NSString *)baseDirectory
                 completionBlock:(void(^)(BOOL success, NSArray *paths, NSArray *errors))completionBlock;

#pragma mark - Selection

@property (nonatomic, readonly) TMLBundle *latestBundle;
@property (nonatomic, readonly) TMLBundle *apiBundle;

#pragma mark - Notifications

- (void) notifyBundleMutation:(NSString *)mutationType
                       bundle:(TMLBundle *)bundle
                       errors:(NSArray *)errors;

@end
