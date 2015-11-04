//
//  TmlLanguageContextTest.m
//  Tml
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import "TmlLanguageContext.h"
#import "TmlTestUser.h"
#import "Tml.h"
#import "TmlLanguageContextRule.h"
#import <Foundation/Foundation.h>
#import "TMLTestBase.h"

@interface TMLLanguageContextTest : TMLTestBase

@end

@implementation TMLLanguageContextTest

- (void) testApplicableToTokenName {
    TmlLanguageContext *context = [[TmlLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_en-US_gender"]];
    XCTAssert([context isApplicableToTokenName:@"user"]);
    XCTAssert([context isApplicableToTokenName:@"user1"]);
    XCTAssert([context isApplicableToTokenName:@"translator"]);
    XCTAssert([context isApplicableToTokenName:@"actor"]);
    XCTAssert([context isApplicableToTokenName:@"current_user"]);
    XCTAssert(![context isApplicableToTokenName:@"someone"]);
}

- (void) testVariables {
    TmlLanguageContext *context = [[TmlLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_en-US_gender"]];
    TMLTestUser *user = [[TMLTestUser alloc] initWithFirstName:@"Michael" andLastName:@"Berkovich" andGender:@"male"];
    
    [Tml configure:^(TmlConfiguration *config) {
        [config setVariableMethod:@"@gender" forContext:@"gender" andVariableName:@"@gender"];
    }];
    
    NSDictionary *expectations = @{@"@gender": @"male"};
    XCTAssert([expectations isEqual:[context vars:user]]);

    expectations = @{@"@gender": @"female"};
    NSDictionary *obj = @{@"name": @"Anna", @"gender": @"female"};
    XCTAssert([expectations isEqual:[context vars: obj]]);

    [Tml configure:^(TmlConfiguration *config) {
        [config setVariableMethod:^(NSObject *obj) { return @"unknown"; } forContext:@"gender" andVariableName:@"@gender"];
    }];

    expectations = @{@"@gender": @"unknown"};
    XCTAssert([expectations isEqual:[context vars: user]]);
    
    [Tml configure:^(TmlConfiguration *config) {
        [config setVariableMethod:@"@@name" forContext:@"gender" andVariableName:@"@gender"];
    }];
    
    expectations = @{@"@gender": @"Michael Berkovich"};
    XCTAssert([expectations isEqual:[context vars: user]]);
}

- (void) testFindMatchingRule {
    TmlLanguageContext *context = [[TmlLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_en-US_gender"]];
    TMLTestUser *user = [[TMLTestUser alloc] initWithFirstName:@"Michael" andLastName:@"Berkovich" andGender:@"male"];
    
    [Tml configure:^(TmlConfiguration *config) {
        [config setVariableMethod:@"@gender" forContext:@"gender" andVariableName:@"@gender"];
    }];
    
    TmlLanguageContextRule *rule = (TmlLanguageContextRule *) [context findMatchingRule:user];
    XCTAssert([@"male" isEqual:rule.keyword]);
    
    
    context = [[TmlLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_ru_number"]];
    
    [Tml configure:^(TmlConfiguration *config) {
        [config setVariableMethod:@"@@self" forContext:@"number" andVariableName:@"@n"];
    }];
    
    rule = (TmlLanguageContextRule *) [context findMatchingRule:@1];
    XCTAssert([@"one" isEqual:rule.keyword]);

    rule = (TmlLanguageContextRule *) [context findMatchingRule:@"1"];
    XCTAssert([@"one" isEqual:rule.keyword]);
    
    rule = (TmlLanguageContextRule *) [context findMatchingRule:@2];
    XCTAssert([@"few" isEqual:rule.keyword]);

    rule = (TmlLanguageContextRule *) [context findMatchingRule:@5];
    XCTAssert([@"many" isEqual:rule.keyword]);

    rule = (TmlLanguageContextRule *) [context findMatchingRule:@"50"];
    XCTAssert([@"many" isEqual:rule.keyword]);
    
}

@end
