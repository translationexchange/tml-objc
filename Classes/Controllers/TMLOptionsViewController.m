//
//  TMLOptionsViewController.m
//  TMLKit
//
//  Created by Konstantin Kabanov on 28/11/2017.
//

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
        self.inlineTranslationModeValueLabel.text = @"In-App";
    } else {
        self.inlineTranslationModeValueLabel.text = @"Dashboard";
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Inline Translation Mode" message:@"Tap and hold a string to translate it inline. In-app mode presents translation center in the app and dashboard mode only highlights selected string on the dashboard." preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"In-App" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [TML sharedInstance].dashboardInlineTranslationModeActive = NO;
        [self configureView];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Dashboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [TML sharedInstance].dashboardInlineTranslationModeActive = YES;
        [self configureView];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
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
