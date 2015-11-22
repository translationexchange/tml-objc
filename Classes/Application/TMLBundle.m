//
//  TMLBundle.m
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "NSString+TmlAdditions.h"
#import "TML.h"
#import "TMLAPISerializer.h"
#import "TMLApplication.h"
#import "TMLBundle.h"
#import "TMLBundleManager.h"

NSString * const TMLBundleVersionFilename = @"snapshot.json";
NSString * const TMLBundleApplicationFilename = @"application.json";
NSString * const TMLBundleSourcesFilename = @"sources.json";
NSString * const TMLBundleTranslationsFilename = @"translations.json";
NSString * const TMLBundleLanguageFilename = @"language.json";
NSString * const TMLBundleSourcesRelativePath = @"sources";

NSString * const TMLBundleVersionKey = @"version";
NSString * const TMLBundleURLKey = @"url";

@interface TMLBundle()
@property (readwrite, nonatomic) NSString *version;
@property (readwrite, nonatomic) NSString *path;
@property (readwrite, nonatomic) NSArray *languages;
@property (readwrite, nonatomic) NSDictionary *translations;
@property (readwrite, nonatomic) NSArray *availableLocales;
@property (readwrite, nonatomic) NSArray *locales;
@property (readwrite, nonatomic) TMLApplication *application;
@property (readwrite, nonatomic) NSArray *sources;
@property (readwrite, nonatomic) NSURL *sourceURL;
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
        if (latestBundle != nil) {
            [bundleManager setActiveBundle:latestBundle];
        }
        return latestBundle;
    }
    return activeBundle;
}

+ (instancetype)apiBundle {
    return [[TMLBundleManager defaultManager] apiBundle];
}

- (instancetype)initWithContentsOfDirectory:(NSString *)path {
    if (self = [super init]) {
        self.path = path;
    }
    return self;
}

- (void)resetData {
    self.languages = nil;
    self.sources = nil;
    self.application = nil;
    self.version = nil;
    self.sourceURL = nil;
}

- (void)reload {
    [self resetData];
}

- (void)reloadVersionInfo {
    NSString *path = [self.path stringByAppendingPathComponent:TMLBundleVersionFilename];
    NSData *versionData = [NSData dataWithContentsOfFile:path];
    NSDictionary *versionInfo = [versionData tmlJSONObject];
    if (versionInfo == nil) {
        TMLError(@"Could not determine version of bundle at path: %@", path);
    }
    else {
        self.version = versionInfo[TMLBundleVersionKey];
        self.sourceURL = [NSURL URLWithString:versionInfo[TMLBundleURLKey]];
    }
}

- (void)reloadApplicationData {
    NSString *path = [self.path stringByAppendingPathComponent:TMLBundleApplicationFilename];
    NSData *applicationData = [NSData dataWithContentsOfFile:path];
    NSDictionary *applicationInfo = [applicationData tmlJSONObject];
    if (applicationInfo == nil) {
        TMLError(@"Could not determine application info of bundle at path: %@", path);
    }
    else {
        self.application = [TMLAPISerializer materializeObject:applicationInfo
                                                     withClass:[TMLApplication class]
                                                      delegate:nil];
    }
}

- (void)reloadSourcesData {
    NSString *path = [self.path stringByAppendingPathComponent:TMLBundleSourcesFilename];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *sources = [data tmlJSONObject];
    if (sources == nil) {
        TMLError(@"Could not determine list of sources at path: %@", path);
    }
    else {
        self.sources = sources;
    }
}

- (void)reloadAvailableLocales {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.path error:&error];
    NSMutableArray *locales = [NSMutableArray array];
    if (contents == nil) {
        TMLError(@"Error listing available bundle locales: %@", error);
    }
    else {
        BOOL isDir = NO;
        for (NSString *path in contents) {
            if ([fileManager fileExistsAtPath:path isDirectory:&isDir] == YES
                && isDir == YES) {
                [locales addObject:[path lastPathComponent]];
            }
        }
    }
    self.availableLocales = locales;
}

#pragma mark - Accessors

