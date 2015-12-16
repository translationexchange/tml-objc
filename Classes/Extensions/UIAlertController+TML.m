//
//  UIAlertController+TML.m
//  TMLKit
//
//  Created by Pasha on 12/15/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "UIAlertController+TML.h"
#import "NSObject+TML.h"

@implementation UIAlertController (TML)

- (NSSet *)tmlLocalizedKeyPaths {
    NSMutableSet *paths = [[super tmlLocalizedKeyPaths] mutableCopy];
    if (paths == nil) {
        paths = [NSMutableSet set];
    }
    [paths addObjectsFromArray:@[@"title", @"message"]];
    return [paths copy];
}

@end
