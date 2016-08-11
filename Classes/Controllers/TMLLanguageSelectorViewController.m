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
#import "TMLApplication.h"
#import "TMLLanguage.h"
#import "TMLLanguageSelectorViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TMLLanguageSelectorViewController () <MBProgressHUDDelegate> {
    BOOL _observingNotifications;
}

@property(nonatomic, strong) IBOutlet UITableView *tableView;
@property(nonatomic, strong) NSArray *languages;
- (IBAction) dismiss: (id)sender;

@end

@implementation TMLLanguageSelectorViewController

- (void)dealloc {
    [self teardownNotificationObserving];
}

- (void) loadView {
    [super loadView];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:TMLLocalizedString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(dismiss:)];
    
    self.title = TMLLocalizedString(@"Select Language");
    self.navigationItem.leftBarButtonItem = doneButton;
    
    self.languages = TMLLanguages();
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.view addSubview:self.tableView];
    
    [self setupNotificationObserving];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notifications

- (void)setupNotificationObserving {
    if (_observingNotifications == YES) {
        return;
    }
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(localizationDataChanged:)
                               name:TMLLocalizationDataChangedNotification
                             object:nil];
    _observingNotifications = YES;
}

- (void)teardownNotificationObserving {
    if (_observingNotifications == NO) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _observingNotifications = NO;
}

- (void)localizationDataChanged:(NSNotification *)aNotification {
    self.languages = TMLLanguages();
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.languages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"UITableViewCell"];
    }
    
    NSArray *languages = self.languages;
    
    TMLLanguage *language = (TMLLanguage *)[languages objectAtIndex:indexPath.row];
    NSString *englishName = language.englishName;
    NSString *nativeName = language.nativeName;
    cell.detailTextLabel.text = (nativeName == nil) ? englishName : nativeName;
    cell.textLabel.text = englishName;
    NSString *currentLocale = TMLCurrentLocale();
    if ([currentLocale isEqualToString:language.locale]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TMLLanguage *language = (TMLLanguage *)[self.languages objectAtIndex:indexPath.row];
    NSString *newLocale = language.locale;
    TML *tml = [TML sharedInstance];
    MBProgressHUD *hud = nil;
    
    if ([tml hasLocalTranslationsForLocale:newLocale] == NO) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = TMLLocalizedString(@"Switching language...");
        hud.delegate = self;
        [hud showAnimated:YES];
    }

    [tml changeLocale:newLocale
      completionBlock:^(BOOL success) {
          if (success == YES) {
              if (_delegate && [_delegate respondsToSelector:@selector(tmlLanguageSelectorViewController:didSelectLanguage:)]) {
                  [_delegate tmlLanguageSelectorViewController:self didSelectLanguage:language];
              }
          }
          if (hud != nil) {
              [hud hideAnimated:YES];
          }
          else {
              dispatch_async(dispatch_get_main_queue(), ^{
                  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
              });
          }
      }];
}

#pragma mark - MBProgressHUDDelegate
- (void)hudWasHidden:(MBProgressHUD *)hud {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
