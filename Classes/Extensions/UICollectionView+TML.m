//
//  UICollectionView+TML.m
//  TMLKit
//
//  Created by Pasha on 2/17/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "NSObject+TML.h"
#import "TML.h"
#import "TMLConfiguration.h"
#import "UICollectionView+TML.h"

@implementation UICollectionView (TML)

- (void)updateReusableTMLStrings {
    [super updateReusableTMLStrings];
    if ([[[TML sharedInstance] configuration] automaticallyReloadDataBackedViews] == YES) {
        [self reloadData];
    }
}

@end
