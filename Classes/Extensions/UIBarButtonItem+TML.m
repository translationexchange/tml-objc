//
//  UIBarButtonItem+TML.m
//  TMLKit
//
//  Created by Pasha on 12/15/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "UIBarButtonItem+TML.h"
#import "NSObject+TML.h"

@implementation UIBarButtonItem (TML)

- (NSArray *)tmlLocalizedKeyPaths {
    NSMutableArray *keys = [[super tmlLocalizedKeyPaths] mutableCopy];
    if (keys == nil) {
        keys = [NSMutableArray array];
    }
    [keys addObjectsFromArray:@[@"possibleTitles"]];
    return [keys copy];
}

@end
