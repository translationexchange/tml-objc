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

- (NSSet *)tmlLocalizableKeyPaths {
    NSMutableSet *paths = [[super tmlLocalizableKeyPaths] mutableCopy];
    if (paths == nil) {
        paths = [NSMutableSet set];
    }
    [paths addObjectsFromArray:@[@"alertBody", @"alertAction", @"alertTitle"]];
    return [paths copy];
}

@end
