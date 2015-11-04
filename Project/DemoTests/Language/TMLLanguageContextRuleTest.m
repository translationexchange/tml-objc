//
//  TmlLanguageContextRuleTest.m
//  Tml
//
//  Created by Michael Berkovich on 1/23/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import "TmlLanguageContextRule.h"
#import <Foundation/Foundation.h>
#import "TMLTestBase.h"

@interface TMLLanguageContextRuleTest : TMLTestBase

@end

@implementation TMLLanguageContextRuleTest

- (void) testEvaluation {
    TmlLanguageContextRule *rule = [[TmlLanguageContextRule alloc] initWithAttributes:@{
      @"keyword":@"many",
      @"description":@"{token} mod 10 is 0 or {token} mod 10 in 5..9 or {token} mod 100 in 11..14",
      @"examples":@"0, 5-20, 25-30, 35-40...",
      @"conditions":@"(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))"
     }];
    
    XCTAssert([[rule evaluate:@{@"@n": @5}] isEqual:@YES]);
    XCTAssert([[rule evaluate:@{@"@n": @9}] isEqual:@YES]);
    XCTAssert([[rule evaluate:@{@"@n": @11}] isEqual:@YES]);
    XCTAssert([[rule evaluate:@{@"@n": @12}] isEqual:@YES]);
    XCTAssert([[rule evaluate:@{@"@n": @14}] isEqual:@YES]);
    XCTAssert([[rule evaluate:@{@"@n": @50}] isEqual:@YES]);

    XCTAssert([[rule evaluate:@{@"@n": @1}] isEqual:@NO]);
    XCTAssert([[rule evaluate:@{@"@n": @2}] isEqual:@NO]);
    XCTAssert([[rule evaluate:@{@"@n": @4}] isEqual:@NO]);
    XCTAssert([[rule evaluate:@{@"@n": @51}] isEqual:@NO]);
    
    rule = [[TmlLanguageContextRule alloc] initWithAttributes:@{
      @"keyword": @"female",
      @"description": @"{token} is a female",
      @"conditions": @"(= 'female' @gender)"
    }];

    XCTAssert([[rule evaluate:@{@"@gender": @"female"}] isEqual:@YES]);
    XCTAssert([[rule evaluate:@{@"@gender": @"male"}] isEqual:@NO]);
    XCTAssert([[rule evaluate:@{@"@gender": @"unknown"}] isEqual:@NO]);
    
    rule = [[TmlLanguageContextRule alloc] initWithAttributes:@{
      @"keyword": @"female",
      @"description": @"{token} contains 1 female",
      @"conditions": @"(&& (= 1 (count @genders)) (all @genders 'female'))",
    }];
    
    NSArray *genders = @[@"female"];
    XCTAssert([[rule evaluate:@{@"@genders": genders}] isEqual:@YES]);
    genders = @[@"female", @"female"];
    XCTAssert([[rule evaluate:@{@"@genders": genders}] isEqual:@NO]);

    rule = [[TmlLanguageContextRule alloc] initWithAttributes:@{
      @"keyword": @"female",
      @"description": @"{token} contains at least 2 females",
      @"conditions": @"(&& (> (count @genders) 1) (all @genders 'female'))",
    }];
    
    genders = @[@"female"];
    XCTAssert([[rule evaluate:@{@"@genders": genders}] isEqual:@NO]);
    genders = @[@"female", @"female"];
    XCTAssert([[rule evaluate:@{@"@genders": genders}] isEqual:@YES]);
}

- (void) testFallback {
    TmlLanguageContextRule *rule = [[TmlLanguageContextRule alloc] initWithAttributes:@{@"keyword":@"other"}];
    XCTAssert([rule isFallback]);
}

@end
