//
//  TMLAlertController.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TML.h"
#import "TMLAlertController.h"
#import "UIView+TML.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>


UIFont * boldSystemFontOfSize(CGFloat size);
UIFont * mediumSystemFontOfSize(CGFloat size);
BOOL useWeight();

BOOL useWeight() {
    static BOOL result;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [UIFont methodForSelector:@selector(systemFontOfSize:weight:)] != nil;
    });
    return result;
}

UIFont * boldSystemFontOfSize(CGFloat size) {
    if (useWeight()) {
        return [UIFont systemFontOfSize:size weight:UIFontWeightBold];
    }
    else {
        return [UIFont fontWithName:@"Helvetica-Neue-Bold" size:size];
    }
}
UIFont * mediumSystemFontOfSize(CGFloat size) {
    if (useWeight()) {
        return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    }
    else {
        return [UIFont fontWithName:@"Helvetica-Neue-Medium" size:size];
    }
}

#pragma mark - TMLAlertTitleView
@interface TMLAlertTitleView : UIView
@property (strong, nonatomic) UILabel *titleLabel;
@property (assign, nonatomic) UIEdgeInsets titleLabelInset;
@property (strong, nonatomic) UILabel *messageLabel;
@property (assign, nonatomic) UIEdgeInsets messageLabelInset;
@property (strong, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) UIEdgeInsets imageViewInset;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSString *imagePlaceholderText;
@property (strong, nonatomic) UILabel *imagePlaceholderLabel;
@property (strong, nonatomic) UIColor *imagePlaceholderBackgroundColor;
@property (assign, nonatomic) BOOL imagePlaceholderHidden;
@end

@implementation TMLAlertTitleView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imagePlaceholderBackgroundColor = [UIColor colorWithRed:160./255. green:167./255. blue:184./255. alpha:1.];
        
        self.imageViewInset = UIEdgeInsetsMake(16, 8, 8, 8);
        self.titleLabelInset = UIEdgeInsetsMake(8, 16, 4, 16);
        self.messageLabelInset = UIEdgeInsetsMake(4, 16, 16, 16);
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:frame];
        titleLabel.font = mediumSystemFontOfSize(16.);
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel = titleLabel;
        
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:frame];
        messageLabel.font = [UIFont systemFontOfSize:12.];
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel = messageLabel;
        
        CGRect imageFrame = CGRectMake(0, 0, 64, 64);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageFrame];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.cornerRadius = 32.;
        imageView.clipsToBounds = YES;
        self.imageView = imageView;
        
        UILabel *placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(imageView.frame), CGRectGetHeight(imageView.frame))];
        placeholderLabel.textColor = [UIColor whiteColor];
        placeholderLabel.font = mediumSystemFontOfSize(18.);
        placeholderLabel.textAlignment = NSTextAlignmentCenter;
        self.imagePlaceholderLabel = placeholderLabel;
    }
    return self;
}

- (void)setTitleLabel:(UILabel *)titleLabel {
    if (_titleLabel == titleLabel) {
        return;
    }
    if (_titleLabel.superview != nil) {
        [_titleLabel removeFromSuperview];
    }
    _titleLabel = titleLabel;
    if (titleLabel != nil) {
        [self addSubview:titleLabel];
    }
    [self setNeedsLayout];
}

- (void)setMessageLabel:(UILabel *)messageLabel {
    if (_messageLabel == messageLabel) {
        return;
    }
    if (_messageLabel.superview != nil) {
        [_messageLabel removeFromSuperview];
    }
    _messageLabel = messageLabel;
    if (messageLabel != nil) {
        [self addSubview:messageLabel];
    }
    [self setNeedsLayout];
}

- (void)setImageView:(UIImageView *)imageView {
    if (_imageView == imageView) {
        return;
    }
    if (_imageView.superview != nil) {
        [_imageView removeFromSuperview];
    }
    _imageView = imageView;
    if (imageView != nil) {
        [self addSubview:imageView];
    }
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    [self updatePlaceholderVisibility];
}

