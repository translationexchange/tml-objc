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
#import "TMLAPISerializer.h"
#import "TMLModel.h"

@interface TMLAPISerializer()

@property (readwrite, nonatomic) NSMutableDictionary *info;

@end


@implementation TMLAPISerializer

+ (NSData *)serializeObject:(id)object {
    NSError *error = nil;
    NSData *result = nil;
    if (object == nil || [[NSNull null] isEqual:object] == YES) {
        return [[[NSNull null] tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if ([object isKindOfClass:[NSNumber class]] == YES) {
        return [[(NSNumber *)object tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if ([object isKindOfClass:[NSString class]] == YES) {
        return [[(NSString *)object tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if ([object isKindOfClass:[NSArray class]] == YES) {
        NSMutableArray *array = [NSMutableArray array];
        for (id item in (NSArray *)object) {
            [array addObject:[[TMLAPISerializer serializeObject:item] tmlJSONObject]];
        }
        result = [NSJSONSerialization dataWithJSONObject:array
                                                 options:0
                                                   error:&error];
        if (error != nil) {
            TMLError(@"TMLAPISerializer error: %@", error);
        }
        return result;
    }
    else if ([object isKindOfClass:[NSDictionary class]] == YES) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (id key in (NSDictionary *)object) {
            NSString *keyString = ([key isKindOfClass:[NSString class]] == YES) ? (NSString *)key : [NSString stringWithFormat:@"%@", key];
            dict[keyString] = [[TMLAPISerializer serializeObject:object[key]] tmlJSONObject];
        }
        result = [NSJSONSerialization dataWithJSONObject:dict
                                                 options:0
                                                   error:&error];
        if (error != nil) {
            TMLError(@"TMLAPISerializer error: %@", error);
        }
        return result;
    }
    TMLAPISerializer *serializer = [[TMLAPISerializer alloc] init];
    [object encodeWithCoder:serializer];
    result = [NSJSONSerialization dataWithJSONObject:serializer.info options:0 error:&error];
    if (error != nil) {
        TMLError(@"TMLAPISerializer error: %@", error);
    }
    return result;
}

+ (id)materializeData:(NSData *)data 
            withClass:(Class)aClass
{
    NSError *error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingAllowFragments
                                                  error:&error];
    if (error != nil) {
        TMLError(@"Error materializing data: %@", error);
    };
    
    if (result == nil) {
        return result;
    }
    
    result = [self materializeObject:result 
                           withClass:aClass ];
    return result;
}

+ (id)materializeObject:(id)object
              withClass:(Class)aClass
{
    id result = nil;
    if ([object isKindOfClass:aClass] == YES) {
        return object;
    }
    if (object == nil || [[NSNull null] isEqual:object] == YES) {
        return [NSNull null];
    }
    if ([object isKindOfClass:[NSNumber class]] == YES
        || [object isKindOfClass:[NSString class]] == YES) {
        return object;
    }
    TMLAPISerializer *serializer = [[TMLAPISerializer alloc] init];
    if ([object isKindOfClass:[NSArray class]] == YES) {
        NSMutableArray *array = [NSMutableArray array];
        for (id item in (NSArray *)object) {
            id decodedItem = [TMLAPISerializer materializeObject:item
                                                       withClass:aClass];
            if (decodedItem != nil) {
                [array addObject:decodedItem];
            }
        }
        result = [array copy];
    }
    else if ([object isKindOfClass:[NSDictionary class]] == YES) {
        serializer.info = object;
        if (aClass != nil) {
            result = [(id<NSCoding>)[aClass alloc] initWithCoder:serializer];
        }
        else {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (NSString *key in (NSDictionary *)object) {
                Class decodeClass = nil;
                id item = [(NSDictionary *)object valueForKey:key];
                id decodedItem = [TMLAPISerializer materializeObject:item
                                                           withClass:decodeClass];
                if (decodedItem != nil) {
                    dict[key] = decodedItem;
                }
            }
            result = dict;
        }
    }
    return result;
}

- (instancetype)init {
    if (self = [super init]) {
        _info = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initForReadingWithData:(NSData *)data {
    if (self = [self init]) {
        NSError *error;
        _info = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error != nil) {
            NSException *exception = [[NSException alloc] initWithName:@"TMLAPISerializer"
                                                                reason:@"Error instantiating as coder for reading with data"
                                                              userInfo:@{
                                                                         @"error": error
                                                                         }];
            [exception raise];
        }
    }
    return self;
}

- (BOOL)allowsKeyedCoding {
    return YES;
}

#pragma mark - Encoding

- (void)encodeObject:(id)objv forKey:(NSString *)key {
    id val = nil;
    if (objv == nil) {
        return;
    }
    
    if ([objv isKindOfClass:[NSString class]] == YES
        || [objv isKindOfClass:[NSNumber class]] == YES) {
        val = objv;
    }
    else if ([objv isKindOfClass:[NSArray class]] == YES) {
        val = [[TMLAPISerializer serializeObject:objv] tmlJSONObject];
    }
    if ([objv isKindOfClass:[NSDictionary class]] == YES) {
        val = [[TMLAPISerializer serializeObject:objv] tmlJSONObject];
    }
    else if ([objv isKindOfClass:[TMLModel class]] == YES) {
        val = [[TMLAPISerializer serializeObject:objv] tmlJSONObject];
    }
    if (val != nil) {
        _info[key] = val;
    }
}

- (void)encodeInteger:(NSInteger)intv forKey:(NSString *)key {
    _info[key] = [NSNumber numberWithInteger:intv];
}

- (void)encodeInt64:(int64_t)intv forKey:(NSString *)key {
    _info[key] = [NSNumber numberWithInteger:(NSInteger)intv];
}

- (void)encodeInt32:(int32_t)intv forKey:(NSString *)key {
    _info[key] = [NSNumber numberWithInteger:intv];
}

- (void)encodeInt:(int)intv forKey:(NSString *)key {
    _info[key] = [NSNumber numberWithInteger:intv];
}

- (void)encodeBool:(BOOL)boolv forKey:(NSString *)key {
    _info[key] = @(boolv);
}

#pragma mark - Decoding

- (id)decodeObjectForKey:(NSString *)key {
    return _info[key];
}

- (NSInteger)decodeIntegerForKey:(NSString *)key {
    return [_info[key] integerValue];
}

-(int64_t)decodeInt64ForKey:(NSString *)key {
    return (int64_t)[_info[key] integerValue];
}

- (int32_t)decodeInt32ForKey:(NSString *)key {
    return (int32_t)[_info[key] integerValue];
}

- (int)decodeIntForKey:(NSString *)key {
    return (int)[_info[key] integerValue];
}

- (BOOL)decodeBoolForKey:(NSString *)key {
    return [_info[key] boolValue];
}

@end
