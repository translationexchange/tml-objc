//
//  TMLAPIBundle.h
//  Demo
//
//  Created by Pasha on 11/20/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TMLBundle.h"
#import "TMLTranslationKey.h"

@interface TMLAPIBundle : TMLBundle

- (void) addTranslationKey:(TMLTranslationKey *)translationKey
                 forSource:(NSString *)sourceKey;

@property(nonatomic, assign) BOOL syncEnabled;
- (BOOL)isSyncing;
- (void)setNeedsSync;
- (void)sync;
- (void)cancelSync;

@end
