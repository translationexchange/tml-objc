//
//  TMLAlertController.h
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMLAlertAction : NSObject
+ (instancetype) actionWithTitle:(NSString *)title
                           style:(UIAlertActionStyle)style
                         handler:(void(^)(TMLAlertAction *action))handler;
@property (readonly, nonatomic) NSString *title;
@property (assign, nonatomic) BOOL enabled;
@end

@interface TMLAlertController : UIViewController
+ (instancetype)alertControllerWithTitle:(NSString *)title
                                 message:(NSString *)message
                                   image:(UIImage *)image
                        imagePlaceholder:(NSString *)placeholder;

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *message;
@property (copy, nonatomic) UIImage *titleImage;
@property (copy, nonatomic) NSString *titleImagePlaceholderText;
@property (readonly, nonatomic) NSArray *actions;
- (void)addAction:(TMLAlertAction *)action;
@property (strong, nonatomic) TMLAlertAction *preferredAction;
@end
