//
//  TMLBundleManager.m
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLApplication.h"
#import "TMLBundle.h"
#import "TMLBundleManager.h"
#import <SSZipArchive/SSZipArchive.h>

NSString * const TMLBundleManagerActiveBundleLinkName = @"active";

@implementation TMLBundleManager

+ (instancetype) defaultManager {
    static TMLBundleManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TMLBundleManager alloc] init];
    });
    return instance;
}

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        NSString *installPath = [self defaultBundleInstallationPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:installPath] == NO) {
            NSError *error = nil;
            if ([fileManager createDirectoryAtPath:installPath
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:&error] == NO) {
                TMLError(@"Error creating bundle install directory: %@", error);
                return nil;
            }
        }
    }
    return self;
}

#pragma mark - Installation

- (NSString *) defaultBundleInstallationPath {
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *parentPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *key = [[TML currentApplication] key];
        NSString *identifier = @"com.translationexchange.com";
        path = [NSString stringWithFormat:@"%@/%@/%@/Bundles", parentPath, identifier, key];
    });
    return path;
}

- (void) installBundleFromPath:(NSString *)aPath completionBlock:(TMLBundleInstallBlock)completionBlock {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:aPath isDirectory:nil] == NO) {
        TMLError(@"Tried to install TML bundle but none could be found at path: %@", aPath);
        return;
    }
    
    NSString *bundleName = [[aPath lastPathComponent] stringByDeletingPathExtension];
    NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", [self defaultBundleInstallationPath], bundleName];
    NSString *extension = [[aPath pathExtension] lowercaseString];
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), bundleName];
    
    if ([@"zip" isEqualToString:extension] == YES) {
        [SSZipArchive unzipFileAtPath:aPath
                        toDestination:tempPath
                            overwrite:YES
                             password:nil
                      progressHandler:nil
                    completionHandler:^(NSString *zipPath, BOOL succeeded, NSError *error) {
                        if (error != nil) {
                            TMLError(@"Error uncompressing local translation bundle: %@", error);
                        }
                        BOOL success = succeeded;
                        NSError *installError = error;
                        if (success == YES) {
                            if ([fileManager fileExistsAtPath:destinationPath] == YES) {
                                if ([fileManager removeItemAtPath:destinationPath error:&installError] == NO) {
                                    TMLError(@"Error removing old cached translation bundle: %@", installError);
                                    success = NO;
                                }
                            }
                        }
                        if (success == YES
                            && [fileManager moveItemAtPath:tempPath toPath:destinationPath error:&installError] == NO) {
                            TMLError(@"Error installing uncompressed translation bundle: %@", installError);
                            success = NO;
                        }
                        
                        if (completionBlock != nil) {
                            if (success == YES) {
                                completionBlock(destinationPath, error);
                            }
                            else {
                                completionBlock(nil, error);
                            }
                        }
                    }];
    }
}

- (void) installBundleFromURL:(NSURL *)aURL completionBlock:(TMLBundleInstallBlock)completionBlock {
    static NSString *downloadsPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadsPath = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    });
    
    NSString *filename = [[aURL absoluteString] lastPathComponent];
    NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", downloadsPath, filename];
    [[NSURLSession sharedSession] dataTaskWithURL:aURL
                                completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                    if ([data writeToFile:destinationPath atomically:YES] == YES) {
                                        [self installBundleFromPath:destinationPath completionBlock:completionBlock];
                                    }
                                    else {
                                        TMLError(@"Error installing bundle from URL: %@", aURL);
                                        if (completionBlock != nil) {
                                            completionBlock(nil, error);
                                        }
                                    }
                                }];
}

#pragma mark - Query

- (NSString *) fetchPublishedBundleInfo:(void(^)(NSDictionary *info, NSError *error))completionBlock {
    NSURL *publishedVersionURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://cdn.translationexchange.com/%@/version.json", [[TML currentApplication] key]]];
    NSData *data = [NSData dataWithContentsOfURL:publishedVersionURL];
    NSError *error = nil;
    NSDictionary *versionInfo = [data tmlJSONObject];
    if (versionInfo == nil) {
        TMLError(@"Error fetching published bundle info: %@", error);
        return nil;
    }
    return versionInfo[TMLBundleVersionKey];
}

- (NSArray *) installedBundles {
    NSString *installPath = [self defaultBundleInstallationPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:installPath isDirectory:nil] == NO) {
        return nil;
    }
    
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:installPath error:&error];
    if (contents == nil) {
        if (error != nil) {
            TMLError(@"Error getting contents of bundle installation directory: %@", error);
        }
        return nil;
    }
    
    NSMutableArray *bundles = [NSMutableArray array];
    for (NSString *path in contents) {
        TMLBundle *bundle = [[TMLBundle alloc] initWithContentsOfDirectory:path];
        if (bundle != nil) {
            [bundles addObject:bundle];
        }
    }
    return bundles;
}

#pragma mark - Selection

- (void)setActiveBundle:(TMLBundle *)bundle {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *link = [NSString stringWithFormat:@"%@/%@", [self defaultBundleInstallationPath], TMLBundleManagerActiveBundleLinkName];
    NSError *error = nil;
    [fileManager removeItemAtPath:link error:&error];
    if (error != nil) {
        TMLError(@"Error removing symlink to active bundle: %@", error);
    }
    
    NSString *path = bundle.path;
    [fileManager createSymbolicLinkAtPath:link withDestinationPath:path error:&error];
    if (error != nil) {
        TMLError(@"Error linking bundle as active: %@", error);
    }
}

- (TMLBundle *)activeBundle {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *activeBundlePath = [NSString stringWithFormat:@"%@/%@", [self defaultBundleInstallationPath], TMLBundleManagerActiveBundleLinkName];
    if ([fileManager fileExistsAtPath:activeBundlePath] == YES) {
        return [[TMLBundle alloc] initWithContentsOfDirectory:activeBundlePath];
    }
    return nil;
}

@end
