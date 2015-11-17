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
/**
 *  Serializes object into JSON data. Usually for transmission to the API node.
 *
 *  @param object Any of NSNumber, NSString, NSArray, NSDictionary or TMLBase
 *
 *  @return JSON data representation of passed object. This can be turned into JSON Object or JSON String.
 */
+ (NSData *)serializeObject:(id)object;

/**
 *  Materializes JSON data into an object of given class. If class is omitted, TMLAPISerializes tries to guess.
 *  Don't, however, expect it to guess anything out of ordinary - it will stick to NS classes.
 *  So, if you're expecting nothing other than a number, array or dictionary - pass nil.
 *  If you're expecting array of specific objects, pass class of those specific objects as it will be used
 *  to instantiate objects using that class.
 *  For deep structures, use delegate to determine class of objects to be instantiate, based on a key of the data
 *  that is to be used for instantiation. 
 *
 *  For example: Let's say that @{@"rules": @[{@"ruleName": @"My rule"}]} represents a top object of class RuleContainer
 *  which contains a list of rules, which are instances of class Rule. You'd pass RuleContainer class to this method,
 *  and your delegate object will be asked for class for the key "rules", in which case the delegate object should
 *  return RuleContainer class. A bit ugly, but API responses don't have any identifiers to otherwise distinguish
 *  one class of objects from another...
 *
 *  @param data     JSON data. Typically API response
 *  @param aClass   Class of object, or array of objects, represented in data
 *  @param delegate Delegate
 *
 *  @return Object of class aClass, or, if nil was passed, an instance of appropriate NS class.
 */
+ (id)materializeData:(NSData *)data
            withClass:(Class)aClass
             delegate:(id<TMLAPISerializerDelegate>)delegate;

/**
 *  Method is identical to materializeData:withClass:delegate: 
 *  but uses JSON object as data source, as opposed to NSData.
 *
 *  @param object   JSON object
 *  @param aClass   Class of object, or array of objects, represented in data
 *  @param delegate Delegate
 *
 *  @return Object of class aClass, or, if nil was passed, an instance of appropriate NS class.
 */
+ (id)materializeObject:(id)object
              withClass:(Class)aClass
               delegate:(id<TMLAPISerializerDelegate>)delegate;

/**
 *  Whether to include empty objects (enumerable with count of 0) when serializing or materializing.
 */
@property (assign, nonatomic) BOOL includeEmptyObjects;
/**
 *  Whether to include nils or properties with nil values, when serializing or materializing.
 */
@property (assign, nonatomic) BOOL includeNils;
@property (weak, nonatomic) id<TMLAPISerializerDelegate> delegate;
@end
