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

@interface TMLBundle : NSObject

- (instancetype)initWithContentsOfDirectory:(NSString *)path;

@property (readonly, nonatomic) NSString *version;
@property (readonly, nonatomic) NSString *path;
@property (readonly, nonatomic) NSArray *languages;
@property (readonly, nonatomic) NSDictionary *applicationInfo;

@end
