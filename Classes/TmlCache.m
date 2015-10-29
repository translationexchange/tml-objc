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

#import "TmlCache.h"
#import "TmlLogger.h"

@interface TmlCache()
@property(strong, nonatomic) NSString *appKey;
@property(strong, nonatomic) NSString *path;
@end

@implementation TmlCache

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
    cachePath = [cachePath stringByAppendingPathComponent: @"Tml"];
    cachePath = [cachePath stringByAppendingPathComponent: self.appKey];
    TmlDebug(@"Cache path: %@", cachePath);
    [self validatePath: cachePath];
    self.path = cachePath;
}

- (void) validatePath: (NSString *) cachePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath])
        return;
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        TmlDebug(@"Failed to create cache folder at %@", cachePath);
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
    
//    TmlDebug(@"Loading %@ at path %@", key, objectPath);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:objectPath]) {
        TmlDebug(@"Cache miss: %@", key);
        return nil;
    }
    
    NSData *jsonData = [NSData dataWithContentsOfFile:objectPath];
//    NSString* jsonString = [NSString stringWithUTF8String:[jsonData bytes]];
//    TmlDebug(@"%@", jsonString);
    
    NSError *error = nil;
    NSObject *result = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        TmlDebug(@"Error trace: %@", error);
        return nil;
    }
    
    TmlDebug(@"Cache hit: %@", key);
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
        TmlDebug(@"Failed to reset cache for key: %@", self.path);
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
        TmlError(@"Failed to move file to path %@. Error: %@", target, error);
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
//    TmlDebug(@"Saving %@ to cache %@", key, objectPath);
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


@end
