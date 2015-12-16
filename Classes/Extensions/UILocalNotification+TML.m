//
//  UILocalNotification+TML.m
//  TMLKit
//
//  Created by Pasha on 12/15/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "UILocalNotification+TML.h"
#import "NSObject+TML.h"

@implementation UILocalNotification (TML)

- (NSSet *)tmlLocalizedKeyPaths {
    NSMutableArray *paths = [[super tmlLocalizedKeyPaths] mutableCopy];
    if (paths == nil) {
        paths = [NSMutableArray array];
    }
    [paths addObjectsFromArray:@[@"alertBody", @"alertAction", @"alertTitle"]];
    return [paths copy];
}

@end
