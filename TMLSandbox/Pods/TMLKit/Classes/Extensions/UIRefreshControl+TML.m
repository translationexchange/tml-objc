//
//  UIRefreshControl+TML.m
//  TMLKit
//
//  Created by Pasha on 12/14/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "NSObject+TML.h"
#import "TML.h"
#import "UIRefreshControl+TML.h"

@implementation UIRefreshControl (TML)

- (NSSet *)tmlLocalizableKeyPaths {
    NSMutableSet *paths = [[super tmlLocalizableKeyPaths] mutableCopy];
    if (paths == nil) {
        paths = [NSMutableSet set];
    }
    [paths addObject:@"attributedTitle"];
    return [paths copy];
}

@end
