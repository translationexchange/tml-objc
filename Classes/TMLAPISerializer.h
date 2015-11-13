//
//  TMLAPISerializer.h
//  Demo
//
//  Created by Pasha on 11/11/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TMLAPISerializerDelegate <NSObject>
@required
- (Class) classForObject:(id)object withKey:(NSString *)key;
@end

@interface TMLAPISerializer : NSCoder
+ (NSData *)serializeObject:(id)object;
+ (id)materializeData:(NSData *)data
            withClass:(Class)aClass
             delegate:(id<TMLAPISerializerDelegate>)delegate;
+ (id)materializeObject:(id)object
              withClass:(Class)aClass
               delegate:(id<TMLAPISerializerDelegate>)delegate;
@property (assign, nonatomic) BOOL includeEmptyObjects;
@property (assign, nonatomic) BOOL includeNils;
@property (weak, nonatomic) id<TMLAPISerializerDelegate> delegate;
@end
