//
//  TMLAnalytics.m
//  TMLKit
//
//  Created by Pasha on 1/25/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLAnalytics.h"
#import "TMLConfiguration.h"

#define ANALYTICS_TIMER_INTERVAL 60

NSString * const TMLAnalyticsEventApplicationKeyKey = @"application_key";
NSString * const TMLAnalyticsEventLocaleKey = @"locale";
NSString * const TMLAnalyticsEventSDKKey = @"sdk";
NSString * const TMLAnalyticsEventTypeKey = @"event_type";
NSString * const TMLAnalyticsEventDataKey = @"event_data";
NSString * const TMLAnalyticsPageViewEventName = @"page_view";

NSString * const TMLAnalyticsBackingFileName = @"TMLAnalytics.json";

@interface TMLAnalytics(){
    NSMutableArray *_analyticsEvents;
    NSTimer *_analyticsTimer;
    NSFileHandle *_backingFileHandle;
    NSURLSessionDataTask *_postTask;
    BOOL _backingFileInvalid;
}
@end

@implementation TMLAnalytics

+ (instancetype)sharedInstance {
    static TMLAnalytics *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TMLAnalytics alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _analyticsEvents = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    [self stopAnalyticsTimerIfNecessary];
}

#pragma mark - 

- (void)setEnabled:(BOOL)enabled {
    if (_enabled == enabled) {
        return;
    }
    _enabled = enabled;
    if (enabled == NO) {
        [self stopAnalyticsTimerIfNecessary];
    }
}

#pragma mark - Backing file

- (NSString *)backingFilePath {
    static NSString *backingFilePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        backingFilePath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:TMLAnalyticsBackingFileName];
    });
    return backingFilePath;
}

- (void)truncateBackingFile {
    NSString *filePath = [self backingFilePath];
    NSError *error = nil;
    BOOL success = YES;
    if ([@"" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error] == NO) {
        TMLDebug(@"Error truncating backing file: %@", error);
        success = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath] == YES) {
            if([fileManager removeItemAtPath:filePath error:&error] == NO) {
                TMLDebug(@"Error removing backing file after failed attempt at truncating it");
                success = NO;
            }
            else {
                success = YES;
            }
        }
    }
    if (success == NO) {
        [self invalidateBackingFile];
        [self stopAnalyticsTimerIfNecessary];
    }
}

- (void)invalidateBackingFile {
    _backingFileInvalid = YES;
}

#pragma mark -

// {key: APP_KEY, locale: CURRENT_LOCALE, sdk: SDK_VERSION}
- (NSMutableDictionary *)baseAnalyticInfo {
    NSBundle *tmlBundle = [NSBundle bundleWithIdentifier:TMLBundleIdentifier];
    NSDictionary *tmlBundleInfo = [tmlBundle infoDictionary];
    NSString *version = [tmlBundleInfo objectForKey:@"CFBundleShortVersionString"];
    if (version == nil) {
        version = @"Unknown";
    }
    NSString *sdkDescription = [tmlBundleInfo objectForKey:@"CFBundleName"];
    sdkDescription = [NSString stringWithFormat:@"%@-iOS v.%@", sdkDescription, version];
    TMLConfiguration *config = [[TML sharedInstance] configuration];
    NSString *appKey = config.applicationKey;
    if (appKey == nil) {
        appKey = @"Unknown";
    }
    NSString *currentLocale = TMLCurrentLocale();
    if (currentLocale == nil) {
        currentLocale = [config deviceLocale];
    }
    if (currentLocale == nil) {
        currentLocale = @"Unknown";
    }
    NSDictionary *info = @{
                           @"key": appKey,
                           @"locale": currentLocale,
                           @"sdk": sdkDescription
                           };
    return [info mutableCopy];
}

#pragma mark - Reporting

