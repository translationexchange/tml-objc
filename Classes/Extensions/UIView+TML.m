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

- (void)restoreTMLLocalizations {
    [super restoreTMLLocalizations];
    for (UIView *subview in self.subviews) {
        [subview restoreTMLLocalizations];
    }
}

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

@end
