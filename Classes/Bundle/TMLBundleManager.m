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

NSString * const TMLBundleRegistryVersionsKey = @"versions";
NSString * const TMLBundleRegistryMainBundleKey = @"mainBundle";
NSString * const TMLBundleRegistryAPIBundleKey = @"apiBundle";


@interface TMLBundleManager() {
    NSURLSession *_downloadSession;
    NSMutableDictionary *_bundleRegistry;
}
@property(strong, nonatomic) NSString *rootDirectory;
@property(strong, nonatomic) NSString *downloadDirectory;
@end

@implementation TMLBundleManager

+ (NSMutableDictionary *)managerRegistry {
    static NSMutableDictionary *registry = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registry = [NSMutableDictionary dictionary];
    });
    return registry;
}

+ (instancetype)defaultManager {
    static TMLBundleManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TMLBundleManager alloc] init];
    });
    return manager;
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

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        self.maximumBundlesToKeep = 2;
        NSString *appSupportDir = [[self class] applicationSupportDirectory];
        self.rootDirectory = appSupportDir;
        self.downloadDirectory = [appSupportDir stringByAppendingPathComponent:@"Downloads"];
        [self resetBundleRegistry];
    }
    return self;
}

#pragma mark - Paths

- (NSString *)bundlePathForApplicationKey:(NSString *)applicationKey {
    return [self.rootDirectory stringByAppendingPathComponent:applicationKey];
}

- (NSString *)installPathForBundleVersion:(NSString *)version applicationKey:(NSString *)applicationKey {
    return [NSString stringWithFormat:@"%@/%@.bundle", [self bundlePathForApplicationKey:applicationKey], version];
}

