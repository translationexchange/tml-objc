//
//  TMLBundleManager.m
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLAPIBundle.h"
#import "TMLAPISerializer.h"
#import "TMLApplication.h"
#import "TMLBundle.h"
#import "TMLBundleManager.h"
#import <NVHTarGzip/NVHTarGzip.h>
#import <SSZipArchive/SSZipArchive.h>

NSString * const TMLBundleManagerErrorDomain = @"TMLBundleManagerErrorDomain";
NSString * const TMLBundleManagerActiveBundleLinkName = @"active";
NSString * const TMLBundleManagerVersionKey = @"version";
NSString * const TMLBundleManagerFilenameKey = @"filename";

NSString * const TMLBundleManagerAPIBundleDirectoryName = @"api";

@interface TMLBundleManager() {
    NSURLSession *_downloadSession;
    TMLBundle *_activeBundle;
}
@property(strong, nonatomic) NSURL *archiveURL;
@property(strong, nonatomic) TMLBundle *apiBundle;
@end

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
        self.archiveURL = [NSURL URLWithString:@"https://cdn.translationexchange.com"];
    }
    return self;
}

#pragma mark - Paths

- (NSString *)downloadDirectory {
    static NSString *downloadsPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadsPath = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    });
    return downloadsPath;
}

- (NSString *) defaultBundleInstallationPath {
    return [self bundleInstallationPathForApplicationKey:[[TML sharedInstance] applicationKey]];
}

- (NSString *)installPathForBundleVersion:(NSString *)version {
    return [NSString stringWithFormat:@"%@/%@", [self defaultBundleInstallationPath], version];
}

#pragma mark - Installation

- (NSString *) bundleInstallationPathForApplicationKey:(NSString *)applicationKey {
    static dispatch_once_t onceToken;
    static NSString *parentPath;
    dispatch_once(&onceToken, ^{
        parentPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    });
    NSString *identifier = @"com.translationexchange";
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@/Bundles", parentPath, identifier, applicationKey];
    return path;
}

- (void) installBundleFromPath:(NSString *)aPath completionBlock:(TMLBundleInstallBlock)completionBlock {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([fileManager fileExistsAtPath:aPath isDirectory:&isDirectory] == NO) {
        TMLError(@"Tried to install TML bundle but none could be found at path: %@", aPath);
        return;
    }
    
    NSString *bundleName = [aPath lastPathComponent];
    if (isDirectory == NO) {
        bundleName = [bundleName stringByDeletingPathExtension];
    }
    NSString *extension = [[aPath pathExtension] lowercaseString];
    
    if (isDirectory == YES) {
        NSString *applicationFilePath = [aPath stringByAppendingPathComponent:TMLBundleApplicationFilename];
        NSError *installError;
        BOOL success = YES;
        if ([fileManager fileExistsAtPath:applicationFilePath] == NO) {
            TMLError(@"Tried to install translation bundle, but no application description was found.");
            installError = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                               code:TMLBundleManagerInvalidApplicationKeyError
                                           userInfo:nil];
            success = NO;
        }
        
        TMLApplication *application;
        if (success == YES) {
            application = [TMLAPISerializer materializeData:[NSData dataWithContentsOfFile:applicationFilePath]
                                                  withClass:[TMLApplication class]
                                                   delegate:nil];
        }
        
        if (application.key == nil
            || [[[TML sharedInstance] applicationKey] isEqualToString:application.key] == NO) {
            installError = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                               code:TMLBundleManagerInvalidApplicationKeyError
                                           userInfo:nil];
            success = NO;
        }
        
        NSString *destinationPath;
        if (success == YES) {
            destinationPath = [NSString stringWithFormat:@"%@/%@", [self bundleInstallationPathForApplicationKey:application.key], bundleName];
            
//            if ([fileManager fileExistsAtPath:destinationPath] == YES) {
//                if ([fileManager removeItemAtPath:destinationPath error:&installError] == NO) {
//                    TMLError(@"Error removing old cached translation bundle: %@", installError);
//                    success = NO;
//                }
//            }
            NSString *destinationDir = [destinationPath stringByDeletingLastPathComponent];
            if ([fileManager fileExistsAtPath:destinationDir] == NO) {
                if ([fileManager createDirectoryAtPath:destinationDir
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:&installError] == NO) {
                    TMLError(@"Error creating bundle installation directory: %@", installError);
                    success = NO;
                }
            }
            if (success == YES
                && [aPath isEqualToString:destinationPath] == NO
                && [fileManager moveItemAtPath:aPath toPath:destinationPath error:&installError] == NO) {
                TMLError(@"Error installing uncompressed translation bundle: %@", installError);
                success = NO;
            }
        }
        
        
        if (completionBlock != nil) {
            if (success == YES) {
                completionBlock(destinationPath, installError);
            }
            else {
                completionBlock(nil, installError);
            }
        }
    }
    else if ([@"zip" isEqualToString:extension] == YES) {
        [self installBundleFromZipArchive:aPath
                          completionBlock:completionBlock];
    }
    else if ([@[@"gzip", @"gz", @"tar", @"tar.gz", @"tar.gzip"] containsObject:extension] == YES) {
        [self installBundleFromTarball:aPath
                       completionBlock:completionBlock];
    } else {
        TMLError(@"Don't know how to install bundle from path '%@'", aPath);
        if (completionBlock != nil) {
            NSError *error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                                 code:TMLBundleManagerUnsupportedArchive
                                             userInfo:@{
                                                        TMLBundleManagerFilenameKey: aPath
                                                        }];
            completionBlock(nil, error);
        }
    }
}

