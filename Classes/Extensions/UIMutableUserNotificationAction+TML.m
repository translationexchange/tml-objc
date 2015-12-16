//
//  UIMutableUserNotificationAction+TML.m
//  TMLKit
//
//  Created by Pasha on 12/15/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "UIMutableUserNotificationAction+TML.h"
#import "NSObject+TML.h"

@implementation UIMutableUserNotificationAction (TML)

- (NSSet *)tmlLocalizedKeyPaths {
    NSMutableSet *keys = [[super tmlLocalizedKeyPaths] mutableCopy];
    if (keys == nil) {
        keys = [NSMutableSet set];
    }
    [keys addObject:@"title"];
    return [keys copy];
}

@end
