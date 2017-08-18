/*
 *  Copyright (c) 2017 Translation Exchange, Inc. All rights reserved.
 *
 *  _______                  _       _   _             ______          _
 * |__   __|                | |     | | (_)           |  ____|        | |
 *    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
 *    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
 *    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
 *    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
 *                                                                                        __/ |
 *                                                                                       |___/
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

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
 *
 *  @param data     JSON data. Typically API response
 *  @param aClass   Class of object, or array of objects, represented in data
 *
 *  @return Object of class aClass, or, if nil was passed, an instance of appropriate NS class.
 */
+ (id)materializeData:(NSData *)data
            withClass:(Class)aClass;

/**
 *  Method is identical to materializeData:withClass:delegate: 
 *  but uses JSON object as data source, as opposed to NSData.
 *
 *  @param object   JSON object
 *  @param aClass   Class of object, or array of objects, represented in data
 *
 *  @return Object of class aClass, or, if nil was passed, an instance of appropriate NS class.
 */
+ (id)materializeObject:(id)object
              withClass:(Class)aClass;

- (instancetype)initForReadingWithData:(NSData *)data;

/**
 *  Whether to include empty objects (enumerable with count of 0) when serializing or materializing.
 */
@property (assign, nonatomic) BOOL includeEmptyObjects;
/**
 *  Whether to include nils or properties with nil values, when serializing or materializing.
 */
@property (assign, nonatomic) BOOL includeNils;
@end
