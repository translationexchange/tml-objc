//
//  NSObject+JSON.h
//  Demo
//
//  Created by Pasha on 11/10/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (TMLJSON)
- (NSString *)tmlJSONString;
@end

@interface NSString (TMLJSON)
- (NSString *)tmlJSONString;
- (id)tmlJSONObject;
@end

@interface NSArray (TMLJSON)
- (NSString *)tmlJSONString;
@end

@interface NSDictionary (TMLJSON)
- (NSString *)tmlJSONString;
@end

@interface NSData (TMLJSON)
- (NSString *)tmlJSONString;
- (id)tmlJSONObject;
@end