//
//  UIView+TML.m
//  TMLKit
//
//  Created by Pasha on 12/7/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "UIView+TML.h"
#import "NSObject+TML.h"

@implementation UIView (TML)

#pragma mark - Localization

- (void)updateReusableTMLStrings {
    [super updateReusableTMLStrings];
    [self setNeedsLayout];
}

#pragma mark - Supporting Methods

- (void)tmlIterateSubviewsWithBlock:(void (^)(UIView *view, BOOL *skip, BOOL *stop))block {
    __block BOOL shouldStop = NO;
    for (UIView *subview in self.subviews) {
        __block BOOL shouldSkip = NO;
        block(subview, &shouldSkip, &shouldStop);
        if (shouldStop == YES) {
            break;
        }
        if (shouldSkip == YES) {
            continue;
        }
        [subview tmlIterateSubviewsWithBlock:^(UIView *view, BOOL *skip, BOOL *stop) {
            block(view, &shouldSkip, &shouldStop);
        }];
        if (shouldStop == YES) {
            break;
        }
    }
}

@end
