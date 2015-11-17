//
//  TMLLanguageCaseTest.m
//  TML
//
//  Created by Michael Berkovich on 1/23/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import "TMLLanguageCase.h"
#import <Foundation/Foundation.h>
#import "TMLTestBase.h"
#import "TMLAPISerializer.h"

@interface TMLLanguageCaseTest : TMLTestBase

@end

@implementation TMLLanguageCaseTest

- (void) testEvaluation {
    NSData *jsonData = [self loadJSONDataFromResource:@"cs_en-US_plural"];
    TMLLanguageCase *lcase = [TMLAPISerializer materializeData:jsonData withClass:[TMLLanguageCase class] delegate:nil];

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
    
    
//    lcase = [[TMLLanguageCase alloc] initWithAttributes: [self loadJSON: @"cs_ru_gen"]];
//    XCTAssert([@"Михаила" isEqual: [lcase apply:@"Михаил" forObject: @{@"gender": @"male"}]]);

}

@end
