//
//  NSObjectTMLTest.m
//  TMLKit
//
//  Created by Pasha on 12/14/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+TML.h"

@interface NSObjectTMLTest : XCTestCase
@property (strong, nonatomic) NSArray *objects;
@property (strong, nonatomic) NSArray *objectsCopy;
@end

@implementation NSObjectTMLTest

- (void)setUp {
    [super setUp];
    self.objects = @[
                     @"First Top Element",
                     @[
                         @"First Secondary Element",
                         @"Second Secondary Element",
                         @[
                             @"First Tertiary Element",
                             @"Second Tertiary Element"
                             ]],
                     @"Third Top Element"
                     ];
}

- (void)tearDown {
    self.objects = nil;
    [super tearDown];
}

- (void)testGettingIndexedPath {
    NSArray *objects = self.objects;
    NSString *result = [self valueForKeyPath:@"objects[0]"];
    XCTAssertEqual(result, [objects objectAtIndex:0]);
    
    result = [self valueForKeyPath:@"objects[1]"];
    XCTAssertEqual(result, [objects objectAtIndex:1]);
    
    result = [self valueForKeyPath:@"objects[1][0]"];
    XCTAssertEqual(result, [[objects objectAtIndex:1] objectAtIndex:0]);
    
    result = [self valueForKeyPath:@"objects[1][2][1]"];
    XCTAssertEqual(result, [[[objects objectAtIndex:1] objectAtIndex:2] objectAtIndex:1]);
}

- (void)testSettingIndexedPath {
    NSArray *keyPaths = @[@"objects[1][2][1]", @"objects[1][0]", @"objects[0]"];
    for (NSString *keyPath in keyPaths) {
        id value = [self valueForKeyPath:keyPath];
        NSString *newKeyPath = [keyPath stringByReplacingOccurrencesOfString:@"objects" withString:@"objectsCopy"];
        [self setValue:value forKeyPath:newKeyPath];
        XCTAssertEqual(value, [self valueForKeyPath:newKeyPath]);
    }
}

@end