- (void)reportEvent:(NSDictionary *)eventInfo {
    if (eventInfo == nil) {
        return;
    }
    
    if (_backingFileInvalid == YES) {
        return;
    }
    
    if (_enabled == NO) {
        return;
    }
    
    if ([[[TML sharedInstance] configuration] isValidConfiguration] == NO) {
        return;
    }
    
    NSMutableDictionary *event = [self baseAnalyticInfo];
    [event addEntriesFromDictionary:eventInfo];
    
    [_analyticsEvents addObject:event];
    
    [self startAnalyticsTimerIfNecessary];
}

- (void)submitQueuedEvents {
    if ([NSThread isMainThread] == NO) {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (_analyticsEvents.count == 0) {
        return;
    }
    
    if (_backingFileHandle != nil) {
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *backingFilePath = [self backingFilePath];
    if ([fileManager fileExistsAtPath:backingFilePath] == NO) {
        [fileManager createFileAtPath:backingFilePath contents:nil attributes:nil];
    }
    
    _backingFileHandle = [NSFileHandle fileHandleForWritingAtPath:backingFilePath];
    [_backingFileHandle seekToEndOfFile];
    unsigned long long offset = [_backingFileHandle offsetInFile];
    NSString *suffix = @"]";
    NSData *suffixData = [suffix dataUsingEncoding:NSUTF8StringEncoding];
    if (offset == 0) {
        NSString *prefix = @"[";
        [_backingFileHandle writeData:[prefix dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else {
        [_backingFileHandle seekToFileOffset:(offset - suffixData.length)];
    }
    @synchronized(_analyticsEvents) {
        for (NSDictionary *event in _analyticsEvents) {
            NSString *json = [[event tmlJSONString] stringByAppendingString:@","];
            [_backingFileHandle writeData:[json dataUsingEncoding:NSUTF8StringEncoding]];
        }
        _analyticsEvents = [NSMutableArray array];
    }
    [_backingFileHandle writeData:suffixData];
    [_backingFileHandle closeFile];
    
    [self postAnalyticsDataFromFile:backingFilePath completion:^(BOOL success) {
        _backingFileHandle = nil;
    }];
}

#pragma mark - Posting
- (void)postAnalyticsDataFromFile:(NSString *)filePath
                       completion:(void(^)(BOOL success))completion
{
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data == nil) {
        return;
    }
    if (_postTask != nil) {
        TMLDebug(@"POST of analytic data is already in progress");
        return;
    }
    
    // wrap data into post param in the format of "data=base64(<data>)"
    data = [[NSString stringWithFormat:@"data=%@", [[NSString alloc] initWithData:[data base64EncodedDataWithOptions:0] encoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:@"https://analyst.translationexchange.com"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    _postTask = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        BOOL success = (statusCode == 200) ? YES : NO;
        if (success == NO) {
            if (error != nil) {
                TMLDebug(@"Error posting analytics data: %@", error);
            }
            else {
                TMLDebug(@"Error posting analytics data: HTTP %i", statusCode);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                _postTask = nil;
                if (completion != nil) {
                    completion(success);
                }
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion != nil) {
                    completion(success);
                }
                _postTask = nil;
                [self truncateBackingFile];
            });
        }
    }];
    [_postTask resume];
}

#pragma mark - Timer

- (void)startAnalyticsTimerIfNecessary {
    if (_analyticsTimer != nil
        && [_analyticsTimer isValid] == YES) {
        return;
    }
    if (_analyticsEvents.count == 0) {
        return;
    }
    _analyticsTimer = [NSTimer timerWithTimeInterval:ANALYTICS_TIMER_INTERVAL
                                              target:self
                                            selector:@selector(analyticsTimerFired:)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_analyticsTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopAnalyticsTimerIfNecessary {
    if (_analyticsTimer != nil) {
        [_analyticsTimer invalidate];
        _analyticsTimer = nil;
    }
}

- (void)analyticsTimerFired:(NSTimer *)timer {
    [self submitQueuedEvents];
}

@end