- (NSString *)version {
    if (_version == nil) {
        [self reloadVersionInfo];
    }
    return _version;
}

- (NSURL *)sourceURL {
    if (_sourceURL == nil) {
        [self reloadVersionInfo];
    }
    return _sourceURL;
}

- (TMLApplication *)application {
    if (_application == nil) {
        [self reloadApplicationData];
    }
    return _application;
}

- (NSArray *)sources {
    if (_sources == nil) {
        [self reloadSourcesData];
    }
    return _sources;
}

- (NSArray *)availableLocales {
    if (_availableLocales == nil) {
        [self reloadAvailableLocales];
    }
    return _availableLocales;
}

- (NSArray *)locales {
    NSArray *langs = self.languages;
    return [langs valueForKeyPath:@"locale"];
}

- (NSArray *)languages {
    TMLApplication *app = self.application;
    return app.languages;
}

#pragma mark - Synchronization

- (void)synchronize:(void (^)(BOOL))completion {
    NSURL *url = self.sourceURL;
    TMLBundleManager *manager = [TMLBundleManager defaultManager];
    [manager installBundleFromURL:url completionBlock:^(NSString *path, NSError *error) {
        if (path != nil && error == nil) {
            TMLInfo(@"Bundle successfully synchronized: %@", path);
        }
        else {
            TMLError(@"Bundle failed to synchronize: %@", error);
        }
    }];
}

- (void)synchronizeApplicationData:(void (^)(BOOL))completion {
    NSString *version = self.version;
    NSArray *paths = @[
                       TMLBundleApplicationFilename,
                       TMLBundleSourcesFilename,
                       TMLBundleVersionFilename
                       ];
    
    [[TMLBundleManager defaultManager] fetchPublishedResources:paths
                                                 bundleVersion:version
                                                 baseDirectory:nil
                                               completionBlock:^(BOOL success, NSArray *paths, NSArray *errors) {
                                                   [self installResources:paths completion:completion];
                                               }];
}

- (void)synchronizeLocales:(NSArray *)locales
                completion:(void (^)(BOOL))completion
{
    NSString *version = self.version;
    NSMutableArray *paths = [NSMutableArray array];
    NSArray *sources = [self sources];
    for (NSString *locale in locales) {
        [paths addObject:[locale stringByAppendingPathComponent:TMLBundleLanguageFilename]];
        [paths addObject:[locale stringByAppendingPathComponent:TMLBundleTranslationsFilename]];
        for (NSString *source in sources) {
            [paths addObject:[[locale stringByAppendingPathComponent:TMLBundleSourcesRelativePath] stringByAppendingPathComponent:source]];
        }
    }
    
    [[TMLBundleManager defaultManager] fetchPublishedResources:paths
                                                 bundleVersion:version
                                                 baseDirectory:nil
                                               completionBlock:^(BOOL success, NSArray *paths, NSArray *errors) {
                                                   [self installResources:paths completion:completion];
                                               }];
}

- (void)installResources:(NSArray *)resourcePaths
              completion:(void(^)(BOOL))completion
{
    if (resourcePaths.count == 0) {
        if (completion != nil) {
            completion(YES);
        }
        return;
    }
    __block NSInteger count = 0;
    NSString *version = self.version;
    __block BOOL success = YES;
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    for (NSString *path in resourcePaths) {
        NSArray *pathComponents = [path pathComponents];
        NSInteger index = [pathComponents indexOfObject:version];
        NSString *relativePath = nil;
        if (index < pathComponents.count - 1) {
            relativePath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(index+1, pathComponents.count - index - 1)]];
        }
        if (relativePath == nil) {
            success = NO;
            continue;
        }
        [bundleManager installResourceFromPath:path
                        withRelativeBundlePath:relativePath
                             intoBundleVersion:version
                               completionBlock:^(NSString *path, NSError *error) {
                                   count++;
                                   if (error != nil) {
                                       success = NO;
                                   }
                                   if (count == resourcePaths.count) {
                                       [self reload];
                                       if (completion != nil) {
                                           completion(success);
                                       }
                                   }
                               }];
    }
}

@end