- (NSArray *)rootContents {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *fileError = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.rootDirectory error:&fileError];
    if (fileError != nil) {
        TMLError(@"Error getting contents of bundle manager's root directory: %@", fileError);
    }
    return contents;
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
    NSRange extRange = [bundleName rangeOfString:@"."];
    if (isDirectory == NO && extRange.location != NSNotFound) {
        bundleName = [bundleName substringToIndex:extRange.location];
    }
    NSString *extension = (extRange.location == NSNotFound) ? nil : [[aPath lastPathComponent] substringFromIndex:(extRange.location + extRange.length)];
    
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
        
        if (application.key == nil) {
            installError = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                               code:TMLBundleManagerInvalidApplicationKeyError
                                           userInfo:nil];
            success = NO;
        }
        
        NSString *destinationPath;
        if (success == YES) {
            destinationPath = [self installPathForBundleVersion:bundleName applicationKey:application.key];
            
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
        
        TMLBundle *installedBundle = nil;
        if (success == YES) {
            installedBundle = [[TMLBundle alloc] initWithContentsOfDirectory:destinationPath];
            [self setMainBundle:installedBundle forApplicationKey:application.key];
        }
        [self cleanup];
        completionBlock(installedBundle, installError);
        if (installedBundle != nil) {
            [installedBundle notifyBundleMutation:TMLLocalizationUpdatesInstalledNotification
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
                  progressHandler:^(NSString *entry, unz_file_info zipInfo, long entryNumber, long total){}
                completionHandler:^(NSString *zipPath, BOOL succeeded, NSError *error) {
                    if (error != nil) {
                        TMLError(@"Error uncompressing local translation bundle: %@", error);
                    }
                    if (succeeded == YES) {
                        [self installBundleFromPath:zipPath completionBlock:^(TMLBundle *bundle, NSError *error) {
                            if (error != nil) {
                                NSFileManager *fileManager = [NSFileManager defaultManager];
                                NSError *fileManagerError;
                                if ([fileManager removeItemAtPath:zipPath error:&fileManagerError] == NO) {
                                    TMLWarn(@"Could not remove temporary zip extraction directory '%@'. Error: %@", zipPath, error);
                                }
                            }
                            if (completionBlock != nil) {
                                completionBlock(bundle, error);
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
    NSString *bundleName = [aPath lastPathComponent];
    NSRange extRange = [bundleName rangeOfString:@"."];
    if (extRange.location != NSNotFound) {
        bundleName = [bundleName substringToIndex:extRange.location];
    }
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

- (NSArray *)selectMatchingLocales:(NSArray *)locales fromPool:(NSArray *)pool {
    NSMutableArray *results = [NSMutableArray array];
    NSArray *ourPool = [pool valueForKeyPath:@"lowercaseString"];
    for (NSString *locale in locales) {
        NSArray *parts = [[locale lowercaseString] componentsSeparatedByString:@"-"];
        NSString *lang = parts[0];
        NSString *region = (parts.count > 1) ? parts[1] : nil;
        if (region == nil && [ourPool containsObject:lang]) {
            [results addObject:lang];
        }
        else if (region != nil) {
            if ([ourPool containsObject:locale]) {
                [results addObject:locale];
            }
            else if ([ourPool containsObject:lang]) {
                [results addObject:lang];
            }
        }
    }
    return results;
}

- (void) installPublishedBundleWithVersion:(NSString *)version
                                   baseURL:(NSURL *)baseURL
                                   locales:(NSArray *)locales
                           completionBlock:(TMLBundleInstallBlock)completionBlock
{
    // Sanity checks
    NSError *error;
    if (version == nil) {
        TMLError(@"Tried to install published bundle w/o a version string");
        error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                    code:TMLBundleManagerInvalidVersionError
                                userInfo:nil];
    }
    if (error != nil) {
        if (completionBlock != nil) {
            completionBlock(nil, error);
        }
        return;
    }
    
    NSMutableSet *resources = [NSMutableSet setWithArray:@[TMLBundleApplicationFilename, TMLBundleVersionFilename, TMLBundleSourcesFilename]];
    
    NSString *bundleDestinationPath = [NSString stringWithFormat:@"%@/%@", [self downloadDirectory], version];
    
    void (^finalize)(BOOL) = ^void(BOOL success){
        if (success == YES) {
            [self installBundleFromPath:bundleDestinationPath
                        completionBlock:completionBlock];
        }
        else if (completionBlock != nil) {
            NSError *error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                                 code:TMLBundleManagerIncompleteData
                                             userInfo:nil];
            completionBlock(nil, error);
        }
    };
    
    NSURL *url = [baseURL URLByAppendingPathComponent:version];
    
    [self fetchPublishedResources:[resources allObjects]
                          baseURL:url
                  destinationPath:bundleDestinationPath
                  completionBlock:^(BOOL success, NSArray *paths, NSArray *errors) {
                      if (success == NO || locales.count == 0) {
                          finalize(success);
                          return;
                      }
                      
                      NSArray *sources = nil;
                      NSDictionary *application = nil;
                      for (NSString *path in paths) {
                          NSString *filename = [path lastPathComponent];
                          if ([TMLBundleSourcesFilename isEqualToString:filename] == YES) {
                              sources = [[NSData dataWithContentsOfFile:path] tmlJSONObject];
                          }
                          else if ([TMLBundleApplicationFilename isEqualToString:filename] == YES) {
                              application = [[NSData dataWithContentsOfFile:path] tmlJSONObject];
                          }
                      }
                      
                      NSArray *availableLocales = [application valueForKeyPath:@"languages.locale"];
                      NSArray *effectiveLocales = [self selectMatchingLocales:locales fromPool:availableLocales];
                      NSMutableArray *additionalResources = [NSMutableArray array];
                      for (NSString *locale in effectiveLocales) {
                          [additionalResources addObject:[locale stringByAppendingPathComponent:TMLBundleLanguageFilename]];
                          [additionalResources addObject:[locale stringByAppendingPathComponent:TMLBundleTranslationsFilename]];
                          if (sources != nil) {
                              for (NSString *source in sources) {
                                  [additionalResources addObject:[NSString stringWithFormat:@"%@/%@/%@.json", locale, TMLBundleSourcesRelativePath, source]];
                              }
                          }
                      }
                      
                      [self fetchPublishedResources:[additionalResources copy]
                                     baseURL:url
                                      destinationPath:bundleDestinationPath
                                    completionBlock:^(BOOL success, NSArray *paths, NSArray *errors) {
                                        finalize(success);
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
    NSArray *contents = [self rootContents];
    NSString *downloadsPath = [self.downloadDirectory lastPathComponent];
    for (NSString *path in contents) {
        if ([path isEqualToString:downloadsPath] == YES) {
            continue;
        }
        [self cleanupUsingApplicationKey:path];
    }
}

- (void)cleanupUsingApplicationKey:(NSString *)applicationKey {
    NSUInteger keep = self.maximumBundlesToKeep;
    if (keep <= 1) {
        return;
    }
    
    NSArray *installedBundles = [self installedBundlesForApplicationKey:applicationKey];
    NSMutableArray *targetBundles = (installedBundles.count > 0) ?  [installedBundles mutableCopy] : [NSMutableArray array];
    TMLBundle *mainBundle = [self mainBundleForApplicationKey:applicationKey];
    [targetBundles removeObject:mainBundle];
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
                                         timeoutInterval:TMLSharedConfiguration().timeoutIntervalForRequest];
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
                                         timeoutInterval:TMLSharedConfiguration().timeoutIntervalForRequest];
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

- (void) fetchPublishedResources:(NSArray *)resourcePaths
                       forBundle:(TMLBundle *)bundle
                 completionBlock:(void(^)(BOOL success, NSArray *paths, NSArray *errors))completionBlock {
    NSURL *baseURL = bundle.baseURL;
    NSString *version = bundle.version;
    NSString *destinationPath = [[self downloadDirectory] stringByAppendingPathComponent:version];
    [self fetchPublishedResources:resourcePaths 
                          baseURL:baseURL
                  destinationPath:destinationPath
                  completionBlock:completionBlock];
}

- (void) fetchPublishedResources:(NSSet *)resourcePaths
                         baseURL:(NSURL *)baseURL
                 destinationPath:(NSString *)destinationPath
                 completionBlock:(void(^)(BOOL success, NSArray *paths, NSArray *errors))completionBlock
{
    __block NSInteger count = 0;
    __block BOOL success = YES;
    __block NSMutableArray *paths = [NSMutableArray array];
    __block NSMutableArray *errors = [NSMutableArray array];
    for (NSString *resourcePath in resourcePaths) {
        [self fetchPublishedResource:resourcePath
                             baseURL:baseURL
                     destinationPath:destinationPath
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
                        baseURL:(NSURL *)baseURL
                destinationPath:(NSString *)destinationPath
                completionBlock:(void(^)(NSString *path, NSError *error))completionBlock
{
    NSString *destination = [destinationPath stringByAppendingPathComponent:resourcePath];
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
    NSString *urlString = [NSString stringWithFormat:@"%@/%@",
                     baseURL,
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

- (void) fetchPublishedBundleInfo:(NSURL *)baseURL
                       completion:(void(^)(NSDictionary *info, NSError *error))completionBlock {
    NSURL *publishedVersionURL = [baseURL URLByAppendingPathComponent:@"version.json"];
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

#pragma mark - Registration

- (void)resetBundleRegistry {
    _bundleRegistry = [NSMutableDictionary dictionary];
}

- (NSMutableDictionary *)newRegistryInfo {
    return [NSMutableDictionary dictionaryWithObject:[NSMutableDictionary dictionary]
                                              forKey:TMLBundleRegistryVersionsKey];
}

- (void)registerBundle:(TMLBundle *)bundle applicationKey:(NSString *)applicationKey {
    NSString *version = bundle.version;
    if (version == nil) {
        return;
    }
    NSMutableDictionary *info = _bundleRegistry[applicationKey];
    if (info == nil) {
        info = [self newRegistryInfo];
        _bundleRegistry[applicationKey] = info;
    }
    
    NSMutableDictionary *versions = info[TMLBundleRegistryVersionsKey];
    versions[version] = bundle;
}

- (TMLBundle *)registeredBundleWithVersion:(NSString *)version applicationKey:(NSString *)applicationKey {
    return _bundleRegistry[applicationKey][TMLBundleRegistryVersionsKey][version];
}

#pragma mark - Query
- (NSArray *) installedBundles {
    NSArray *contents = [self rootContents];
    NSMutableArray *allBundles = [NSMutableArray array];
    for (NSString *path in contents) {
        if ([path isEqualToString:self.downloadDirectory] == YES) {
            continue;
        }
        NSArray *bundles = [self installedBundlesAtPath:path];
        if (bundles.count > 0) {
            [allBundles addObjectsFromArray:bundles];
        }
    }
    return allBundles;
}

- (NSArray *) installedBundlesForApplicationKey:(NSString *)applicationKey {
    NSString *path = [self.rootDirectory stringByAppendingPathComponent:applicationKey];
    return [self installedBundlesAtPath:path];
}

- (NSArray *) installedBundlesAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDir] == NO || isDir == NO) {
        return nil;
    }
    
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:&error];
    if (contents == nil) {
        if (error != nil) {
            TMLError(@"Error getting contents of bundle installation directory: %@", error);
        }
        return nil;
    }
    
    NSMutableArray *bundles = [NSMutableArray array];
    for (NSString *bundlePath in contents) {
        NSString *extension = [[bundlePath lastPathComponent] pathExtension];
        if ([extension isEqualToString:@"bundle"] == NO) {
            continue;
        }
        TMLBundle *bundle = [[TMLBundle alloc] initWithContentsOfDirectory:[path stringByAppendingPathComponent:bundlePath]];
        if (bundle != nil) {
            [bundles addObject:bundle];
        }
    }
    return bundles;
}

- (TMLBundle *)installedBundleWithVersion:(NSString *)version applicationKey:(NSString *)applicationKey {
    NSString *installPath = [self installPathForBundleVersion:version applicationKey:applicationKey];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:installPath] == NO) {
        return nil;
    }
    TMLBundle *bundle = [[TMLBundle alloc] initWithContentsOfDirectory:installPath];
    return bundle;
}

- (BOOL)isBundleInstalledWithVersion:(NSString *)version applicationKey:(NSString *)applicationKey {
    NSString *installPath = [self installPathForBundleVersion:version applicationKey:applicationKey];
    return ([[NSFileManager defaultManager] fileExistsAtPath:installPath] == YES);
}

- (TMLBundle *)bundleWithVersion:(NSString *)version applicationKey:(NSString *)applicationKey {
    TMLBundle *bundle = [self registeredBundleWithVersion:version applicationKey:applicationKey];
    if (bundle != nil) {
        return bundle;
    }
    return [self installedBundleWithVersion:version applicationKey:applicationKey];
}

#pragma mark - Main Bundle

- (void)setMainBundle:(TMLBundle *)bundle forApplicationKey:(NSString *)applicationKey {
    if (applicationKey == nil) {
        return;
    }
    [self registerBundle:bundle applicationKey:applicationKey];
    _bundleRegistry[applicationKey][TMLBundleRegistryMainBundleKey] = bundle;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *bundleContainer = [self bundlePathForApplicationKey:applicationKey];
    NSString *link = [NSString stringWithFormat:@"%@/%@", bundleContainer, TMLBundleManagerLatestBundleLinkName];
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
}

- (TMLBundle *)mainBundleForApplicationKey:(NSString *)applicationKey {
    if (applicationKey == nil) {
        return nil;
    }
    TMLBundle *mainBundle = _bundleRegistry[applicationKey][TMLBundleRegistryMainBundleKey];
    
    if (mainBundle == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *bundleContainer = [self bundlePathForApplicationKey:applicationKey];
        NSString *bundlePath = [NSString stringWithFormat:@"%@/%@", bundleContainer, TMLBundleManagerLatestBundleLinkName];
        if ([fileManager fileExistsAtPath:bundlePath] == YES) {
            mainBundle = [[TMLBundle alloc] initWithContentsOfDirectory:bundlePath];
        }
        else {
            NSArray *bundles = [self installedBundlesForApplicationKey:applicationKey];
            if (bundles.count > 0) {
                bundles = [bundles sortedArrayUsingComparator:^NSComparisonResult(TMLBundle *a, TMLBundle *b) {
                    NSString *aVersion = a.version;
                    NSString *bVersion = b.version;
                    return [aVersion compareToTMLTranslationBundleVersion:bVersion];
                }];
            }
            mainBundle = [bundles lastObject];
        }
        
        if (mainBundle != nil && mainBundle.version != nil) {
            _bundleRegistry[applicationKey][TMLBundleRegistryMainBundleKey] = mainBundle;
        }
        else {
            mainBundle = nil;
        }
    }
    return mainBundle;
}

#pragma mark - API Bundle

- (TMLAPIBundle *)apiBundleForApplicationKey:(NSString *)applicationKey {
    if (applicationKey == nil) {
        return nil;
    }
    TMLAPIBundle *apiBundle = _bundleRegistry[applicationKey][TMLBundleRegistryAPIBundleKey];
    
    if (apiBundle == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *apiBundleDir = [[self bundlePathForApplicationKey:applicationKey] stringByAppendingPathComponent:TMLBundleManagerAPIBundleDirectoryName];
        NSError *error;
        if ([fileManager fileExistsAtPath:apiBundleDir] == NO) {
            if ([fileManager createDirectoryAtPath:apiBundleDir
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:&error] == NO) {
                TMLError(@"Error creating directory structure for API bundle: %@", error);
                return apiBundle;
            }
        }
        apiBundle = [[TMLAPIBundle alloc] initWithContentsOfDirectory:apiBundleDir];
        if (apiBundle != nil) {
            NSMutableDictionary *info = _bundleRegistry[applicationKey];
            if (info == nil) {
                info = [self newRegistryInfo];
                _bundleRegistry[applicationKey] = info;
            }
            info[TMLBundleRegistryAPIBundleKey] = apiBundle;
        }
    }
    return apiBundle;
}

#pragma mark - Removing

- (void)removeAllBundles {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [self rootContents];
    NSString *root = self.rootDirectory;
    NSString *downloads = self.downloadDirectory;
    for (NSString *path in contents) {
        NSString *fullPath = [root stringByAppendingPathComponent:path];
        if ([fullPath isEqualToString:downloads] == YES) {
            continue;
        }
        NSError *fileError = nil;
        if([fileManager removeItemAtPath:fullPath error:&fileError] == NO) {
            TMLError(@"Error removing '%@': %@", fullPath, fileError);
        }
    }
    [self resetBundleRegistry];
}

@end
