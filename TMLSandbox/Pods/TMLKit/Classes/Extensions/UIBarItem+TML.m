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

- (NSSet *)tmlLocalizableKeyPaths {
    NSMutableSet *paths = [[super tmlLocalizableKeyPaths] mutableCopy];
    if (paths == nil) {
        paths = [NSMutableSet set];
    }
    [paths addObject:@"title"];
    return [paths copy];
}

@end
