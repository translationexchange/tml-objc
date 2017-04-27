//
//  TMLScreenshotViewController.m
//  TMLKit
//
//  Created by Pasha on 1/2/17.
//  Copyright © 2017 Translation Exchange. All rights reserved.
//

#import "TML.h"
#import "TMLAPIClient.h"
#import "TMLScreenShot.h"
#import "TMLScreenshotViewController.h"

@interface TMLScreenShotViewController ()

@property (strong, nonatomic) TMLScreenShot *screenShot;
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation TMLScreenShotViewController

#pragma mark - UIViewController

- (void)loadView {
    self.imageView = [[UIImageView alloc] init];
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    self.view = self.imageView;
    
    [self takeScreenshot];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:TMLLocalizedString(@"Screenshot") message:TMLLocalizedString(@"Please enter title and description for the screenshot.") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:TMLLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:TMLLocalizedString(@"Submit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        TMLScreenShot *screenShot = self.screenShot;
        
        NSString *title = alertController.textFields[0].text;
        NSString *description = alertController.textFields[1].text;
        
        [self dismissViewControllerAnimated:YES completion:^{
            if (screenShot != nil) {
                screenShot.title = title;
                screenShot.userDescription = description;
                TMLAPIClient *apiClient = [[TML sharedInstance] apiClient];
                [apiClient postScreenShot:screenShot completionBlock:^(BOOL success, NSError *error) {
                    TMLInfo(@"Posted screenshot...");
                }];
            }
        }];
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = TMLLocalizedString(@"Title");
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = TMLLocalizedString(@"Description");
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:submitAction];
    
    [self presentViewController:alertController animated:true completion:nil];
}

- (UIModalTransitionStyle)modalTransitionStyle {
    return UIModalTransitionStyleCrossDissolve;
}

#pragma mark - Accessors

- (void)setScreenShot:(TMLScreenShot *)screenShot {
    if (_screenShot == screenShot) {
        return;
    }
    
    _screenShot = screenShot;
    self.imageView.image = screenShot.image;
}

#pragma mark - ScreenShot

- (void)takeScreenshot {
    TMLScreenShot *screenshot = [TMLScreenShot screenShot];
    screenshot.title = TMLLocalizedString(@"New Screenshot");
    screenshot.userDescription = TMLLocalizedString(@"New screenshot description");
    self.screenShot = screenshot;
}

@end
