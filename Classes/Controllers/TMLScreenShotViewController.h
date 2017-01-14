//
//  TMLScreenshotViewController.h
//  TMLKit
//
//  Created by Pasha on 1/2/17.
//  Copyright © 2017 Translation Exchange. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMLViewController.h"

@interface TMLScreenShotViewController : TMLViewController
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *userDescription;
@property (strong, nonatomic, readonly) UITextField *titleField;
@property (strong, nonatomic, readonly) UITextField *userDescriptionField;
@end