- (void)setImagePlaceholderHidden:(BOOL)imagePlaceholderHidden {
    UILabel *label = self.imagePlaceholderLabel;
    UIImageView *imageView = self.imageView;
    if (imagePlaceholderHidden == YES && label.superview != nil) {
        imageView.backgroundColor = [UIColor clearColor];
        [label removeFromSuperview];
    }
    else if (imagePlaceholderHidden == NO && label.superview == nil) {
        imageView.backgroundColor = self.imagePlaceholderBackgroundColor;
        [imageView addSubview:label];
    }
}

- (BOOL)imagePlaceholderHidden {
    return self.imagePlaceholderLabel.superview == nil;
}

- (void)updatePlaceholderVisibility {
    self.imagePlaceholderHidden = (self.imageView.image != nil);
}

- (void)setImagePlaceholderText:(NSString *)imagePlaceholderText {
    UILabel *label = self.imagePlaceholderLabel;
    label.text = imagePlaceholderText;
    [self updatePlaceholderVisibility];
}

-(CGSize)sizeThatFits:(CGSize)size {
    CGSize availableSizeForLabels = size;
    UIImageView *imageView = self.imageView;
    CGSize imageSize = imageView.frame.size;
    UIEdgeInsets imageInset = self.imageViewInset;
    availableSizeForLabels.height -= imageSize.height + imageInset.top + imageInset.bottom;
    
    UILabel *titleLabel = self.titleLabel;
    BOOL hasTitle = (titleLabel.text != nil) ? YES : NO;
    CGSize fitTitleSize = CGSizeZero;
    UIEdgeInsets titleInset = self.titleLabelInset;
    if (hasTitle == YES) {
        CGSize sizeForTitle = availableSizeForLabels;
        sizeForTitle.width -= titleInset.left + titleInset.right;
        sizeForTitle.height -= titleInset.top + titleInset.bottom;
        fitTitleSize = [self.titleLabel sizeThatFits:sizeForTitle];
    }
    
    UILabel *messageLabel = self.messageLabel;
    BOOL hasMessage = (messageLabel.text != nil) ? YES : NO;
    CGSize fitMessageSize = CGSizeZero;
    UIEdgeInsets messageInset = self.messageLabelInset;
    if (hasMessage == YES) {
        CGSize sizeForMessage = availableSizeForLabels;
        sizeForMessage.width -= messageInset.left + messageInset.right;
        sizeForMessage.height -= messageInset.top + messageInset.bottom;
        fitMessageSize = [self.messageLabel sizeThatFits:sizeForMessage];
    }
    
    CGSize fitSize = size;
    fitSize.width = MAX(imageSize.width + imageInset.left + imageInset.right,
                        MAX(titleInset.left + titleInset.right + fitTitleSize.width,
                            messageInset.left + messageInset.right + fitMessageSize.width));
    fitSize.height = imageInset.top + imageInset.bottom + imageSize.height;
    if (hasTitle == YES) {
        fitSize.height += titleInset.top + fitTitleSize.height;
        if (hasMessage == YES) {
            fitSize.height += titleInset.bottom;
        }
        else {
            fitSize.height += messageInset.bottom;
        }
    }
    if (hasMessage == YES) {
        if (hasTitle == YES) {
            fitSize.height += messageInset.top;
        }
        else {
            fitSize.height += titleInset.top;
        }
        fitSize.height += messageInset.bottom + fitMessageSize.height;
    }
    return fitSize;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIImageView *imageView = self.imageView;
    UIEdgeInsets imageInset = self.imageViewInset;
    CGRect imageFrame = imageView.frame;
    
    UILabel *titleLabel = self.titleLabel;
    UIEdgeInsets titleInset = self.titleLabelInset;
    CGRect titleFrame = titleLabel.frame;
    
    UILabel *messageLabel = self.messageLabel;
    UIEdgeInsets messageInset = self.messageLabelInset;
    CGRect messageFrame = messageLabel.frame;
    
    CGRect ourBounds = self.bounds;
    CGRect frameForLabels = ourBounds;
    
    imageFrame.origin.y = imageInset.top;
    imageFrame.origin.x = CGRectGetMidX(ourBounds) - (CGRectGetWidth(imageFrame)/2.);
    CGRect imageBoundingBox = CGRectMake(CGRectGetMinX(imageFrame) - imageInset.left,
                                         0,
                                         CGRectGetWidth(imageFrame) + imageInset.left + imageInset.right,
                                         CGRectGetHeight(imageFrame) + imageInset.top + imageInset.bottom);
    
    BOOL hasTitle = (titleLabel.text != nil) ? YES : NO;
    BOOL hasMessage = (messageLabel.text != nil) ? YES : NO;
    
    frameForLabels = CGRectMake(0,
                                CGRectGetMaxY(imageBoundingBox),
                                CGRectGetWidth(ourBounds),
                                CGRectGetHeight(ourBounds) - CGRectGetHeight(imageBoundingBox));
    
    if (hasTitle == YES) {
        CGFloat titleBottomInset = (hasMessage == YES) ? titleInset.bottom : messageInset.bottom;
        titleFrame.origin.x = titleInset.left;
        titleFrame.origin.y = CGRectGetMaxY(imageBoundingBox) + titleInset.top;
        CGSize titleSize = CGSizeMake(CGRectGetWidth(frameForLabels) - titleInset.left - titleInset.right,
                                      CGRectGetHeight(frameForLabels) - titleInset.top - titleBottomInset);
        titleSize.height = [titleLabel sizeThatFits:titleSize].height;
        titleFrame.size = titleSize;
    }
    
    if (hasMessage == YES) {
        CGFloat messageTopInset = (hasTitle == YES) ? messageInset.top : titleInset.top;
        messageFrame.origin.x = messageInset.left;
        messageFrame.origin.y = CGRectGetMaxY(titleFrame) + titleInset.bottom + messageTopInset;
        CGSize messageSize = CGSizeMake(CGRectGetWidth(frameForLabels) - messageInset.left - messageInset.right,
                                        CGRectGetHeight(frameForLabels) - messageTopInset - messageInset.bottom);
        messageSize.height = [messageLabel sizeThatFits:messageSize].height;
        messageFrame.size = messageSize;
    }
    
    imageFrame.origin.x = floorf(imageFrame.origin.x);
    imageFrame.origin.y = floorf(imageFrame.origin.y);
    imageView.frame = imageFrame;
    
    UILabel *placeholder = self.imagePlaceholderLabel;
    CGRect placeholderFrame = imageView.bounds;
    placeholderFrame.size.height = [placeholder sizeThatFits:placeholderFrame.size].height;
    placeholderFrame.origin.y = floorf(CGRectGetMidY(imageView.bounds) - CGRectGetHeight(placeholderFrame)/2.0);
    placeholder.frame = placeholderFrame;
    
    titleFrame.origin.x = floorf(titleFrame.origin.x);
    titleFrame.origin.y = floorf(titleFrame.origin.y);
    titleLabel.frame = titleFrame;
    
    messageFrame.origin.x = floorf(messageFrame.origin.x);
    messageFrame.origin.y = floorf(messageFrame.origin.y);
    messageLabel.frame = messageFrame;
}

