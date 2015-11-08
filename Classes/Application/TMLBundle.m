//
//  TMLBundle.m
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TMLBundle.h"
#import "TML.h"
#import "TMLApplication.h"

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
