//
//  TMLScreenShot.m
//  TMLKit
//
//  Created by Pasha on 12/30/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TMLScreenShot.h"
#import "NSObject+TML.h"
#import "UIView+TML.h"
#import "TMLTranslationKey.h"

@interface TMLScreenShot ()
@property (strong, nonatomic, readwrite) UIImage *image;
@property (strong, nonatomic, readwrite) NSDictionary *keys;
@end

@implementation TMLScreenShot

+ (UIImage *)screenshotWindow {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        return nil;
    }
    return [self screenshotView:keyWindow];
}

+ (UIImage *)screenshotTopViewController {
    UIViewController *topViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    if (topViewController == nil) {
        return nil;
    }
    return [self screenshotView:topViewController.view];
}

+ (UIImage *) screenshotView: (UIView *)view {
    CGSize viewSize = view.bounds.size;
    UIGraphicsBeginImageContextWithOptions(viewSize, view.opaque, 1.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
# if TARGET_IPHONE_SIMULATOR
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:@"/Users/pasha/Desktop/screenshot.png" atomically:YES];
#endif
    
    return image;
}

+ (NSDictionary *) findViewsWithTranslationKeys: (UIView *)view relativeTo: (UIView *)relativeView {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    UIView *parentView = (relativeView == nil) ?  view : relativeView;
    NSSet *keyPaths = [view tmlLocalizableKeyPaths];
    for (NSString *path in keyPaths) {
        NSDictionary *reuseInfo = [view tmlInfoForReuseIdentifier:path];
        NSString *translationKey = reuseInfo[TMLTranslationKeyInfoKey];
        if (translationKey != nil) {
            CGRect frame = [view convertRect:view.bounds toView:parentView];
            results[translationKey] = [NSValue valueWithCGRect:frame];
        }
    }
    
    for (UIView *subview in view.subviews) {
        NSDictionary *subResults = [self findViewsWithTranslationKeys:subview relativeTo:parentView];
        [results addEntriesFromDictionary:subResults];
    }
    
    return results;
}

+ (instancetype) screenShot {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    TMLScreenShot *instance = [TMLScreenShot new];
    instance.image = [self screenshotView:window];
    instance.keys = [self findViewsWithTranslationKeys:window relativeTo:nil];
    return instance;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    UIImage *image = self.image;
    NSData *imageData = (image != nil) ? UIImagePNGRepresentation(image) : nil;
    if (imageData != nil) {
        [aCoder encodeObject:imageData forKey:@"image"];
    }
    NSDictionary *keys = self.keys;
    if (keys != nil) {
        NSMutableDictionary *keysForAPI = [NSMutableDictionary dictionary];
        for (TMLTranslationKey *key in keys) {
            CGRect frame = [keys[key] CGRectValue];
            keysForAPI[key.key] = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithFloat:frame.origin.x], @"left",
                               [NSNumber numberWithFloat:frame.origin.y], @"top",
                               [NSNumber numberWithFloat:frame.size.width], @"width",
                               [NSNumber numberWithFloat:frame.size.height], @"height", nil];
        }
        [aCoder encodeObject:keysForAPI forKey:@"keys"];
    }
    NSString *title = self.title;
    if (title != nil) {
        [aCoder encodeObject:title forKey:@"title"];
    }
    NSString *description = self.userDescription;
    if (description != nil) {
        [aCoder encodeObject:description forKey:@"description"];
    }
}

@end