@end

#pragma mark - TMLAlertView

@interface TMLAlertView : UIView
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UIColor *backgroundViewColor;
@property (strong, nonatomic) TMLAlertTitleView *titleView;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIView *contentView;
@end

@implementation TMLAlertView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundViewColor = [UIColor colorWithWhite:0. alpha:0.33];
        UIView *backgroundView = [[UIView alloc] initWithFrame:frame];
        backgroundView.backgroundColor = self.backgroundViewColor;
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundView = backgroundView;
        [self addSubview:backgroundView];
        
        UIView *contentView = [[UIView alloc] initWithFrame:frame];
        contentView.backgroundColor = [UIColor colorWithRed:246./255. green:247./255. blue:248./255. alpha:1.];
        contentView.clipsToBounds = YES;
        contentView.layer.cornerRadius = 16.;
        self.contentView = contentView;
        [self addSubview:contentView];
        
        TMLAlertTitleView *titleView = [[TMLAlertTitleView alloc] initWithFrame:frame];
        self.titleView = titleView;
        [contentView addSubview:titleView];
        
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.minimumLineSpacing = 0.;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        self.collectionView = collectionView;
        [contentView addSubview:collectionView];
    }
    return self;
}

- (CGSize)preferredContentSize {
    CGSize preferredSize = CGSizeMake(270, 0);
    TMLAlertTitleView *titleView = self.titleView;
    CGSize titleSize = [titleView sizeThatFits:preferredSize];
    preferredSize.height = titleSize.height;
    
    UICollectionView *collectionView = self.collectionView;
    CGSize collectionContentSize = collectionView.contentSize;
    preferredSize.height += collectionContentSize.height;
    
    CGRect ourBounds = self.bounds;
    CGFloat maxHeight = CGRectGetHeight(ourBounds)*0.8;
    preferredSize.height = MIN(preferredSize.height, maxHeight);
    return preferredSize;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect ourBounds = self.bounds;
    
    CGSize preferredContentSize = [self preferredContentSize];
    UIView *contentView = self.contentView;
    CGRect contentFrame = contentView.frame;
    contentFrame.size = preferredContentSize;
    contentFrame.origin = CGPointMake(CGRectGetMidX(ourBounds) - preferredContentSize.width/2.,
                                      CGRectGetMidY(ourBounds) - preferredContentSize.height/2.);
    contentView.frame = contentFrame;
    
    TMLAlertTitleView *titleView = self.titleView;
    CGSize titleSize = [titleView sizeThatFits:preferredContentSize];
    CGRect titleFrame = CGRectMake(0, 0, preferredContentSize.width, titleSize.height);
    titleView.frame = titleFrame;
    
    UICollectionView *collectionView = self.collectionView;
    CGRect collectionFrame = collectionView.frame;
    collectionFrame.origin = CGPointMake(0, CGRectGetMaxY(titleFrame));
    collectionFrame.size = CGSizeMake(preferredContentSize.width, preferredContentSize.height - titleSize.height);
    collectionView.frame = collectionFrame;
}

