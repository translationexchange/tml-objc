//
//  UITableViewRowAction+TML.m
//  TMLKit
//
//  Created by Pasha on 12/15/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "UITableViewRowAction+TML.h"
#import "NSObject+TML.h"

@implementation UITableViewRowAction (TML)

- (NSSet *)tmlLocalizableKeyPaths {
    NSMutableSet *keys = [[super tmlLocalizableKeyPaths] mutableCopy];
    if (keys == nil) {
        keys = [NSMutableSet set];
    }
    [keys addObject:@"title"];
    return [keys copy];
}

@end
