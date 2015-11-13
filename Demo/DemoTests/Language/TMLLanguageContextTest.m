//
//  TMLLanguageContextTest.m
//  TML
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import "TML.h"
#import "TMLConfiguration.h"
#import "TMLLanguageContext.h"
#import "TMLLanguageContextRule.h"
#import "TMLTestBase.h"
#import "TMLTestUser.h"
#import <Foundation/Foundation.h>

@interface TMLLanguageContextTest : TMLTestBase

@end

@implementation TMLLanguageContextTest

- (void) testApplicableToTokenName {
    TMLLanguageContext *context = [[TMLLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_en-US_gender"]];
    XCTAssert([context isApplicableToTokenName:@"user"]);
    XCTAssert([context isApplicableToTokenName:@"user1"]);
    XCTAssert([context isApplicableToTokenName:@"translator"]);
    XCTAssert([context isApplicableToTokenName:@"actor"]);
    XCTAssert([context isApplicableToTokenName:@"current_user"]);
    XCTAssert(![context isApplicableToTokenName:@"someone"]);
}

- (void) testVariables {
    TMLLanguageContext *context = [[TMLLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_en-US_gender"]];
    TMLTestUser *user = [[TMLTestUser alloc] initWithFirstName:@"Michael" andLastName:@"Berkovich" andGender:@"male"];
    
    [TML configure:^(TMLConfiguration *config) {
        [config setVariableMethod:@"@gender" forContext:@"gender" andVariableName:@"@gender"];
    }];
    
    NSDictionary *expectations = @{@"@gender": @"male"};
    XCTAssert([expectations isEqual:[context vars:user]]);

    expectations = @{@"@gender": @"female"};
    NSDictionary *obj = @{@"name": @"Anna", @"gender": @"female"};
    XCTAssert([expectations isEqual:[context vars: obj]]);

    [TML configure:^(TMLConfiguration *config) {
        [config setVariableMethod:^(NSObject *obj) { return @"unknown"; } forContext:@"gender" andVariableName:@"@gender"];
    }];

    expectations = @{@"@gender": @"unknown"};
    XCTAssert([expectations isEqual:[context vars: user]]);
    
    [TML configure:^(TMLConfiguration *config) {
        [config setVariableMethod:@"@@name" forContext:@"gender" andVariableName:@"@gender"];
    }];
    
    expectations = @{@"@gender": @"Michael Berkovich"};
    XCTAssert([expectations isEqual:[context vars: user]]);
}

- (void) testFindMatchingRule {
    TMLLanguageContext *context = [[TMLLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_en-US_gender"]];
    TMLTestUser *user = [[TMLTestUser alloc] initWithFirstName:@"Michael" andLastName:@"Berkovich" andGender:@"male"];
    
    [TML configure:^(TMLConfiguration *config) {
        [config setVariableMethod:@"@gender" forContext:@"gender" andVariableName:@"@gender"];
    }];
    
    TMLLanguageContextRule *rule = (TMLLanguageContextRule *) [context findMatchingRule:user];
    XCTAssert([@"male" isEqual:rule.keyword]);
    
    
    context = [[TMLLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_ru_number"]];
    
    [TML configure:^(TMLConfiguration *config) {
        [config setVariableMethod:@"@@self" forContext:@"number" andVariableName:@"@n"];
    }];
    
    rule = (TMLLanguageContextRule *) [context findMatchingRule:@1];
    XCTAssert([@"one" isEqual:rule.keyword]);

    rule = (TMLLanguageContextRule *) [context findMatchingRule:@"1"];
    XCTAssert([@"one" isEqual:rule.keyword]);
    
    rule = (TMLLanguageContextRule *) [context findMatchingRule:@2];
    XCTAssert([@"few" isEqual:rule.keyword]);

    rule = (TMLLanguageContextRule *) [context findMatchingRule:@5];
    XCTAssert([@"many" isEqual:rule.keyword]);

    rule = (TMLLanguageContextRule *) [context findMatchingRule:@"50"];
    XCTAssert([@"many" isEqual:rule.keyword]);
    
}

@end