- (void)alertWillAppear {
    UIView *backgroundView = self.backgroundView;
    backgroundView.backgroundColor = [UIColor clearColor];
    
    CGRect ourBounds = self.bounds;
    UIView *contentView = self.contentView;
    CGRect contentFrame = contentView.frame;
    contentFrame.origin.y = CGRectGetMaxY(ourBounds);
    contentView.frame = contentFrame;
}

- (void)alertDidAppear {
    UIView *backgroundView = self.backgroundView;
    backgroundView.backgroundColor = self.backgroundViewColor;
    
    CGRect ourBounds = self.bounds;
    UIView *contentView = self.contentView;
    CGRect contentFrame = contentView.frame;
    contentFrame.origin.y = floorf(CGRectGetMidY(ourBounds) - contentFrame.size.height/2.);
    contentView.frame = contentFrame;
}

- (void)alertWillDisappear {
}

- (void)alertDidDisappear {
    UIView *backgroundView = self.backgroundView;
    backgroundView.backgroundColor = [UIColor clearColor];
    
    CGRect ourBounds = self.bounds;
    UIView *contentView = self.contentView;
    CGRect contentFrame = contentView.frame;
    contentFrame.origin.y = CGRectGetMaxY(ourBounds);
    contentView.frame = contentFrame;
}

@end

#pragma mark - TMLAlertViewCell

@interface TMLAlertViewCell : UICollectionViewCell
@property (strong, nonatomic) UILabel *titleLabel;
@property (assign, nonatomic) UIEdgeInsets titleInset;
@property (assign, nonatomic) UIAlertActionStyle style;
@end

@implementation TMLAlertViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:frame];
        self.titleLabel = titleLabel;
        self.titleInset = UIEdgeInsetsMake(8, 8, 8, 8);
        [self.contentView addSubview:titleLabel];
        self.backgroundColor = [UIColor colorWithRed:246./255. green:247./255. blue:248./255. alpha:1.];
        
        UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 1)];
        border.backgroundColor = [UIColor colorWithWhite:0. alpha:0.23];
        border.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:border];
        
        self.style = UIAlertActionStyleDefault;
    }
    return self;
}

- (void)setStyle:(UIAlertActionStyle)style {
    _style = style;
    UILabel *titleLabel = self.titleLabel;
    if (style == UIAlertActionStyleDefault) {
        titleLabel.font = [UIFont systemFontOfSize:16.];
        titleLabel.textColor = [self tintColor];
    }
    else if (style == UIAlertActionStyleCancel) {
        titleLabel.font = boldSystemFontOfSize(16.);
        titleLabel.textColor = [self tintColor];
    }
    else if (style == UIAlertActionStyleDestructive) {
        titleLabel.font = boldSystemFontOfSize(16.);
        titleLabel.textColor = [UIColor redColor];
    }
}

