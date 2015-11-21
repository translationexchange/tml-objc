//
//  TMLBundle.h
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TMLBundleVersionFilename;
extern NSString * const TMLBundleApplicationFilename;
extern NSString * const TMLBundleSourcesFilename;
extern NSString * const TMLBundleVersionKey;
extern NSString * const TMLBundleURLKey;

@class TMLApplication;

@interface TMLBundle : NSObject

/**
 *  Returns main translation bundle. This bundle contains project definition, including
 *  available languages and translations. This method may return nil if there are no
 *  bundles available locally.
 *
 *  @return Main translation bundle, or nil, if none exist locally.
 */
+ (instancetype)mainBundle;

+ (instancetype)apiBundle;

- (instancetype)initWithContentsOfDirectory:(NSString *)path;

/**
 *  Bundle version
 */
@property (readonly, nonatomic) NSString *version;

/**
 *  Absolute path to the bundle on disk
 */
@property (readonly, nonatomic) NSString *path;

/**
 *  Array of languages contained in the bundle
 */
@property (readonly, nonatomic) NSArray *languages;

/**
 *  Array of locales for which there are locally stored translations
 */
@property (readonly, nonatomic) NSArray *availableLocales;

/**
 *  Array of locales supported by the bundle
 */
@property (readonly, nonatomic) NSArray *locales;

/**
 *  List of TMLSource names used in the bundle
 */
@property (readonly, nonatomic) NSArray *sources;

/**
 *  Application info included in the bundle
 */
@property (readonly, nonatomic) TMLApplication *application;

@property (readonly, nonatomic) NSURL *sourceURL;

#pragma mark - Synchronizing

- (void)synchronize:(void(^)(BOOL success))completion;
- (void)synchronizeApplicationData:(void (^)(BOOL))completion;
- (void)synchronizeLocales:(NSArray *)locales
                completion:(void (^)(BOOL))completion;

@end
