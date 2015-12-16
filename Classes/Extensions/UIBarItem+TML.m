//
//  UIBarItem+TML.m
//  TMLKit
//
//  Created by Pasha on 12/9/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "NSObject+TML.h"
#import "TML.h"
#import "UIBarItem+TML.h"

@implementation UIBarItem (TML)

- (NSSet *)tmlLocalizedKeyPaths {
    NSMutableArray *paths = [[super tmlLocalizedKeyPaths] mutableCopy];
    if (paths == nil) {
        paths = [NSMutableArray array];
    }
    [paths addObject:@"title"];
    return [paths copy];
}

@end
