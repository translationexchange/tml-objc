//
//  TMLAPISerializationTest.m
//  Demo
//
//  Created by Pasha on 11/12/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TMLAPISerializer.h"
#import "TMLLanguage.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"
#import <XCTest/XCTest.h>

@interface TMLAPISerializationTest : XCTestCase {
    NSArray *_in;
    NSArray *_out;
}

@end

@implementation TMLAPISerializationTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFoundationSerialization {
    BOOL aTooth = YES;
    NSString *result = nil;
    result = [[TMLAPISerializer serializeObject:@(aTooth)] tmlJSONString];
    XCTAssert([result isEqualToString:@"1"]);
    
    BOOL aLie = NO;
    result = [[TMLAPISerializer serializeObject:@(aLie)] tmlJSONString];
    XCTAssert([result isEqualToString:@"0"]);
    
    result = [[TMLAPISerializer serializeObject:nil] tmlJSONString];
    XCTAssert([result isEqualToString:@"null"]);
    
    result = [[TMLAPISerializer serializeObject:[NSNull null]] tmlJSONString];
    XCTAssert([result isEqualToString:@"null"]);
    
    NSNumber *number = @3;
    result = [[TMLAPISerializer serializeObject:number] tmlJSONString];
    XCTAssertEqualObjects(result, @"3");
    
    number = @(3.4);
    result = [[TMLAPISerializer serializeObject:number] tmlJSONString];
    XCTAssertEqualObjects(result, @"3.4");
    
    NSString *aString = @"A String";
    result = [[TMLAPISerializer serializeObject:aString] tmlJSONString];
    XCTAssertEqualObjects(result, [aString tmlJSONString]);
    
    NSArray *array = @[number, aString, @[number, aString, @"Inner Array"], @{@"Foo": @"foo"}];
    result = [[TMLAPISerializer serializeObject:array] tmlJSONString];
    XCTAssertEqualObjects(result, [array tmlJSONString]);
    
    array = @[@"Really nested array", array];
    result = [[TMLAPISerializer serializeObject:array] tmlJSONString];
    XCTAssertEqualObjects(result, [array tmlJSONString]);
    
    NSDictionary *dict = @{
                           @"number": number,
                           @"string": aString,
                           @"array": array,
                           @"dictionary": @{
                                   @"number": number,
                                   @"string": aString,
                                   @"array": array,
                                   @"dictionary": @{@"Foo": @"foo"},
                                   @"null": [NSNull null]
                                   },
                           @"null": [NSNull null]
                           };
    result = [[TMLAPISerializer serializeObject:dict] tmlJSONString];
    XCTAssertEqualObjects(result, [dict tmlJSONString]);
}

- (void)testTMLSerialization {
    TMLTranslationKey *key = [[TMLTranslationKey alloc] init];
    key.key = @"123876234876238476234";
    key.keyDescription = @"Test Key Description";
    key.level = 100;
    key.locale = @"en";
    key.translations = @[];
    key.label = @"Test Label";
    NSDictionary *dict = @{
                           @"key": key.key,
                           @"description": key.keyDescription,
                           @"level": @(key.level),
                           @"locale": key.locale
                           };
    NSString *result = [[TMLAPISerializer serializeObject:key] tmlJSONString];
    XCTAssertNotEqualObjects([result tmlJSONObject], dict);
    NSMutableDictionary *complete = [dict mutableCopy];
    complete[@"label"] = key.label;
    dict = [complete copy];
    XCTAssertEqualObjects([result tmlJSONObject], dict);
    
    TMLTranslationKey *anotherKey = [key copy];
    anotherKey.key = @"ksjdhf876sdf876sdf876";
    anotherKey.keyDescription = @"Another Test Description";
    NSMutableDictionary *anotherDict = [[dict copy] mutableCopy];
    anotherDict[@"key"] = anotherKey.key;
    anotherDict[@"description"] = anotherKey.keyDescription;
    
    NSArray *keys = @[key, anotherKey];
    NSArray *dicts = @[dict, anotherDict];
    result = [[TMLAPISerializer serializeObject:keys] tmlJSONString];
    XCTAssertEqualObjects([result tmlJSONObject], dicts);
    
    NSDictionary *keyDict = @{
                              @"Source 1": key,
                              @"Source 2": anotherKey
                              };
    NSDictionary *dictDict = @{
                               @"Source 1": dict,
                               @"Source 2": anotherDict
                               };
    result = [[TMLAPISerializer serializeObject:keyDict] tmlJSONString];
    XCTAssertEqualObjects([result tmlJSONObject], dictDict);
    
    TMLSource *source = [[TMLSource alloc] init];
    source.key = @"Test Source";
    source.translations = @{@"en": @[key, anotherKey]};
    NSDictionary *sourceDict = @{
                                 @"id": @0,
                                 @"key": source.key,
//                                 @"translations": @{
//                                         @"en": @[dict, anotherDict]
//                                         }
                                 };
    result = [[TMLAPISerializer serializeObject:source] tmlJSONString];
    XCTAssertEqualObjects([result tmlJSONObject], sourceDict);
}

