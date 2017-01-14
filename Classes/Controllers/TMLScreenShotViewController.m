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

@interface TMLScreenShotView : UIView
@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic, readwrite) UITextField *titleField;
@property (strong, nonatomic, readwrite) UITextField *userDescriptionField;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *shadeView;
@property (assign, nonatomic) UIEdgeInsets contentInset;
@property (assign, nonatomic) UIEdgeInsets imageInset;
@end

@implementation TMLScreenShotView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentInset = UIEdgeInsetsMake(8, 8, 8, 8);
        self.imageInset = UIEdgeInsetsMake(0, 4, 0, 0);
        self.backgroundColor = [UIColor whiteColor];
        
        UIColor *tintColor = [UIColor colorWithRed:0.0 green:0.3 blue:0.7 alpha:0.93];
        UIColor *textColor = [UIColor whiteColor];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44)];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbar.barTintColor = tintColor;
        toolbar.tintColor = textColor;
        toolbar.barStyle = UIBarStyleBlackTranslucent;
        self.toolbar = toolbar;
        
        _shadeView = [[UIView alloc] initWithFrame:frame];
        _shadeView.backgroundColor = tintColor;
        [self addSubview:_shadeView];
        
        UITextField *titleField = [[UITextField alloc] initWithFrame:frame];
        titleField.placeholder = TMLLocalizedString(@"Title");
        titleField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleField.tintColor = textColor;
        titleField.textColor = textColor;
        titleField.backgroundColor = [UIColor clearColor];
        titleField.font = [UIFont systemFontOfSize:18.0];
        self.titleField = titleField;
        
        UITextField *descriptionView = [[UITextField alloc] initWithFrame:frame];
        descriptionView.placeholder = TMLLocalizedString(@"Description");
        descriptionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        descriptionView.tintColor = textColor;
        descriptionView.textColor = textColor;
        descriptionView.backgroundColor = [UIColor clearColor];
        descriptionView.font = [UIFont italicSystemFontOfSize:16.0];
        self.userDescriptionField = descriptionView;
    }
    return self;
}

- (void)layoutSubviews {
    CGRect ourBounds = self.bounds;
    CGRect toolbarFrame = _toolbar.frame;
    toolbarFrame.origin.x = 0.;
    toolbarFrame.origin.y = 0.;
    toolbarFrame.size.width = CGRectGetWidth(ourBounds);
    _toolbar.frame = toolbarFrame;
    
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    CGRect imageFrame = _imageView.frame;
    imageFrame.origin.x = 0.;
    imageFrame.origin.y = CGRectGetMaxY(toolbarFrame);
    imageFrame.size = ourBounds.size;
    imageFrame.size.height -= CGRectGetMaxY(toolbarFrame);
    imageFrame.size.height /= 2;
    _imageView.frame = imageFrame;
    [self sendSubviewToBack:_imageView];
    
    CGFloat spacing = 8.0;
    
    CGRect descriptionFrame = _userDescriptionField.frame;
    descriptionFrame.origin.x = _contentInset.left;
    descriptionFrame.size = [_userDescriptionField sizeThatFits:CGSizeMake(ourBounds.size.width - _contentInset.left - _contentInset.right, 24)];
    descriptionFrame.size.width = ourBounds.size.width;
    descriptionFrame.origin.y = CGRectGetMaxY(ourBounds) - descriptionFrame.size.height - spacing;
    _userDescriptionField.frame = descriptionFrame;
    
    CGRect titleFrame = _titleField.frame;
    titleFrame.origin.x = _contentInset.left;
    titleFrame.size = [_titleField sizeThatFits:CGSizeMake(ourBounds.size.width - _contentInset.left - _contentInset.right, 24)];
    titleFrame.size.width = ourBounds.size.width;
    titleFrame.origin.y = CGRectGetMinY(descriptionFrame) - spacing - titleFrame.size.height;
    _titleField.frame = titleFrame;
    
    CGRect shadeFrame = _shadeView.frame;
    shadeFrame.origin = CGPointMake(0, titleFrame.origin.y - spacing);
    shadeFrame.size = CGRectUnion(descriptionFrame, titleFrame).size;
    shadeFrame.size.width = ourBounds.size.width;
    shadeFrame.size.height += spacing * 2;
    _shadeView.frame = shadeFrame;
    
    [self bringSubviewToFront:_titleField];
    [self bringSubviewToFront:_userDescriptionField];
}

