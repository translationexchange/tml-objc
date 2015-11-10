//
//  TMLBundleManager.h
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TMLBundleInstallBlock)(NSString *path, NSError *error);

@interface TMLBundleManager : NSObject

+ (instancetype) defaultManager;

#pragma mark - Installation

- (void) installBundleFromPath:(NSString *)aPath completionBlock:(TMLBundleInstallBlock)completionBlock;
- (void) installBundleFromURL:(NSURL *)aURL completionBlock:(TMLBundleInstallBlock)completionBlock;

#pragma mark - Query

- (NSString *) fetchPublishedBundleInfo:(void(^)(NSDictionary *info, NSError *error))completionBlock;
- (NSArray *) installedBundles;

#pragma mark - Selection

- (void) setActiveBundle:(TMLBundle *)bundle;
- (TMLBundle *)activeBundle;

@end