- (void) installBundleFromZipArchive:(NSString *)aPath
                     completionBlock:(TMLBundleInstallBlock)completionBlock
{
    NSString *bundleName = [[aPath lastPathComponent] stringByDeletingPathExtension];
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), bundleName];
    [SSZipArchive unzipFileAtPath:aPath
                    toDestination:tempPath
                        overwrite:YES
                         password:nil
                  progressHandler:nil
                completionHandler:^(NSString *zipPath, BOOL succeeded, NSError *error) {
                    if (error != nil) {
                        TMLError(@"Error uncompressing local translation bundle: %@", error);
                    }
                    if (succeeded == YES) {
                        [self installBundleFromPath:zipPath completionBlock:^(NSString *path, NSError *error) {
                            if (error != nil) {
                                NSFileManager *fileManager = [NSFileManager defaultManager];
                                NSError *fileManagerError;
                                if ([fileManager removeItemAtPath:zipPath error:&fileManagerError] == NO) {
                                    TMLWarn(@"Could not remove temporary zip extraction directory '%@'. Error: %@", zipPath, error);
                                }
                            }
                            if (completionBlock != nil) {
                                completionBlock(path, error);
                            }
                        }];
                    }
                    else if (completionBlock != nil) {
                        completionBlock(nil, error);
                    }
                }];
}

- (void) installBundleFromTarball:(NSString *)aPath
                  completionBlock:(TMLBundleInstallBlock)completionBlock
{
    NSString *bundleName = [[aPath lastPathComponent] stringByDeletingPathExtension];
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), bundleName];
    NSString *lowercasePath = [aPath lowercaseString];
    void(^finish)(NSError *) = ^(NSError *error){
        if (error != nil) {
            TMLError(@"Error extracting bundle from archive '%@' %@", aPath, error);
            if (completionBlock != nil) {
                completionBlock(nil, error);
            }
        }
        else {
            [self installBundleFromPath:tempPath
                        completionBlock:completionBlock];
        }
    };
    if ([lowercasePath hasSuffix:@"tar.gz"] == YES
        || [lowercasePath hasSuffix:@"tar.gzip"] == YES) {
        [[NVHTarGzip sharedInstance] unTarGzipFileAtPath:aPath
                                                  toPath:tempPath
                                              completion:finish];
        return;
    }
    NSString *extension = [lowercasePath pathExtension];
    if ([@"gzip" isEqualToString:extension] == YES
        || [@"gz" isEqualToString:extension] == YES) {
        [[NVHTarGzip sharedInstance] unGzipFileAtPath:aPath
                                               toPath:tempPath
                                           completion:finish];
        return;
    }
    else if ([@"tar" isEqualToString:extension] == YES) {
        [[NVHTarGzip sharedInstance] unTarFileAtPath:aPath
                                              toPath:tempPath
                                          completion:finish];
        return;
    }
    
    if (completionBlock != nil) {
        NSError *error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                             code:TMLBundleManagerUnsupportedArchive
                                         userInfo:@{
                                                    TMLBundleManagerFilenameKey: aPath
                                                    }];
        completionBlock(nil, error);
    }
}

- (void) installBundleFromURL:(NSURL *)aURL completionBlock:(TMLBundleInstallBlock)completionBlock {
    NSString *downloadsPath = [self downloadDirectory];
    NSString *filename = [[aURL absoluteString] lastPathComponent];
    NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", downloadsPath, filename];
    [[[NSURLSession sharedSession] dataTaskWithURL:aURL
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
                                }] resume];
}

