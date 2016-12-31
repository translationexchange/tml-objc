//
//  TMLScreenShot.h
//  TMLKit
//
//  Created by Pasha on 12/30/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMLScreenShot : NSObject <NSCoding>
@property (strong, nonatomic, readonly) UIImage *image;
@property (strong, nonatomic, readonly) NSDictionary *keys;
@property (strong, nonatomic, readwrite) NSString *title;
@property (strong, nonatomic, readwrite) NSString *userDescription;
+ (instancetype) screenShot;
@end
