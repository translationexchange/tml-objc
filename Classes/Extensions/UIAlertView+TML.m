//
//  UIAlertView+TML.m
//  TMLKit
//
//  Created by Pasha on 12/14/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "NSObject+TML.h"
#import "TML.h"
#import "UIAlertView+TML.h"

@implementation UIAlertView (TML)

- (NSSet *)tmlLocalizedKeyPaths {
    NSMutableArray *paths = [[super tmlLocalizedKeyPaths] mutableCopy];
    if (paths == nil) {
        paths = [NSMutableArray array];
    }
    [paths addObjectsFromArray:@[@"title", @"message"]];
    return [paths copy];
}

@end
