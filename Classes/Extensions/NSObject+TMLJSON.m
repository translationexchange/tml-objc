//
//  NSObject+JSON.m
//  Demo
//
//  Created by Pasha on 11/10/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

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