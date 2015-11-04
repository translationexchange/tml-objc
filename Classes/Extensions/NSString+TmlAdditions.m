//
//  NSString+TMLAdditions.m
//  Demo
//
//  Created by Pasha on 10/29/15.
//  Copyright © 2015 TMLHub Inc. All rights reserved.
//

#import "NSString+TMLAdditions.h"
#import "TML.h"

@implementation NSString (TMLAdditions)

- (NSString *)tmlTranslationBundleVersionFromPath {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"tml_([0-9]+)\\.zip"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (error != nil) {
        TMLError(@"Error constructing regexp for determinging version of local localization bundles: %@", error);
        return nil;
    }
    
    NSString *lastComponent = [self lastPathComponent];
    NSString *version = [regex stringByReplacingMatchesInString:lastComponent
                                                        options:NSMatchingReportCompletion
                                                          range:NSMakeRange(0, lastComponent.length)
                                                   withTemplate:@"$1"];
    return version;
}

- (NSComparisonResult)compareToTMLTranslationBundleVersion:(NSString *)version {
    NSInteger ours = [self integerValue];
    NSInteger their = (version == nil) ? 0 : [version integerValue];
    if (ours < their) {
        return NSOrderedAscending;
    }
    else if (ours > their) {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

@end
