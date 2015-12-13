//
//  TMLAppDelegate.m
//  Sample
//
//  Created by Michael Berkovich on 1/30/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import "AppDelegate.h"
#import "IIViewDeckController.h"
#import "MenuViewController.h"
#import "TMLPrivateConfig.h"

#ifndef TMLAccessToken
#define TMLAccessToken @"8641229aae46c7d39e78657e9da0c86c80f432c21e4e4fb5bf0934673499be7a"
#endif
#ifndef TMLApplicationKey
#define TMLApplicationKey @"8641229aae46c7d39e78657e9da0c86c80f432c21e4e4fb5bf0934673499be7a"
#endif

@interface AppDelegate()<TMLDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    TML *tml = [TML sharedInstanceWithApplicationKey:TMLApplicationKey accessToken:TMLAccessToken];
    tml.delegate = self;
    

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self.window.rootViewController = [[IIViewDeckController alloc] initWithCenterViewController:[mainStoryboard instantiateViewControllerWithIdentifier: @"WelcomeViewController"]
                                                                             leftViewController:[mainStoryboard instantiateViewControllerWithIdentifier: @"MenuViewController"]];
    [self.window makeKeyAndVisible];
    
    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge
                                                                                             |UIUserNotificationTypeSound
                                                                                             |UIUserNotificationTypeAlert)
                                                                                 categories:nil];
        [app registerUserNotificationSettings:settings];
    }

    return YES;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    TMLDebug(@"%@", [err description]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    TMLDebug(@"%@", [userInfo description]);
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@""
                                                     message:[[userInfo valueForKey:@"aps"] valueForKey:@"alert"]
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert show];
}

#pragma mark - TMLDelegate
#if (TARGET_IPHONE_SIMULATOR)
- (UIGestureRecognizer *)gestureRecognizerForTranslationActivation {
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
    gestureRecognizer.numberOfTouchesRequired = 2;
    return gestureRecognizer;
}
#endif
@end

