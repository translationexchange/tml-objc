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

- (void)restoreTMLLocalizations {
    [super restoreTMLLocalizations];
    for (UIView *subview in self.subviews) {
        [subview restoreTMLLocalizations];
    }
    [self setNeedsLayout];
}

#pragma mark - Supporting Methods
- (id)tmlFindFirstResponder {
    if ([self isFirstResponder] == YES) {
        return self;
    }
    for (UIView *subview in self.subviews) {
        id responder = [subview tmlFindFirstResponder];
        if (responder != nil) {
            return responder;
        }
    }
    return nil;
}

- (void)tmlIterateSubviewsWithBlock:(void (^)(UIView *view, BOOL *skip, BOOL *stop))block {
    __block BOOL shouldStop = NO;
    __block BOOL shouldSkip = NO;
    for (UIView *subview in self.subviews) {
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
