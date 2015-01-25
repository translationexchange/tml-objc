//
//  TmlAppDelegate.m
//  Sample
//
//  Created by Michael Berkovich on 1/30/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import "AppDelegate.h"
#import "Tml.h"
#import "IIViewDeckController.h"
#import "MenuViewController.h"
#import "TmlPostOffice.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [Tml sharedInstanceWithToken:@"c1b24de175b50f9d37d1259024689e9fea2c51ea28679517109925539afbed58"];

//    [Tml sharedInstanceWithToken:@"ca989a39e14a7d8ce17ddce533c14e1b1bb31623b7670dd14ea1a59313e59fa9"
//                   launchOptions:@{@"host": @"http://localhost:3000"}];
 
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self.window.rootViewController = [[IIViewDeckController alloc] initWithCenterViewController:[mainStoryboard instantiateViewControllerWithIdentifier: @"WelcomeViewController"]
                                                                             leftViewController:[mainStoryboard instantiateViewControllerWithIdentifier: @"MenuViewController"]];
    [self.window makeKeyAndVisible];
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                         |UIRemoteNotificationTypeSound
                                                                                         |UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
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

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[[Tml currentApplication] postOffice] registerToken: [deviceToken description]];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    TmlDebug(@"%@", [err description]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    TmlDebug(@"%@", [userInfo description]);
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@""
                                                     message:[[userInfo valueForKey:@"aps"] valueForKey:@"alert"]
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert show];
}

@end

