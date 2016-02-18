//
//  TonsOfStringsTableViewController.m
//  TMLSandbox
//
//  Created by Pasha on 2/17/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TonsOfStringsTableViewController.h"


@interface Cell : UITableViewCell
@end
@implementation Cell
@end


@interface TonsOfStringsTableViewController ()
@property (strong, nonatomic) NSArray *strings;
@end

#define MAX_STRINGS INFINITY

@implementation TonsOfStringsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSError *error = nil;
    NSString *string = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"words" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    NSArray *strings = [string componentsSeparatedByString:@"\n"];
    NSMutableArray *localizedStrings = [NSMutableArray array];
    for (NSString *string in strings) {
        [localizedStrings addObject:TMLLocalizedString(string)];
        if (MAX_STRINGS != INFINITY
            && localizedStrings.count >= MAX_STRINGS) {
            break;
        }
    }
    self.strings = localizedStrings;
    
    [self.tableView registerClass:[Cell class] forCellReuseIdentifier:@"Cell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.strings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *str = [self.strings objectAtIndex:indexPath.row];
    cell.textLabel.text = str;
    return cell;
}

@end
