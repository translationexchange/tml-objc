//
//  TMLAuthorizationViewController.h
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const TMLAuthorizationStatusKey;
extern NSString * const TMLAuthorizationStatusAuthorized;
extern NSString * const TMLAuthorizationAccessTokenKey;
extern NSString * const TMLAuthorizationTranslatorInfoKey;
extern NSString * const TMLAuthorizationTranslatorIDKey;
extern NSString * const TMLAuthorizationTranslatorFirstNameKey;
extern NSString * const TMLAuthorizationTranslatorMugshotKey;
extern NSString * const TMLAuthorizationTranslatorInlineModeKey;

@protocol TMLAuthorizationViewControllerDelegate;

@interface TMLAuthorizationViewController : UIViewController
@property (weak, nonatomic) id<TMLAuthorizationViewControllerDelegate> delegate;
@end

@protocol TMLAuthorizationViewControllerDelegate <NSObject>
@optional
- (void) authorizationViewController:(TMLAuthorizationViewController *)controller
                        didAuthorize:(NSDictionary *)userInfo;
@end