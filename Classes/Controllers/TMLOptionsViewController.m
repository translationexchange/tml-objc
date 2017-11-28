/*
 *  Copyright (c) 2017 Translation Exchange, Inc. All rights reserved.
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


#import "TMLOptionsViewController.h"
#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLAPIResponse.h"

@interface TMLOptionsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *initialsLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *profileActivityIndicator;

@property (weak, nonatomic) IBOutlet UISwitch *translationActiveSwitch;
@property (weak, nonatomic) IBOutlet UILabel *inlineTranslationModeValueLabel;

@end

@implementation TMLOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configureView];
    [self fetchTranslator];
}

- (void)configureView {
    if (self.translator) {
        self.nameLabel.hidden = NO;
        self.emailLabel.hidden = NO;
        self.profileImageView.hidden = NO;
        self.initialsLabel.hidden = NO;
        [self.profileActivityIndicator stopAnimating];
        
        self.nameLabel.text = self.translator.displayName;
        self.emailLabel.text = self.translator.email;
        self.initialsLabel.text = [self.translator initials];
        
        NSURL *mugshotURL = self.translator.mugshotURL;
        
        if (mugshotURL != nil) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:mugshotURL];
                if (imageData != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.profileImageView.image = [UIImage imageWithData:imageData];
                        self.initialsLabel.hidden = YES;
                    });
                }
            });
        } else {
            self.initialsLabel.hidden = NO;
        }
    } else {
        self.nameLabel.hidden = YES;
        self.emailLabel.hidden = YES;
        self.profileImageView.hidden = YES;
        self.initialsLabel.hidden = YES;
        [self.profileActivityIndicator startAnimating];
    }
    
    self.translationActiveSwitch.on = [TML sharedInstance].translationActive;
    
    if (![TML sharedInstance].dashboardInlineTranslationModeActive) {
        self.inlineTranslationModeValueLabel.text = TMLLocalizedString(@"In-App");
    } else {
        self.inlineTranslationModeValueLabel.text = TMLLocalizedString(@"Dashboard");
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            [self presentInlineTranslationModeAlertView];
        } else if (indexPath.row == 2) {
            [[TML sharedInstance] signout];
            
            [self dismissViewControllerAnimated:true completion:nil];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            [[TML sharedInstance] presentLanguageSelectorController];
        } else if (indexPath.row == 1) {
            [[TML sharedInstance] presentScreenshotController];
        }
    }
}

- (void)fetchTranslator {
    [[TML sharedInstance].apiClient getUserInfo:^(TMLUser *user, TMLAPIResponse *response, NSError *error) {
        if (error != nil) {
            TMLError(@"Error retrieving user based on supplied access token");
        }
        if (user != nil) {
            self.translator = (TMLBasicUser *)user;
            [self configureView];
        }
    }];
}

- (void)presentInlineTranslationModeAlertView {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:TMLLocalizedString(@"Inline Translation Mode") message:TMLLocalizedString(@"Tap and hold a string to translate it inline. In-app mode presents translation center in the app and dashboard mode only highlights selected string on the dashboard.") preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:TMLLocalizedString(@"In-App") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [TML sharedInstance].dashboardInlineTranslationModeActive = NO;
        [self configureView];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:TMLLocalizedString(@"Dashboard") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [TML sharedInstance].dashboardInlineTranslationModeActive = YES;
        [self configureView];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:TMLLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:true completion:nil];
}

- (IBAction)didPressCancelButton:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)didSwitchTranslationActiveSwitch:(id)sender {
    [[TML sharedInstance] toggleActiveTranslation];
    [self configureView];
}

@end