- (void) installPublishedBundleWithVersion:(NSString *)version
                                   locales:(NSArray *)locales
                           completionBlock:(TMLBundleInstallBlock)completionBlock
{
    // Sanity checks
    NSError *error;
    NSString *appKey = [[TML sharedInstance] applicationKey];
    if (version == nil) {
        TMLError(@"Tried to install published bundle w/o a version string");
        error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                    code:TMLBundleManagerInvalidVersionError
                                userInfo:nil];
    }
    else if (appKey == nil) {
        TMLError(@"Tried to install published bundle w/o valid application key");
        error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                    code:TMLBundleManagerInvalidApplicationKeyError
                                userInfo:nil];
    }
    if (error != nil) {
        if (completionBlock != nil) {
            completionBlock(nil, error);
        }
        return;
    }
    
    __block NSMutableArray *resources = [NSMutableArray arrayWithArray:@[@"application.json", @"snapshot.json"]];
    if (locales.count > 0) {
        for (NSString *locale in locales) {
            [resources addObject:[NSString stringWithFormat:@"%@/languages.json", locale]];
            [resources addObject:[NSString stringWithFormat:@"%@/translations.json", locale]];
        }
    }
    
    NSString *bundleDestinationPath = [NSString stringWithFormat:@"%@/%@", [self downloadDirectory], version];
    [self fetchPublishedResource:@"sources.json"
                   bundleVersion:version
                   baseDirectory:bundleDestinationPath
                 completionBlock:^(NSString *path, NSError *error) {
                     if (path != nil && locales.count > 0) {
                         NSArray *sources = [[NSData dataWithContentsOfFile:path] tmlJSONObject];
                         for (NSString *source in sources) {
                             for (NSString *locale in locales) {
                                 [resources addObject:[NSString stringWithFormat:@"%@/sources/%@.json", locale, source]];
                             }
                         }
                     }
                     [self fetchPublishedResources:resources
                                     bundleVersion:version
                                     baseDirectory:bundleDestinationPath
                                   completionBlock:^(BOOL success, NSArray *paths, NSArray *errors) {
                                       if (success == YES) {
                                           [self installBundleFromPath:bundleDestinationPath
                                                       completionBlock:completionBlock];
                                       }
                                       else if (completionBlock != nil) {
                                           NSError *error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                                                                code:TMLBundleManagerIncompleteData
                                                                            userInfo:nil];
                                           completionBlock(bundleDestinationPath, error);
                                       }
                     }];
    }];
}

#pragma mark - Downloading

- (void) fetchPublishedResources:(NSArray *)resourcePaths
                   bundleVersion:(NSString *)bundleVersion
                   baseDirectory:(NSString *)baseDirectory
                 completionBlock:(void(^)(BOOL success, NSArray *paths, NSArray *errors))completionBlock
{
    __block NSInteger count = 0;
    __block BOOL success = YES;
    __block NSMutableArray *paths = [NSMutableArray array];
    __block NSMutableArray *errors = [NSMutableArray array];
    for (NSString *resourcePath in resourcePaths) {
        [self fetchPublishedResource:resourcePath
                       bundleVersion:bundleVersion
                       baseDirectory:baseDirectory
                     completionBlock:^(NSString *path, NSError *error) {
                         count++;
                         if (error != nil) {
                             [errors addObject:error];
                             success = NO;
                         }
                         else if (paths != nil) {
                             [paths addObject:path];
                         }
                         if (count == resourcePaths.count
                             && completionBlock != nil) {
                             completionBlock(success, [paths copy], [error copy]);
                         }
                     }];
    }
}

- (void) fetchPublishedResource:(NSString *)resourcePath
                  bundleVersion:(NSString *)bundleVersion
                  baseDirectory:(NSString *)baseDirectory
                completionBlock:(void(^)(NSString *path, NSError *error))completionBlock
{
    if (baseDirectory == nil) {
        baseDirectory = [[self downloadDirectory] stringByAppendingPathComponent:bundleVersion];
    }
    NSString *destination = [baseDirectory stringByAppendingPathComponent:resourcePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check if the file already exists. We may have downloaded it previously
    // but the entire bundle failed to download, so the file is left over
    if ([fileManager fileExistsAtPath:destination] == YES) {
        if (completionBlock != nil) {
            completionBlock(destination, nil);
        }
        return;
    }
    
    NSError *error;
    NSString *destinationDir = [destination stringByDeletingLastPathComponent];
    
    if ([fileManager fileExistsAtPath:destinationDir] == NO) {
        if ([fileManager createDirectoryAtPath:destinationDir
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error] == NO) {
            TMLError(@"Error creating bundle resource destination directory: '%@': %@", destinationDir, error);
        }
    }
    if (error != nil) {
        if (completionBlock != nil) {
            completionBlock(nil, error);
        }
        return;
    }
    
    NSURLSession *downloadSession = [self downloadSession];
    NSURL *resourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@",
                                               [self archiveURL],
                                               [[TML sharedInstance] applicationKey],
                                               bundleVersion,
                                               resourcePath]];
    [[downloadSession dataTaskWithURL:resourceURL
                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                       NSError *ourError = error;
                       if (data != nil) {
                           if ([data writeToFile:destination options:NSDataWritingAtomic error:&ourError] == NO) {
                               TMLError(@"Error writing fetched bundle resource '%@': %@", resourcePath, ourError);
                           }
                       }
                       if (completionBlock != nil) {
                           completionBlock((error) ? nil : destination, error);
                       }
                   }] resume];
}

