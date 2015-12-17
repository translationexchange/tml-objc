//
//  UIResponder+TML.h
//  TMLKit
//
//  Created by Pasha on 12/10/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (TML)

- (NSDictionary *)tmlTranslationKeysAndPaths;
- (NSString *)tmlTranslationKeyForKeyPath:(NSString *)keyPath;

@end
