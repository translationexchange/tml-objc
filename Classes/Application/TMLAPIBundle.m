//
//  TMLAPIBundle.m
//  Demo
//
//  Created by Pasha on 11/20/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TML.h"
#import "TMLAPIBundle.h"
#import "TMLAPIClient.h"
#import "TMLConfiguration.h"

@interface TMLAPIBundle()
@property(strong, nonatomic) NSOperationQueue *syncQueue;
@property(strong, nonatomic) NSArray *sources;
@property (readwrite, nonatomic) NSArray *languages;
@property (readwrite, nonatomic) TMLApplication *application;
@end

@implementation TMLAPIBundle

@dynamic sources, languages, application;

- (NSURL *)sourceURL {
    return [[[TML sharedInstance] configuration] apiURL];
}

- (NSOperationQueue *)syncQueue {
    if (_syncQueue == nil) {
        _syncQueue = [[NSOperationQueue alloc] init];
    }
    return _syncQueue;
}

- (void)synchronize:(void (^)(BOOL))completion {
    [self synchronizeApplicationData:^(BOOL success) {
        NSArray *locales;
        if (success == YES) {
            locales = self.locales;
        }
        if (locales.count > 0) {
            [self synchronizeLocales:locales completion:completion];
        }
        else if (completion != nil) {
            completion(success);
        }
    }];
}

- (void)synchronizeApplicationData:(void (^)(BOOL))completion {
    NSOperationQueue *syncQueue = self.syncQueue;
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        TMLAPIClient *client = [[TML sharedInstance] apiClient];
        [client getCurrentApplicationWithOptions:@{TMLAPIOptionsIncludeDefinition: @YES}
                                 completionBlock:^(TMLApplication *application, NSError *error) {
                                     if (application != nil) {
                                         self.application = application;
                                     }
                                     if (syncQueue.operations == 0) {
                                         [syncQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                                             [client getSources:nil
                                                completionBlock:^(NSArray *sources, NSError *error) {
                                                    if (error != nil) {
                                                        self.sources = sources;
                                                    }
                                                }];
                                         }]];
                                     }
                                 }];
    }];
    [syncQueue addOperation:op];
}

- (void)synchronizeLocales:(NSArray *)locales completion:(void (^)(BOOL))completion {
    
}

@end