- (void)testFoundationMaterialization {
    BOOL aTooth = YES;
    id result = nil;
    result = [TMLAPISerializer materializeObject:@(aTooth) withClass:nil];
    XCTAssert([result isEqual:@1]);
    
    BOOL aLie = NO;
    result = [TMLAPISerializer materializeObject:@(aLie) withClass:nil];
    XCTAssert([result isEqual:@0]);
    
    result = [TMLAPISerializer materializeObject:nil withClass:nil];
    XCTAssert([result isEqual:[NSNull null]]);
    
    result = [TMLAPISerializer materializeObject:[NSNull null] withClass:nil];
    XCTAssert([result isEqual:[NSNull null]]);
    
    NSNumber *number = @3;
    result = [TMLAPISerializer materializeObject:number withClass:nil];
    XCTAssertEqualObjects(result, number);
    
    number = @(3.4);
    result = [TMLAPISerializer materializeObject:number withClass:nil];
    XCTAssertEqualObjects(result, number);
    
    NSString *aString = @"A String";
    result = [TMLAPISerializer materializeObject:aString withClass:nil];
    XCTAssertEqualObjects(result, aString);
    
    NSArray *array = @[number, aString, @[number, aString, @"Inner Array"], @{@"Foo": @"foo"}];
    result = [TMLAPISerializer materializeObject:array withClass:nil];
    XCTAssertEqualObjects(result, array);
    
    array = @[@"Really nested array", array];
    result = [TMLAPISerializer materializeObject:array withClass:nil];
    XCTAssertEqualObjects(result, array);
    
    NSDictionary *dict = @{
                           @"number": number,
                           @"string": aString,
                           @"array": array,
                           @"dictionary": @{
                                   @"number": number,
                                   @"string": aString,
                                   @"array": array,
                                   @"dictionary": @{@"Foo": @"foo"},
                                   @"null": [NSNull null]
                                   },
                           @"null": [NSNull null]
                           };
    result = [TMLAPISerializer materializeObject:dict withClass:nil];
    XCTAssertEqualObjects(result, dict);
}

- (void)testTMLMaterialization {
    TMLTranslationKey *key = [[TMLTranslationKey alloc] init];
    key.key = @"123876234876238476234";
    key.keyDescription = @"Test Key Description";
    key.level = 100;
    key.locale = @"en";
    key.translations = @[];
    key.label = @"Test Label";
    NSDictionary *dict = @{
                           @"key": key.key,
                           @"description": key.keyDescription,
                           @"level": @(key.level),
                           @"locale": key.locale,
                           @"label": key.label,
                           @"translations": key.translations
                           };
    id result = [TMLAPISerializer materializeObject:dict withClass:[TMLTranslationKey class]];
    XCTAssertEqualObjects(result, key);
    
    TMLTranslationKey *anotherKey = [key copy];
    anotherKey.key = @"ksjdhf876sdf876sdf876";
    anotherKey.keyDescription = @"Another Test Description";
    NSMutableDictionary *anotherDict = [[dict copy] mutableCopy];
    anotherDict[@"key"] = anotherKey.key;
    anotherDict[@"description"] = anotherKey.keyDescription;
    
    NSArray *keys = @[key, anotherKey];
    NSArray *dicts = @[dict, anotherDict];
    result = [TMLAPISerializer materializeObject:dicts withClass:[TMLTranslationKey class]];
    XCTAssertEqualObjects(result, keys);
    
    TMLLanguage *lang = [[TMLLanguage alloc] init];
    lang.locale = @"en-ru";
    lang.englishName = @"Rushun";
    lang.nativeName = @"Russish";
    
    TMLTranslation *translation = [[TMLTranslation alloc] init];
    translation.language = lang;
    translation.label = @"A Label";
    translation.translationKey = key;
    
    NSDictionary *translationDict = @{
                               @"label": @"A Label",
                               @"locked": @0,
                               @"translation_key": dict
                               };
    result = [TMLAPISerializer materializeObject:translationDict withClass:[TMLTranslation class]];
    XCTAssertEqualObjects(result, translation);
    
    TMLSource *source = [[TMLSource alloc] init];
    source.key = @"Test Source";
    source.translations = @{@"en": @[key, anotherKey]};
    NSDictionary *sourceDict = @{
                                 @"key": source.key,
                                 @"translations": @{
                                         @"en": @[dict, anotherDict]
                                         }
                                 };
    result = [TMLAPISerializer materializeObject:sourceDict withClass:[TMLSource class]];
    XCTAssertEqualObjects(result, source);
}

@end
