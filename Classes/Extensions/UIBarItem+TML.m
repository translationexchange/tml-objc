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

- (void)localizeWithTML {
    [super localizeWithTML];
    NSString *title = self.title;
    if (title != nil) {
        self.title = TMLLocalizedString(title, @"title");
    }
}

@end
