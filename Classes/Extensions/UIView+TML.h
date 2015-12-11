//
//  UIView+TML.h
//  TMLKit
//
//  Created by Pasha on 12/7/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (TML)

- (id)tmlFindFirstResponder;

- (void)tmlIterateSubviewsWithBlock:(void(^)(UIView *view, BOOL *skip, BOOL *stop))block;

@end
