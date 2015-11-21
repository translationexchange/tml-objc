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
    TMLBundleManagerInvalidApplicationKeyError,
    TMLBundleManagerInvalidVersionError,
    TMLBundleManagerInvalidData,
    TMLBundleManagerIncompleteData
};

extern NSString * const TMLBundleManagerVersionKey;

typedef void (^TMLBundleInstallBlock)(NSString *path, NSError *error);

@interface TMLBundleManager : NSObject

+ (instancetype) defaultManager;

#pragma mark - Installation

- (void) installBundleFromPath:(NSString *)aPath completionBlock:(TMLBundleInstallBlock)completionBlock;
- (void) installBundleFromURL:(NSURL *)aURL completionBlock:(TMLBundleInstallBlock)completionBlock;
- (void) installPublishedBundleWithVersion:(NSString *)version
                                   locales:(NSArray *)locales
                           completionBlock:(TMLBundleInstallBlock)completionBlock;

#pragma mark - Query

- (void) fetchPublishedBundleInfo:(void(^)(NSDictionary *info, NSError *error))completionBlock;
- (NSArray *) installedBundles;

#pragma mark - Selection

- (void) setActiveBundle:(TMLBundle *)bundle;
- (TMLBundle *)activeBundle;

@end
