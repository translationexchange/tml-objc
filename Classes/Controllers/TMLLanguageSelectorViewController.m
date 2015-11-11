/*
 *  Copyright (c) 2015 Translation Exchange, Inc. All rights reserved.
 *
 *  _______                  _       _   _             ______          _
 * |__   __|                | |     | | (_)           |  ____|        | |
 *    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
 *    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
 *    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
 *    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
 *                                                                                        __/ |
 *                                                                                       |___/
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */


#import "MBProgressHUD.h"
#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLApplication.h"
#import "TMLLanguage.h"
#import "TMLLanguageSelectorViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TMLLanguageSelectorViewController ()

@property(nonatomic, strong) IBOutlet UITableView *tableView;

@property(nonatomic, strong) NSMutableArray *languages;

- (IBAction) dismiss: (id)sender;

@end

@implementation TMLLanguageSelectorViewController

+ (void) changeLanguageFromController:(UIViewController *) controller {
    TMLLanguageSelectorViewController *selector = [[TMLLanguageSelectorViewController alloc] init];
    selector.delegate = (id<TMLLanguageSelectorViewControllerDelegate>) controller;
    [controller presentViewController:selector animated: YES completion: nil];
}

- (id)init {
    self = [super init];
    if (self) {
        self.languages = [NSMutableArray array];
    }
    return self;
}

- (void) loadView {
    [super loadView];

    self.view.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 25, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:TMLLocalizedString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(dismiss:)];
    
    UINavigationItem *titleItem = [[UINavigationItem alloc] initWithTitle:TMLLocalizedString(@"Select Language")];
    titleItem.leftBarButtonItem=doneButton;
    navBar.items = @[titleItem];
    [self.view addSubview:navBar];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 70, self.view.frame.size.width, self.view.frame.size.height - 70)];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = TMLLocalizedString(@"Loading Languages...");
    TMLAPIClient *apiClient = [[[TML sharedInstance] currentApplication] apiClient];
    
    [apiClient getProjectLanguagesWithOptions:nil completionBlock:^(NSArray<TMLLanguage *> *newLanguages, NSError *error) {
        if (newLanguages != nil) {
            self.languages = [newLanguages mutableCopy];
            [self.tableView reloadData];
            
            hud.labelText = TMLLocalizedString(@"Languages updated");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [hud hide:YES];
            });
        }
        else {
            // TODO: no more cache; should use bundles
            //           NSArray *locales = [[TML cache] cachedLocales];
            //           NSArray *locales = nil;
            //
            //           self.languages = [NSMutableArray array];
            //           for (NSString *locale in locales) {
            //               [self.languages addObject:[[TML currentApplication] languageForLocale:locale]];
            //           }
            //           [self.tableView reloadData];
            //
            //           hud.labelText = TMLLocalizedString(@"Loaded cached languages");
            //
                       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                           [hud hide:YES];
                       });
        }
    }];
}

-(IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_languages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"UITableViewCell"];
    }
    
    TMLLanguage *language = (TMLLanguage *)[self.languages objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = language.nativeName;
    cell.textLabel.text = language.englishName;
    if ([[[TML sharedInstance] currentLanguage].locale isEqualToString:language.locale]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TMLLanguage *language = (TMLLanguage *)[self.languages objectAtIndex:indexPath.row];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = TMLLocalizedString(@"Switching language...");

    [TML changeLocale:language.locale completionBlock:^(BOOL success) {
        if (success == YES) {
            if (_delegate && [_delegate respondsToSelector:@selector(tmlLanguageSelectorViewController:didSelectLanguage:)]) {
                [_delegate tmlLanguageSelectorViewController:self didSelectLanguage:language];
            }
            
            hud.labelText = TMLLocalizedString(@"Language changed");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [hud hide:YES];
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
        else {
            if (_delegate && [_delegate respondsToSelector:@selector(tmlLanguageSelectorViewController:didSelectLanguage:)]) {
                [_delegate tmlLanguageSelectorViewController:self didSelectLanguage:language];
            }
            
            hud.labelText = TMLLocalizedString(@"Language changed");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [hud hide:YES];
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }];
}

@end
