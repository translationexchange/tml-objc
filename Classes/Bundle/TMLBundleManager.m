//
//  TMLBundleManager.m
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "NSString+TML.h"
#import "NSURL+TML.h"
#import "TML.h"
#import "TMLAPIBundle.h"
#import "TMLAPISerializer.h"
#import "TMLApplication.h"
#import "TMLBundle.h"
#import "TMLBundleManager.h"
#import <NVHTarGzip/NVHTarGzip.h>
#import <SSZipArchive/SSZipArchive.h>

NSString * const TMLBundleManagerErrorDomain = @"TMLBundleManagerErrorDomain";
NSString * const TMLBundleManagerLatestBundleLinkName = @"latest";
NSString * const TMLBundleManagerVersionKey = @"version";
NSString * const TMLBundleManagerFilenameKey = @"filename";
NSString * const TMLBundleManagerURLKey = @"url";
NSString * const TMLBundleManagerPathKey = @"path";
NSString * const TMLBundleManagerErrorCodeKey = @"code";

NSString * const TMLBundleManagerAPIBundleDirectoryName = @"api";

NSString * const TMLBundleChangeInfoBundleKey = @"bundle";
NSString * const TMLBundleChangeInfoErrorsKey = @"errors";

#define DEFAULT_URL_TASK_TIMEOUT 60.

@interface TMLBundleManager() {
    NSURLSession *_downloadSession;
    TMLBundle *_latestBundle;
    NSMutableDictionary *_registry;
}
@property(strong, nonatomic) NSURL *archiveURL;
@property(strong, nonatomic) TMLBundle *apiBundle;
@property(strong, nonatomic) NSString *rootDirectory;
@property(strong, nonatomic) NSString *applicationKey;
@end

@implementation TMLBundleManager

+ (instancetype) defaultManager {
    NSString *applicationKey = TMLApplicationKey();
    NSURL *cdnURL = TMLSharedConfiguration().cdnURL;
    if (applicationKey == nil || cdnURL == nil) {
        TMLRaiseUnconfiguredIncovation();
        return nil;
    }
    
    static TMLBundleManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TMLBundleManager alloc] initWithApplicationKey:applicationKey archiveURL:cdnURL];
    });
    return instance;
}

+ (NSString *) applicationSupportDirectory {
    static dispatch_once_t onceToken;
    static NSString *path;
    dispatch_once(&onceToken, ^{
        path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *identifier = [[NSBundle bundleForClass:[TML class]] bundleIdentifier];
        path = [path stringByAppendingPathComponent:identifier];
        
    });
    return path;
}

+ (NSString *) bundleDirectoryForApplicationKey:(NSString *)applicationKey {
    NSString *path = [[self applicationSupportDirectory] stringByAppendingPathComponent:applicationKey];
    return path;
}

#pragma mark - Init

- (instancetype)init {
    TMLRaiseAlternativeInstantiationMethod(@selector(initWithApplicationKey:archiveURL:));
    return nil;
}

- (instancetype)initWithApplicationKey:(NSString *)applicationKey archiveURL:(NSURL *)archiveURL{
#if DEBUG
    NSAssert(applicationKey.length > 0, @"application key cannot be empty");
#endif
    if (self = [super init]) {
        self.archiveURL = archiveURL;
        self.maximumBundlesToKeep = 2;
        self.applicationKey = applicationKey;
        self.rootDirectory = [[self class] bundleDirectoryForApplicationKey:applicationKey];
    }
    return self;
}

#pragma mark - Paths

- (NSString *)downloadDirectory {
    NSString *downloadPath = [[self.class applicationSupportDirectory] stringByAppendingPathComponent:@"Downloads"];
    return downloadPath;
}

- (NSString *)installPathForBundleVersion:(NSString *)version {
    return [NSString stringWithFormat:@"%@/%@.bundle", self.rootDirectory, version];
}

#pragma mark - Installation