- (void)tintColorDidChange {
    self.titleLabel.textColor = [self tintColor];
}

- (CGSize)sizeThatFits:(CGSize)size {
    UIEdgeInsets insets = self.titleInset;
    CGSize fitSize = [self.titleLabel sizeThatFits:CGSizeMake(size.width - insets.left - insets.right,
                                                              size.height - insets.top - insets.bottom)];
    fitSize.width = size.width;
    fitSize.height += insets.top + insets.bottom;
    return fitSize;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UILabel *titleLabel = self.titleLabel;
    CGRect titleFrame = titleLabel.frame;
    CGRect ourBounds = self.contentView.bounds;
    UIEdgeInsets inset = self.titleInset;
    CGSize titleSize = [titleLabel sizeThatFits:CGSizeMake(CGRectGetWidth(ourBounds) - inset.left - inset.right,
                                                           CGRectGetHeight(ourBounds) - inset.top - inset.bottom)];
    titleFrame.size = titleSize;
    titleFrame.origin.y = floorf(CGRectGetMidY(ourBounds) - titleSize.height/2.);
    titleFrame.origin.x = floorf(CGRectGetMidX(ourBounds) - titleSize.width/2.);
    titleLabel.frame = titleFrame;
}

@end

#pragma mark - TMLAlertAction

@interface TMLAlertAction()
@property (strong, nonatomic) NSString *title;
@property (copy, nonatomic) void (^handler)(TMLAlertAction *action);
@property (assign, nonatomic) UIAlertActionStyle style;
- (void)performActionHandler;
@end

@implementation TMLAlertAction
+ (instancetype)actionWithTitle:(NSString *)title
                          style:(UIAlertActionStyle)style
                        handler:(void (^)(TMLAlertAction *action))handler {
    TMLAlertAction *action = [[TMLAlertAction alloc] init];
    action.title = title;
    action.handler = [handler copy];
    action.enabled = YES;
    action.style = style;
    return action;
}

- (void)performActionHandler {
    if (self.handler != nil) {
        self.handler(self);
    }
}

@end

#pragma mark - TMLAlertController

@interface TMLAlertController ()<
UIViewControllerTransitioningDelegate,
UIViewControllerAnimatedTransitioning,
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout
> {
    NSMutableArray *_actions;
}
@property (readonly, nonatomic) TMLAlertTitleView *titleView;
@property (readonly, nonatomic) TMLAlertView *alertView;
@end

@implementation TMLAlertController

+ (instancetype)alertControllerWithTitle:(NSString *)title
                                 message:(NSString *)message
                                   image:(UIImage *)image
                        imagePlaceholder:(NSString *)placeholder
{
    TMLAlertController *alert = [[self alloc] init];
    alert.title = title;
    alert.message = message;
    alert.titleImage = image;
    alert.titleImagePlaceholderText = placeholder;
    return alert;
}

- (instancetype)init {
    if (self = [super init]) {
        TMLAlertView *alertView = [[TMLAlertView alloc] initWithFrame:CGRectZero];
        UICollectionView *collectionView = alertView.collectionView;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [collectionView registerClass:[TMLAlertViewCell class] forCellWithReuseIdentifier:NSStringFromClass([TMLAlertViewCell class])];
        self.view = alertView;
        self.modalPresentationStyle = UIModalPresentationCustom;
        _actions = [NSMutableArray array];
    }
    return self;
}

- (TMLAlertView *)alertView {
    return (TMLAlertView *)self.view;
}

- (TMLAlertTitleView *)titleView {
    return self.alertView.titleView;
}

- (void)setTitle:(NSString *)title {
    self.titleView.titleLabel.text = title;
    [self.view setNeedsLayout];
}

- (NSString *)title {
    return self.titleView.titleLabel.text;
}

- (void)setMessage:(NSString *)message {
    self.titleView.messageLabel.text = message;
}

- (NSString *)message {
    return self.titleView.messageLabel.text;
}

- (void)setTitleImage:(UIImage *)titleImage {
    self.titleView.image = titleImage;
    [self.view setNeedsLayout];
}

