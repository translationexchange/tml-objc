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


#import "NSObject+TMLJSON.h"
#import "TMLJSONValueTransformer.h"

@implementation NSObject (TMLJSON)
- (NSString *)tmlJSONString {
    NSData *data = nil;
    if ([self conformsToProtocol:@protocol(NSCoding)] == YES) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:TMLJSONValueTransformerName];
        data = [transformer transformedValue:self];
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                       options:0
                                                         error:&error];
    if (jsonData == nil) {
        TMLError(@"Error transorming %@ to JSONString: ", NSStringFromClass([self class]), error);
    }
    return [jsonData tmlJSONString];
}
@end

@implementation NSNull (TMLJSON)
- (NSString *)tmlJSONString {
    return @"null";
}
@end

@implementation NSString (TMLJSON)
- (NSString *)tmlJSONString {
    NSArray *array = @[self];
    NSString *arrayString = [array tmlJSONString];
    return [arrayString substringWithRange:NSMakeRange(1, arrayString.length-2)];
}

- (id)tmlJSONObject {
    NSError *error = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                             options:NSJSONReadingAllowFragments
                                               error:&error];
    if (obj == nil) {
        TMLError(@"Error transorming %@ to JSONObject: ", NSStringFromClass([self class]), error);
    }
    return obj;
}
@end

@implementation NSNumber (TMLJSON)
- (NSString *)tmlJSONString {
    NSString *stringValue = [self stringValue];
    return stringValue;
}
@end

@implementation NSArray (TMLJSON)
- (NSString *)tmlJSONString {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self
                                                   options:0
                                                     error:&error];
    if (data == nil) {
        TMLError(@"Error transorming %@ to JSONString: ", NSStringFromClass([self class]), error);
    }
    return [data tmlJSONString];
}
@end

@implementation NSDictionary (TMLJSON)
- (NSString *)tmlJSONString {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self
                                                   options:0
                                                     error:&error];
    if (data == nil) {
        TMLError(@"Error transorming %@ to JSONString: ", NSStringFromClass([self class]), error);
    }
    return [data tmlJSONString];
}
@end


@implementation NSData (TMLJSON)

- (NSString *)tmlJSONString {
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

- (id)tmlJSONObject {
    NSError *error = nil;
    id obj =  [NSJSONSerialization JSONObjectWithData:self
                                           options:NSJSONReadingAllowFragments
                                             error:&error];
    if (obj == nil) {
        TMLError(@"Error transorming %@ to JSONString: ", NSStringFromClass([self class]), error);
    }
    return obj;
}

@end