- (void) installBundleFromPath:(NSString *)aPath completionBlock:(TMLBundleInstallBlock)completionBlock {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([fileManager fileExistsAtPath:aPath isDirectory:&isDirectory] == NO) {
        TMLError(@"Tried to install TML bundle but none could be found at path: %@", aPath);
        if (completionBlock != nil) {
            NSError *installError = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                                        code:TMLBundleInvalidResourcePath
                                                    userInfo:@{TMLBundleErrorResourcePathKey: aPath}];
            completionBlock(nil, installError);
        }
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
                                                  withClass:[TMLApplication class]];
        }
        
        if (application.key == nil
            || [self.applicationKey isEqualToString:application.key] == NO) {
            installError = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                               code:TMLBundleManagerInvalidApplicationKeyError
                                           userInfo:nil];
            success = NO;
        }
        
        NSString *destinationPath;
        if (success == YES) {
            destinationPath = [self installPathForBundleVersion:bundleName];
            
            NSString *destinationDir = [destinationPath stringByDeletingLastPathComponent];
            if ([fileManager fileExistsAtPath:destinationDir] == YES) {
                if([fileManager removeItemAtPath:destinationDir error:&installError] == NO) {
                    TMLError(@"Error removing existing bundle installation path: %@", installError);
                    success = NO;
                }
            }
            if (success == YES
                && [fileManager createDirectoryAtPath:destinationDir
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:&installError] == NO) {
                TMLError(@"Error creating bundle installation directory: %@", installError);
                success = NO;
            }
            if (success == YES
                && [aPath isEqualToString:destinationPath] == NO
                && [fileManager moveItemAtPath:aPath toPath:destinationPath error:&installError] == NO) {
                TMLError(@"Error installing uncompressed translation bundle: %@", installError);
                success = NO;
            }
        }
        
        if (success == YES) {
            TMLBundle *installedBundle = [[TMLBundle alloc] initWithContentsOfDirectory:destinationPath];
            self.latestBundle = installedBundle;
        }
        [self cleanup];
        completionBlock((success == YES) ? destinationPath : nil, installError);
        if (success == YES) {
            [self notifyBundleMutation:TMLLocalizationUpdatesInstalledNotification
                                bundle:self.latestBundle
                                errors:nil];
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
    [self fetchURL:aURL
   completionBlock:^(NSData *data, NSURLResponse *response, NSError *error) {
       if (error == nil
           && data != nil
           && [data writeToFile:destinationPath atomically:YES] == YES) {
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

- (void) installPublishedBundleWithVersion:(NSString *)version
                                   locales:(NSArray *)locales
                           completionBlock:(TMLBundleInstallBlock)completionBlock
{
    // Sanity checks
    NSError *error;
    NSString *appKey = TMLApplicationKey();
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
    
    __block NSMutableSet *resources = [NSMutableSet setWithArray:@[@"application.json", @"snapshot.json"]];
    if (locales.count > 0) {
        for (NSString *locale in locales) {
            [resources addObject:[locale stringByAppendingPathComponent:TMLBundleLanguageFilename]];
            [resources addObject:[locale stringByAppendingPathComponent:TMLBundleTranslationsFilename]];
        }
    }
    
    NSString *bundleDestinationPath = [NSString stringWithFormat:@"%@/%@", [self downloadDirectory], version];
    [self fetchPublishedResource:TMLBundleSourcesFilename
                   bundleVersion:version
                   baseDirectory:bundleDestinationPath
                 completionBlock:^(NSString *path, NSError *error) {
                     if (path != nil && locales.count > 0) {
                         NSArray *sources = [[NSData dataWithContentsOfFile:path] tmlJSONObject];
                         for (NSString *source in sources) {
                             for (NSString *locale in locales) {
                                 [resources addObject:[NSString stringWithFormat:@"%@/%@/%@.json", locale, TMLBundleSourcesRelativePath, source]];
                             }
                         }
                     }
                     [self fetchPublishedResources:[resources copy]
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

- (void)uninstallBundle:(TMLBundle *)bundle {
    NSString *bundlePath = bundle.path;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (bundlePath == nil || [fileManager fileExistsAtPath:bundlePath] == NO) {
        TMLWarn(@"Could not uninstall bundle as its backing path cannot be found: %@", bundlePath);
        return;
    }
    NSError *error;
    if ([fileManager removeItemAtPath:bundlePath error:&error] == NO) {
        TMLError(@"Error uninstalling bundle: %@", error);
    }
}

- (void)cleanup {
    NSUInteger keep = self.maximumBundlesToKeep;
    if (keep <= 1) {
        return;
    }
    
    NSArray *installedBundles = [self installedBundles];
    TMLBundle *latestBundle = [self latestBundle];
    NSMutableArray *targetBundles = [installedBundles mutableCopy];
    [targetBundles removeObject:latestBundle];
    keep -= installedBundles.count - targetBundles.count;
    installedBundles = targetBundles;
    
    if (installedBundles.count <= keep) {
        return;
    }
    
    installedBundles = [installedBundles sortedArrayUsingComparator:^NSComparisonResult(TMLBundle *a, TMLBundle *b) {
        NSString *aVersion = a.version;
        NSString *bVersion = b.version;
        return [aVersion compareToTMLTranslationBundleVersion:bVersion];
    }];
    
    NSArray *toRemove = [installedBundles subarrayWithRange:NSMakeRange(0, installedBundles.count - keep)];
    for (TMLBundle *bundle in toRemove) {
        [self uninstallBundle:bundle];
    }
}

#pragma mark - Downloading

- (void)fetchURL:(NSURL *)url
 completionBlock:(void(^)(NSData *data,
                          NSURLResponse *response,
                          NSError *error))completionBlock
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:DEFAULT_URL_TASK_TIMEOUT];
    [self fetchRequest:request completionBlock:completionBlock];
}

- (void)fetchURL:(NSURL *)url
     cachePolicy:(NSURLRequestCachePolicy)cachePolicy
 completionBlock:(void(^)(NSData *data,
                          NSURLResponse *response,
                          NSError *error))completionBlock
{
    NSURL *newURL = url;
    if (cachePolicy == NSURLRequestReloadIgnoringLocalAndRemoteCacheData) {
        newURL = [url URLByAppendingQueryParameters:@{@"_": [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]}];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:newURL
                                             cachePolicy:cachePolicy
                                         timeoutInterval:DEFAULT_URL_TASK_TIMEOUT];
    [self fetchRequest:request completionBlock:completionBlock];
}

- (void)fetchRequest:(NSURLRequest *)urlRequest
        completionBlock:(void(^)(NSData *data,
                                 NSURLResponse *response,
                                 NSError *error))completionBlock
{
    NSURLSession *downloadSession = [self downloadSession];
    [[downloadSession dataTaskWithRequest:urlRequest
                        completionHandler:^(NSData *data,
                                            NSURLResponse *response,
                                            NSError *error) {
                            NSError *ourError = error;
                            NSInteger responseCode = 0;
                            if ([response isKindOfClass:[NSHTTPURLResponse class]] == YES) {
                                responseCode = [(NSHTTPURLResponse *)response statusCode];
                            }
                            if (responseCode != 200 && ourError == nil) {
                                data = nil;
                                TMLError(@"Error fetching resource '%@'. HTTP: %i", urlRequest.URL, responseCode);
                                ourError = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                                               code:TMLBundleManagerHTTPError
                                                           userInfo:@{
                                                                      TMLBundleManagerErrorCodeKey: @(responseCode),
                                                                      TMLBundleManagerURLKey: urlRequest.URL
                                                                      }];
                            }
                            if (completionBlock != nil) {
                                completionBlock(data, response, ourError);
                            }
                        }] resume];
}

- (void) fetchPublishedResources:(NSSet *)resourcePaths
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
                         if (count > resourcePaths.count) {
                             TMLError(@"Overflown handler for URL task");
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
    
    // Ensure destination directory exists
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
    
    // Fetch resource data
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@/%@",
                     [self archiveURL],
                     TMLApplicationKey(),
                     bundleVersion,
                     [resourcePath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
    NSURL *resourceURL = [NSURL URLWithString:urlString];
    
    [self fetchURL:resourceURL
   completionBlock:^(NSData *data, NSURLResponse *response, NSError *error) {
       NSError *ourError = error;
        if (ourError == nil && data != nil) {
            if ([data writeToFile:destination options:NSDataWritingAtomic error:&ourError] == NO) {
                TMLError(@"Error writing fetched bundle resource '%@': %@", resourcePath, ourError);
            }
        }
        if (completionBlock != nil) {
            NSString *effectiveDestination = (ourError == nil) ? destination : nil;
            completionBlock(effectiveDestination, ourError);
        }
    }];
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
    NSString *applicationKey = TMLApplicationKey();
    if (applicationKey == nil) {
        error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                    code:TMLBundleManagerInvalidApplicationKeyError
                                userInfo:nil];
        TMLError(@"Tried to fetch published bundle info w/o valid application key");
        if (completionBlock != nil) {
            completionBlock(nil, error);
        }
        return;
    }
    
    NSURL *publishedVersionURL = [self.archiveURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/version.json", applicationKey]];
    [self fetchURL:publishedVersionURL
       cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
   completionBlock:^(NSData *data, NSURLResponse *response, NSError *error) {
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
   }];
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
        if ([fileManager fileExistsAtPath:destinationPath] == YES) {
            if([fileManager removeItemAtPath:destinationPath error:&error] == NO) {
                TMLError(@"Error removing existing resource at path '%@': %@", error);
            }
        }
        if ([fileManager moveItemAtPath:resourcePath toPath:destinationPath error:&error] == NO) {
            TMLError(@"Error installing resource '%@' for bundle '%@': %@", relativeBundlePath, bundleVersion, error);
        }
    }
    if (completionBlock != nil) {
        completionBlock((error) ? nil : destinationPath, error);
    }
}

#pragma mark - Registration

- (void)registerBundle:(TMLBundle *)bundle {
    NSString *version = bundle.version;
    if (version == nil) {
        return;
    }
    if (_registry == nil) {
        _registry = [NSMutableDictionary dictionary];
    }
    _registry[version] = bundle;
}

- (TMLBundle *)registeredBundleWithVersion:(NSString *)version {
    return _registry[version];
}

#pragma mark - Query

- (NSArray *) installedBundles {
    NSString *installPath = self.rootDirectory;
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
        NSString *extension = [[path lastPathComponent] pathExtension];
        if ([extension isEqualToString:@"bundle"] == NO) {
            continue;
        }
        TMLBundle *bundle = [[TMLBundle alloc] initWithContentsOfDirectory:[installPath stringByAppendingPathComponent:path]];
        if (bundle != nil) {
            [bundles addObject:bundle];
        }
    }
    return bundles;
}

- (TMLBundle *)installedBundleWithVersion:(NSString *)version {
    NSString *installPath = [self installPathForBundleVersion:version];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:installPath] == NO) {
        return nil;
    }
    TMLBundle *bundle = [[TMLBundle alloc] initWithContentsOfDirectory:installPath];
    return bundle;
}

- (BOOL)isVersionInstalled:(NSString *)version {
    NSString *installPath = [self installPathForBundleVersion:version];
    return ([[NSFileManager defaultManager] fileExistsAtPath:installPath] == YES);
}

#pragma mark - Latest Bundle

- (void)setLatestBundle:(TMLBundle *)bundle {
    if (_latestBundle == bundle) {
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *link = [NSString stringWithFormat:@"%@/%@", self.rootDirectory, TMLBundleManagerLatestBundleLinkName];
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
    _latestBundle = bundle;
}

- (TMLBundle *)latestBundle {
    if (_latestBundle == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *activeBundlePath = [NSString stringWithFormat:@"%@/%@", self.rootDirectory, TMLBundleManagerLatestBundleLinkName];
        if ([fileManager fileExistsAtPath:activeBundlePath] == YES) {
            NSString *version = [[activeBundlePath lastPathComponent] stringByDeletingPathExtension];
            _latestBundle = (version != nil) ? [self registeredBundleWithVersion:version] : nil;
            if (_latestBundle == nil) {
                _latestBundle = [[TMLBundle alloc] initWithContentsOfDirectory:activeBundlePath];
            }
        }
        else {
            NSArray *bundles = [self installedBundles];
            if (bundles.count > 0) {
                bundles = [bundles sortedArrayUsingComparator:^NSComparisonResult(TMLBundle *a, TMLBundle *b) {
                    NSString *aVersion = a.version;
                    NSString *bVersion = b.version;
                    return [aVersion compareToTMLTranslationBundleVersion:bVersion];
                }];
            }
            _latestBundle = [bundles lastObject];
        }
    }
    return _latestBundle;
}

#pragma mark - API Bundle

- (TMLBundle *)apiBundle {
    if (_apiBundle == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *apiBundleDir = [self.rootDirectory stringByAppendingPathComponent:TMLBundleManagerAPIBundleDirectoryName];
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

#pragma mark - Removing

- (void)removeAllBundles {
    NSMutableArray *allBundles = [[self installedBundles] mutableCopy];
    [allBundles addObject:[self apiBundle]];
    if (allBundles.count == 0) {
        return;
    }
    TMLInfo(@"Removing %i local translation bundles.", allBundles.count);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    for (TMLBundle *bundle in allBundles) {
        NSString *bundlePath = bundle.path;
        if (bundlePath == nil) {
            continue;
        }
        if([fileManager removeItemAtPath:bundlePath error:&error] == NO) {
            TMLError(@"Error removing installed bundle: %@", error);
        }
    }
    
    NSString *link = [NSString stringWithFormat:@"%@/%@", self.rootDirectory, TMLBundleManagerLatestBundleLinkName];
    if ([fileManager removeItemAtPath:link error:&error] == NO) {
        TMLError(@"Error removing latest bundle symlink: %@", error);
    }
    self.latestBundle = nil;
}

#pragma mark - Notifications

- (void) notifyBundleMutation:(NSString *)mutationType
                       bundle:(TMLBundle *)bundle
                       errors:(NSArray *)errors
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[TMLBundleChangeInfoBundleKey] = bundle;
    if (errors.count > 0) {
        info[TMLBundleChangeInfoErrorsKey] = errors;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:mutationType
                                                        object:nil
                                                      userInfo:info];
}

@end
