//
//  UIApplicationShortcutItem+TML.m
//  TMLKit
//
//  Created by Pasha on 12/15/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "UIApplicationShortcutItem+TML.h"
#import "NSObject+TML.h"

@implementation UIApplicationShortcutItem (TML)

- (NSSet *)tmlLocalizedKeyPaths {
    NSMutableArray *keys = [[super tmlLocalizedKeyPaths] mutableCopy];
    if (keys == nil) {
        keys = [NSMutableArray array];
    }
    [keys addObjectsFromArray:@[@"localizedTitle", @"localizedSubtitle"]];
    return [keys copy];
}

@end
