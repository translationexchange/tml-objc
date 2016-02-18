//
//  TMLJSONValueTransformer.m
//  Demo
//
//  Created by Pasha on 11/10/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TMLJSONValueTransformer.h"
#import "NSObject+TMLJSON.h"

NSString * const TMLJSONValueTransformerName = @"TMLJSONValueTransformer";

@implementation TMLJSONValueTransformer

+ (void)initialize {
    if (self == [TMLJSONValueTransformer class]) {
        [NSValueTransformer setValueTransformer:[[self alloc] init] forName:TMLJSONValueTransformerName];
    }
}

+ (Class)transformedValueClass {
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if (value == nil) {
        return nil;
    }
    return [[value tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
}

- (id)reverseTransformedValue:(id)value {
    NSString *string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    return [string tmlJSONObject];
}

@end
