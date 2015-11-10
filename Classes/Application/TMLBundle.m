//
//  TMLBundle.m
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TML.h"
#import "TMLApplication.h"
#import "TMLBundle.h"
#import "TMLBundleManager.h"
#import "NSString+TmlAdditions.h"

NSString * const TMLBundleVersionFileName = @"snapshot.json";
NSString * const TMLBundleApplicationFileName = @"application.json";
NSString * const TMLBundleVersionKey = @"bundle";

@interface TMLBundle()
@property (readwrite, nonatomic) NSString *version;
@property (readwrite, nonatomic) NSString *path;
@property (readwrite, nonatomic) NSArray *languages;
@property (readwrite, nonatomic) NSDictionary *applicationInfo;
@end

@implementation TMLBundle

+ (instancetype)mainBundle {
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    TMLBundle *activeBundle = [bundleManager activeBundle];
    if (activeBundle == nil) {
        NSArray *bundles = [bundleManager installedBundles];
        if (bundles.count > 0) {
            bundles = [bundles sortedArrayUsingComparator:^NSComparisonResult(TMLBundle *a, TMLBundle *b) {
                NSString *aVersion = a.version;
                NSString *bVersion = b.version;
                return [aVersion compareToTMLTranslationBundleVersion:bVersion];
            }];
        }
        TMLBundle *latestBundle = [bundles lastObject];
        [bundleManager setActiveBundle:latestBundle];
        return latestBundle;
    }
    return activeBundle;
}

- (instancetype)initWithContentsOfDirectory:(NSString *)path {
    if (self = [super init]) {
        NSString *versionFilePath = [NSString stringWithFormat:@"%@/%@", path, TMLBundleVersionFileName];
        NSData *versionData = [NSData dataWithContentsOfFile:versionFilePath];
        NSError *error = nil;
        NSDictionary *versionInfo = [NSJSONSerialization JSONObjectWithData:versionData
                                                                    options:0
                                                                      error:&error];
        if (versionInfo == nil) {
            TMLError(@"Could not determine version of bundle at path: %@", path);
            return nil;
        }
        self.version = versionInfo[TMLBundleVersionKey];
        self.path = path;
        NSData *applicationData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", path, TMLBundleApplicationFileName]];
        NSDictionary *applicationInfo = [NSJSONSerialization JSONObjectWithData:applicationData
                                                                        options:0
                                                                          error:&error];
        if (applicationInfo == nil) {
            TMLError(@"Could not determin application info of bundle at path: %@", path);
            return nil;
        }
        self.applicationInfo = applicationInfo;
    }
    return self;
}

@end