- (void)setImageView:(UIImageView *)imageView {
    if (_imageView == imageView) {
        return;
    }
    [_imageView removeFromSuperview];
    _imageView = imageView;
    if (imageView != nil) {
        [self addSubview:imageView];
    }
    [self setNeedsLayout];
}

- (void)setTitleField:(UITextField *)titleField {
    if (_titleField == titleField) {
        return;
    }
    [_titleField removeFromSuperview];
    _titleField = titleField;
    if (titleField != nil) {
        [self addSubview:titleField];
    }
    [self setNeedsLayout];
}

- (void)setUserDescriptionField:(UITextField *)userDescriptionField {
    if (_userDescriptionField == userDescriptionField) {
        return;
    }
    [_userDescriptionField removeFromSuperview];
    _userDescriptionField = userDescriptionField;
    if (userDescriptionField != nil) {
        [self addSubview:userDescriptionField];
    }
    [self setNeedsLayout];
}

- (void)setToolbar:(UIToolbar *)toolbar {
    if (_toolbar == toolbar) {
        return;
    }
    [_toolbar removeFromSuperview];
    _toolbar = toolbar;
    if (toolbar != nil) {
        [self addSubview:toolbar];
    }
    [self setNeedsLayout];
}

@end


@interface TMLScreenShotViewController ()
@property (strong, nonatomic) TMLScreenShot *screenShot;
@end

@implementation TMLScreenShotViewController

#pragma mark - UIViewController

- (void)loadView {
    TMLScreenShotView *view = [[TMLScreenShotView alloc] initWithFrame:CGRectZero];
    self.view = view;
    [self takeScreenshot];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIToolbar *toolbar = [[self screenShotView] toolbar];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:TMLLocalizedString(@"Cancel") style:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:TMLLocalizedString(@"Save") style:UIBarButtonSystemItemCancel target:self action:@selector(save:)];
    toolbar.items = @[cancel, flex, save];
}

- (CGSize)preferredContentSize {
    return CGSizeMake(320., 320.);
}

#pragma mark - Accessors

- (TMLScreenShotView *)screenShotView {
    return self.view;
}

- (UITextField *)titleField {
    return [(TMLScreenShotView *)self.view titleField];
}

- (void)setTitle:(NSString *)title {
    [[[self screenShotView] titleField] setText:title];
}

- (NSString *)title {
    return [[[self screenShotView] titleField] text];
}

- (UITextField *)userDescriptionField {
    return [(TMLScreenShotView *)self.view userDescriptionField];
}

- (void)setUserDescription:(NSString *)userDescription {
    [[[self screenShotView] userDescriptionField] setText:userDescription];
}

- (NSString *)userDescription {
    return [[[self screenShotView] userDescriptionField] text];
}

- (void)setScreenShot:(TMLScreenShot *)screenShot {
    if (_screenShot == screenShot) {
        return;
    }
    
    _screenShot = screenShot;
    UIImage *image = screenShot.image;
    UIImageView *imageView = nil;
    if (image == nil) {
        [[self screenShotView] setImageView:imageView];
        return;
    }
    imageView = [[UIImageView alloc] initWithImage:image];
    [[self screenShotView] setImageView:imageView];
}

#pragma mark - ScreenShot
- (void)takeScreenshot {
    TMLScreenShot *screenshot = [TMLScreenShot screenShot];
    screenshot.title = TMLLocalizedString(@"New Screenshot");
    screenshot.userDescription = TMLLocalizedString(@"New screenshot description");
    self.screenShot = screenshot;
}

#pragma mark - Actions
- (void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save:(id)sender {
    TMLScreenShot *screenShot = self.screenShot;
    NSString *title = self.titleField.text;
    NSString *description = self.userDescriptionField.text;
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
}

@end