- (UIImage *)titleImage {
    return self.titleView.imageView.image;
}

- (void)setTitleImagePlaceholderText:(NSString *)titleImagePlaceholderText {
    self.titleView.imagePlaceholderText = titleImagePlaceholderText;
    [self.view setNeedsLayout];
}

- (NSString *)titleImagePlaceholderText {
    return self.titleView.imagePlaceholderText;
}

#pragma mark - Actions
- (NSArray *)actions {
    return [_actions copy];
}

- (void)addAction:(TMLAlertAction *)action {
    [_actions addObject:action];
    UICollectionView *collectionView = self.alertView.collectionView;
    [collectionView reloadData];
//    NSIndexPath *path = [NSIndexPath indexPathForRow:_actions.count-1 inSection:0];
//    [collectionView insertItemsAtIndexPaths:@[path]];
}

#pragma mark - UICollectionViewLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize alertSize = [self.alertView sizeThatFits:CGSizeZero];
    return CGSizeMake(alertSize.width, 44);
}

#pragma mark - UICollectionViewDataSource
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TMLAlertViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TMLAlertViewCell class]) forIndexPath:indexPath];
    TMLAlertAction *action;
    if (_actions.count >= indexPath.row) {
        action = [_actions objectAtIndex:indexPath.row];
    }
    
    cell.style = action.style;
    cell.titleLabel.text = action.title;
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _actions.count;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.row;
    if (_actions.count <= index) {
        return;
    }
    TMLAlertAction *action = [_actions objectAtIndex:index];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [action performActionHandler];
    }];
}

#pragma mark - Transitioning
- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationOverCurrentContext;
}

- (id<UIViewControllerTransitioningDelegate>)transitioningDelegate {
    return self;
}

#pragma mark - UIViewControllerTransitioningDelegate
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if (presented == self) {
        return self;
    }
    
    return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (dismissed == self) {
        return self;
    }
    return nil;
}

#pragma mark - UIViewControllerAnimatedTransitioning
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    UIView *ourView = nil;
    TMLAlertView *alertView = self.alertView;
    
    TMLConfiguration *config = [[TML sharedInstance] configuration];
    BOOL useBlur = (config.translationAlertUsesBlur == YES);
    
    __block UIView *fxView;
    const void * blurViewKey = "tmlBlurView";
    UIView *blurTargetView;
    
    if (toVC == self) {
        ourView = toVC.view;
        ourView.frame = [transitionContext finalFrameForViewController:toVC];
        [transitionContext.containerView addSubview:ourView];
        [alertView alertWillAppear];
        
        if (useBlur == YES) {
            blurTargetView = fromVC.view;
            fxView = objc_getAssociatedObject(blurTargetView, blurViewKey);
            if (fxView != nil) {
                [fxView removeFromSuperview];
            }
        
            UIBlurEffect *fx = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            fxView = [[UIVisualEffectView alloc] initWithEffect:fx];
            fxView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            fxView.frame = blurTargetView.bounds;
            fxView.alpha = 0.;
            [blurTargetView addSubview:fxView];
            objc_setAssociatedObject(blurTargetView, blurViewKey, fxView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    else if (fromVC == self) {
        ourView = fromVC.view;
        ourView.frame = [transitionContext initialFrameForViewController:fromVC];
        [alertView alertWillDisappear];
        
        if (useBlur == YES) {
            blurTargetView = toVC.view;
        }
    }
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0
         usingSpringWithDamping:1.4
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         if (toVC == self) {
                             [alertView alertDidAppear];
                             fxView.alpha = 1.;
                         }
                         else {
                             [alertView alertDidDisappear];
                             fxView = objc_getAssociatedObject(blurTargetView, blurViewKey);
                             fxView.alpha = 0.;
                         }
                     }
                     completion:^(BOOL finished) {
                         if (fromVC == self) {
                             fxView = objc_getAssociatedObject(blurTargetView, blurViewKey);
                             if (fxView != nil) {
                                 [fxView removeFromSuperview];
                                 objc_setAssociatedObject(blurTargetView, blurViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                             }
                         }
                         [transitionContext completeTransition:YES];
                     }];
}


@end
