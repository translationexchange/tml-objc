//
//  NSString+TML.h
//  Demo
//
//  Created by Pasha on 10/29/15.
//  Copyright © 2015 TMLHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TML)

- (NSString *)tmlTranslationBundleVersionFromPath;
- (NSComparisonResult)compareToTMLTranslationBundleVersion:(NSString *)version;
- (NSString *)tmlCamelCaseString;
- (NSString *)tmlSnakeCaseString;
- (BOOL)tmlContainsDataTokens;
- (BOOL)tmlContainsDecoratedTokens;
- (NSString *) tmlMD5;

@end
