//
//  UIActionSheet+TML.m
//  TMLKit
//
//  Created by Pasha on 12/14/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "NSObject+TML.h"
#import "TML.h"
#import "UIActionSheet+TML.h"

@implementation UIActionSheet (TML)

- (NSArray *)tmlLocalizedKeyPaths {
    NSMutableArray *paths = [[super tmlLocalizedKeyPaths] mutableCopy];
    if (paths == nil) {
        paths = [NSMutableArray array];
    }
    [paths addObject:@"title"];
    return [paths copy];
}

@end