- (NSURLSession *)downloadSession {
    if (_downloadSession == nil) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _downloadSession = [NSURLSession sessionWithConfiguration:config];
    }
    return _downloadSession;
}

- (void) fetchPublishedBundleInfo:(void(^)(NSDictionary *info, NSError *error))completionBlock {
    NSError *error = nil;
    NSString *applicationKey = [[TML sharedInstance] applicationKey];
    if (applicationKey == nil) {
        error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                    code:TMLBundleManagerInvalidApplicationKeyError
                                userInfo:nil];
        TMLError(@"Tried to fetch published bundle info w/o valid application key");
    }
    
    if (error == nil) {
        NSURL *publishedVersionURL = [self.archiveURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/version.json", applicationKey]];
        NSURLSession *urlSession = [self downloadSession];
        [[urlSession dataTaskWithURL:publishedVersionURL
                  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                      NSDictionary *versionInfo;
                      if (data != nil) {
                          versionInfo = [data tmlJSONObject];
                      }
                      else {
                          TMLError(@"Error fetching published bundle info: %@", error);
                      }
                      if (completionBlock != nil) {
                          completionBlock(versionInfo, error);
                      }
                  }] resume];
    }
}

- (void) installResourceFromPath:(NSString *)resourcePath
          withRelativeBundlePath:(NSString *)relativeBundlePath
               intoBundleVersion:(NSString *)bundleVersion
                 completionBlock:(void(^)(NSString *path, NSError *error))completionBlock
{
    NSString *bundleRootPath = [self installPathForBundleVersion:bundleVersion];
    NSString *destinationPath = [bundleRootPath stringByAppendingPathComponent:relativeBundlePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *destinationRoot = [destinationPath stringByDeletingLastPathComponent];
    NSError *error;
    if ([fileManager fileExistsAtPath:destinationRoot] == NO) {
        if ([fileManager createDirectoryAtPath:destinationRoot
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error] == NO){
            TMLError(@"Error creating installation directory for resource '%@': %@", relativeBundlePath, error);
        }
    }
    if (error == nil
        && [resourcePath isEqualToString:destinationPath] == NO) {
        if ([fileManager moveItemAtPath:resourcePath toPath:destinationPath error:&error] == NO) {
            TMLError(@"Error installing resource '%@' for bundle '%@': %@", relativeBundlePath, bundleVersion, error);
        }
    }
    if (completionBlock != nil) {
        completionBlock((error) ? nil : destinationPath, error);
    }
}

#pragma mark - Query

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
        TMLBundle *bundle = [[TMLBundle alloc] initWithContentsOfDirectory:[installPath stringByAppendingPathComponent:path]];
        if (bundle != nil) {
            [bundles addObject:bundle];
        }
    }
    return bundles;
}

#pragma mark - Active Bundle

- (void)setActiveBundle:(TMLBundle *)bundle {
    if (_activeBundle == bundle) {
        return;
    }
    
    if (_activeBundle == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *link = [NSString stringWithFormat:@"%@/%@", [self defaultBundleInstallationPath], TMLBundleManagerActiveBundleLinkName];
        NSError *error = nil;
        NSDictionary *attrs = [fileManager attributesOfItemAtPath:link error:&error];
        if (attrs != nil
            && [fileManager removeItemAtPath:link error:&error] == NO) {
            TMLError(@"Error removing symlink to active bundle: %@", error);
        }
        
        NSString *path = bundle.path;
        if ([fileManager createSymbolicLinkAtPath:link withDestinationPath:path error:&error] == NO) {
            TMLError(@"Error linking bundle as active: %@", error);
        }
        _activeBundle = bundle;
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

#pragma mark - API Bundle

- (TMLBundle *)apiBundle {
    if (_apiBundle == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *apiBundleDir = [[self defaultBundleInstallationPath] stringByAppendingPathComponent:TMLBundleManagerAPIBundleDirectoryName];
        NSError *error;
        if ([fileManager fileExistsAtPath:apiBundleDir] == NO) {
            if ([fileManager createDirectoryAtPath:apiBundleDir
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:&error] == NO) {
                TMLError(@"Error creating directory structure for API bundle: %@", error);
                return _apiBundle;
            }
        }
        _apiBundle = [[TMLAPIBundle alloc] initWithContentsOfDirectory:apiBundleDir];
    }
    return _apiBundle;
}

@end
