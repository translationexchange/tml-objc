//
//  UIResponder+TML.h
//  TMLKit
//
//  Created by Pasha on 12/10/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (TML)

- (NSArray *)tmlLocalizedKeyPaths;
- (NSArray *)tmlTranslationKeys;

@end
