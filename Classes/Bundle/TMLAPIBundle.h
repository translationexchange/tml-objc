//
//  TMLAPIBundle.h
//  Demo
//
//  Created by Pasha on 11/20/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TMLBundle.h"

@interface TMLAPIBundle : TMLBundle

- (void) addTranslationKey:(TMLTranslationKey *)translationKey
                 forSource:(NSString *)sourceKey;

@property(nonatomic, assign) BOOL syncEnabled;
- (void)setNeedsSync;
- (void)sync;

@end
