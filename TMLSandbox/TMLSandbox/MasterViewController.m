//
//  MasterViewController.m
//  TMLSandbox
//
//  Created by Pasha on 2/17/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "MasterViewController.h"
#import "TonsOfStringsTableViewController.h"

typedef NS_ENUM(NSInteger, DetailRow) {
    TonsOfStringsTableViewControllerRow = 0
};

@interface MasterViewController ()
@end

@implementation MasterViewController

- (void)viewDidLoad {
    self.title = @"TMLSandbox";
    [super viewDidLoad];
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSInteger row = indexPath.row;
    // Tons of Strings
    if (row == TonsOfStringsTableViewControllerRow) {
        cell.textLabel.text = @"Tons of strings";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    // Tons of Strings
    if (row == TonsOfStringsTableViewControllerRow) {
        TonsOfStringsTableViewController *controller = [[TonsOfStringsTableViewController alloc] init];
        [self presentDetailController:controller];
    }
}

#pragma mark - Presentation
- (void)presentDetailController:(UIViewController *)detailController {
    [self.navigationController pushViewController:detailController animated:YES];
}

@end
