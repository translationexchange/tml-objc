//
//  TMLBundle.h
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TMLBundleVersionFileName;
extern NSString * const TMLBundleApplicationFileName;
extern NSString * const TMLBundleVersionKey;

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
 *  Application info included in the bundle
 */
@property (readonly, nonatomic) TMLApplication *application;

@end
