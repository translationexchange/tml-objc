//
//  TmlLanguageCaseTest.m
//  Tml
//
//  Created by Michael Berkovich on 1/23/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import "TmlLanguageCase.h"
#import <Foundation/Foundation.h>
#import "TmlTestBase.h"

@interface TmlLanguageCaseTest : TmlTestBase

@end

@implementation TmlLanguageCaseTest

- (void) testEvaluation {
    TmlLanguageCase *lcase = [[TmlLanguageCase alloc] initWithAttributes: [self loadJSON: @"cs_en-US_plural"]];

    XCTAssert([@"sheep" isEqual:[lcase apply:@"sheep"]]);
    XCTAssert([@"fish" isEqual:[lcase apply:@"fish"]]);
    XCTAssert([@"rice" isEqual:[lcase apply:@"rice"]]);
    XCTAssert([@"moves" isEqual:[lcase apply:@"move"]]);
    XCTAssert([@"sexes" isEqual:[lcase apply:@"sex"]]);
    XCTAssert([@"children" isEqual:[lcase apply:@"child"]]);
    XCTAssert([@"people" isEqual:[lcase apply:@"person"]]);
    XCTAssert([@"quizzes" isEqual:[lcase apply:@"quiz"]]);
    XCTAssert([@"oxen" isEqual:[lcase apply:@"ox"]]);
    XCTAssert([@"mice" isEqual:[lcase apply:@"mouse"]]);
    
    
//    lcase = [[TmlLanguageCase alloc] initWithAttributes: [self loadJSON: @"cs_ru_gen"]];
//    XCTAssert([@"Михаила" isEqual: [lcase apply:@"Михаил" forObject: @{@"gender": @"male"}]]);

}

@end
