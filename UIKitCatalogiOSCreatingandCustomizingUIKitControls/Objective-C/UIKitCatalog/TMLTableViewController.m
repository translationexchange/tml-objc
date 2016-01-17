//
//  TMLTableViewController.m
//  UIKitCatalog
//
//  Created by Pasha on 1/17/16.
//  Copyright © 2016 f. All rights reserved.
//

#import "TMLTableViewController.h"

@interface TMLTableViewController ()

@end

@implementation TMLTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TML sharedInstance] registerObjectWithReusableLocalizedStrings:self];
}

#pragma mark - TML
- (void)updateReusableTMLStrings {
    [super updateReusableTMLStrings];
    [self.tableView reloadData];
}

@end
