//
//  TMLAnalytics.h
//  TMLKit
//
//  Created by Pasha on 1/25/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TMLAnalyticsEventTypeKey;
extern NSString * const TMLAnalyticsEventDataKey;
extern NSString * const TMLAnalyticsPageViewEventName;

@interface TMLAnalytics : NSObject

+ (instancetype)sharedInstance;

- (void)reportEvent:(NSDictionary *)event;
- (void)submitQueuedEvents;

@end
