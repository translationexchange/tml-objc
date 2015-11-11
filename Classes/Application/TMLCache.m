/*
 *  Copyright (c) 2015 Translation Exchange, Inc. All rights reserved.
 *
 *  _______                  _       _   _             ______          _
 * |__   __|                | |     | | (_)           |  ____|        | |
 *    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
 *    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
 *    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
 *    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
 *                                                                                        __/ |
 *                                                                                       |___/
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

#import "NSObject+TMLJSON.h"
#import "NSString+TMLAdditions.h"
#import "TMLCache.h"
#import "TMLLogger.h"
#import <SSZipArchive/SSZipArchive.h>

@interface TMLCache()
@property(strong, nonatomic) NSString *appKey;
@property(strong, nonatomic) NSString *path;
@end

@implementation TMLCache

@synthesize appKey, path;

- (id) initWithKey: (NSString *) key {
    if (self == [super init]) {
        self.appKey = key;
        [self initCachePath];
    }
    return self;
}

- (void) initCachePath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    cachePath = [cachePath stringByAppendingPathComponent: @"TML"];
    cachePath = [cachePath stringByAppendingPathComponent: self.appKey];
    TMLDebug(@"Cache path: %@", cachePath);
    [self validatePath: cachePath];
    self.path = cachePath;
}

- (void) validatePath: (NSString *) cachePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath])
        return;
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        TMLDebug(@"Failed to create cache folder at %@", cachePath);
    }
}

- (NSString *) cachePathForKey: (NSString *) key {
    NSString *cachePath = self.path;

    NSArray *components = [key componentsSeparatedByString:@"/"];
    if ([components count] > 1) {
        cachePath = [NSString stringWithFormat:@"%@/%@", self.path, [[components subarrayWithRange:NSMakeRange(0, [components count]-1)] componentsJoinedByString:@"/"]];
        key = [components lastObject];
    }

    [self validatePath:cachePath];
    return [cachePath stringByAppendingPathComponent: [NSString stringWithFormat:@"/%@.json", key]];
}

- (NSObject *) fetchObjectForKey: (NSString *) key {
    NSString *objectPath = [self cachePathForKey: key];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:objectPath]) {
        TMLDebug(@"Cache miss: %@", key);
        return nil;
    }
    
    NSData *jsonData = [NSData dataWithContentsOfFile:objectPath];
    
    NSObject *result = [jsonData tmlJSONObject];
    
    if (result == nil) {
        TMLDebug(@"Error fetching object for key: %@", key);
        return nil;
    }
    
    TMLDebug(@"Cache hit: %@", key);
    return result;
}

- (void) removeItemAtPath: (NSString *) objectPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:objectPath]) {
        return;
    }
    
    NSError *error = nil;
    [fileManager removeItemAtPath:objectPath error:&error];
    
    if (error) {
        TMLDebug(@"Failed to reset cache for key: %@", self.path);
    }
}

- (BOOL) moveItemFrom: (NSString *) source to: (NSString *) target {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:source]) {
        return false;
    }
    
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:target]) {
        [fileManager removeItemAtPath:target error:&error];
    }
    
    [fileManager moveItemAtPath:source toPath:target error:&error];
    if (error) {
        TMLError(@"Failed to move file to path %@. Error: %@", target, error);
        return false;
    }
    
    return true;
}

- (NSString *) backupName: (NSString *) name {
    return [NSString stringWithFormat:@"%@.bak", name];
}

- (void) reset {
    [self moveItemFrom:self.path to:[self backupName:self.path]];
    [self validatePath: self.path];
}

- (void) resetCacheForKey: (NSString *) key {
    NSString *cachePath = [self cachePathForKey: key];
    [self moveItemFrom:cachePath to:[self backupName:cachePath]];
}

- (void) storeData: (NSData *) data forKey: (NSString *) key withOptions: (NSDictionary *) options {
    NSString *objectPath = [self cachePathForKey: key];
//    TMLDebug(@"Saving %@ to cache %@", key, objectPath);
    NSData *copy = [NSData dataWithData:data];
    [copy writeToFile:objectPath atomically:NO];
}

- (BOOL) backupCacheForLocale: (NSString *) locale {
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", self.path, locale];
    return [self moveItemFrom:cachePath to:[self backupName:cachePath]];
}

- (BOOL) restoreCacheBackupForLocale: (NSString *) locale {
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", self.path, locale];
    return [self moveItemFrom:[self backupName:cachePath] to:cachePath];
}

- (NSArray *) cachedLocales {
    NSFileManager *fM = [NSFileManager defaultManager];
    
    NSMutableArray *languages = [NSMutableArray array];
    
    NSError *error = nil;
    NSArray *fileList = [fM contentsOfDirectoryAtPath:self.path error:&error];

    for(NSString *file in fileList) {
        NSString *dirPath = [self.path stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fM fileExistsAtPath:dirPath isDirectory:(&isDir)];
        if(isDir) {
            NSString *locale = [[file componentsSeparatedByString:@"."] objectAtIndex:0];
            if ([languages indexOfObject:locale] == NSNotFound)
                [languages addObject:locale];
        }
    }
    
    return languages;
}

#pragma mark - Translation Bundles
- (NSString *)cachedBundleVersionInfoPath {
    return [NSString stringWithFormat:@"%@/version.json", self.path];
}

- (NSArray *)cachedTranslationBundlePaths {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *rootPath = self.path;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:rootPath error:&error];
    if (error != nil) {
        TMLError(@"Error getting contents of cache directory: %@", error);
        return nil;
    }
    NSArray *filteredPaths = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self matches '^[0-9]+$'"]];
    NSMutableArray *bundlePaths = [NSMutableArray array];
    BOOL isDir = NO;
    for (NSString *candidatePath in filteredPaths) {
        NSString *absolutePath = [NSString stringWithFormat:@"%@/%@", rootPath, candidatePath];
        if ([fileManager fileExistsAtPath:absolutePath isDirectory:&isDir] && isDir == YES) {
            [bundlePaths addObject:absolutePath];
        }
    }
    return [NSArray arrayWithArray:bundlePaths];
}

- (NSString *)currentTranslationBundleVersion {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *currentBundleLinkPath = [self cachePathForCurrentTranslationBundle];
    if ([fileManager fileExistsAtPath:currentBundleLinkPath isDirectory:nil] == NO) {
        return nil;
    }
    NSString *bundlePath = [currentBundleLinkPath stringByResolvingSymlinksInPath];
    NSString *version = [bundlePath tmlTranslationBundleVersionFromPath];
    return version;
}

- (NSString *)latestTranslationBundleVersion {
    NSArray *allBundlePaths = [self cachedTranslationBundlePaths];
    NSString *latestVersion = nil;
    for (NSString *bundlePath in allBundlePaths) {
        NSString *bundleVersion = [bundlePath tmlTranslationBundleVersionFromPath];
        if (latestVersion == nil
            || [latestVersion compareToTMLTranslationBundleVersion:bundleVersion] == NSOrderedAscending) {
            latestVersion = bundleVersion;
        }
    }
    return latestVersion;
}

- (NSString *)cachePathForTranslationBundleVersion:(NSString *)bundleVersion {
    return [NSString stringWithFormat:@"%@/%@", self.path, bundleVersion];
}

- (NSString *)cachePathForCurrentTranslationBundle {
    return [NSString stringWithFormat:@"%@/current", self.path];
}

- (void)installContentsOfTranslationBundleAtPath:(NSString *)aPath
                                      completion:(void(^)(NSString *destinationPath, BOOL success, NSError *error))completion
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:aPath isDirectory:nil] == NO) {
        TMLError(@"Tried to load contents of localization bundle but none could be found at path: %@", path);
        return;
    }
    NSString *bundleVersion = [[aPath lastPathComponent] tmlTranslationBundleVersionFromPath];
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), bundleVersion];
    [self validatePath:tempPath];
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
                    NSString *destinationPath = [self cachePathForTranslationBundleVersion:bundleVersion];
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
                    if (completion != nil) {
                        completion(destinationPath, success, error);
                    }
                }];
}

- (void)loadContentsOfTranslationBundleAtPath:(NSString *)aPath {
    [self installContentsOfTranslationBundleAtPath:aPath completion:^(NSString *destinationPath, BOOL success, NSError *error) {
        NSString *bundleVersion = nil;
        if (success == YES && destinationPath != nil) {
            bundleVersion = [destinationPath tmlTranslationBundleVersionFromPath];
        }
        if (bundleVersion != nil)
        [self selectCachedTranslationBundleWithVersion:bundleVersion];
    }];
}

- (void)selectCachedTranslationBundleWithVersion:(NSString *)version {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *versionedPath = [self cachePathForTranslationBundleVersion:version];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:versionedPath isDirectory:&isDir] == NO || isDir == NO) {
        TMLError(@"Cannot selecting cached bundle with version \"%@\"", version);
        return;
    }
    
    // create symlink to versioned path
    NSError *error = nil;
    NSString *currentBundlePath = [self cachePathForCurrentTranslationBundle];
    [fileManager removeItemAtPath:currentBundlePath error:nil];
    if ([fileManager createSymbolicLinkAtPath:currentBundlePath
                          withDestinationPath:[versionedPath lastPathComponent]
                                        error:&error] == NO) {
        TMLError(@"Error linking cached translation bundle as current: %@", error);
        return;
    }
    
    // Create/update version.json
    NSDictionary *info = @{@"version": version};
    NSData *data = [NSJSONSerialization dataWithJSONObject:info options:0 error:&error];
    if (data == nil) {
        TMLError(@"Error writing version info: %@", error);
        return;
    }
    NSString *versionInfoPath = [self cachedBundleVersionInfoPath];
    if ([data writeToFile:versionInfoPath options:NSDataWritingAtomic error:&error] == NO) {
        TMLError(@"Error saving version info: %@", error);
    }
}

@end
