//
//  TMLHtmlDecorationTokenizerTest.m
//  TML
//
//  Created by Michael Berkovich on 1/31/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import "TMLHtmlDecorationTokenizer.h"
#import "TMLTestBase.h"

@interface TMLHtmlDecorationTokenizerTest : TMLTestBase

@end

@implementation TMLHtmlDecorationTokenizerTest


- (void) testEvaluating {
    TMLHtmlDecorationTokenizer *tdt;
    NSObject *result;
    NSString *expectation;
    
    tdt = [[TMLHtmlDecorationTokenizer alloc] initWithLabel: @"Hello World"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[] isEqual:tdt.tokenNames]);
    
    tdt = [[TMLHtmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello World]"];
    expectation = @"<strong>Hello World</strong>";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<strong>{$0}</strong>"}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"bold"] isEqual:tdt.tokenNames]);

    tdt = [[TMLHtmlDecorationTokenizer alloc] initWithLabel: @"[capital: H]ello World"];
    expectation = @"<strong>H</strong>ello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"capital": @"<strong>{$0}</strong>"}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"capital"] isEqual:tdt.tokenNames]);

    tdt = [[TMLHtmlDecorationTokenizer alloc] initWithLabel: @"H[underscore:ell]o World"];
    expectation = @"H<u>ell</u>o World";
    result = [tdt substituteTokensInLabelUsingData:@{@"underscore": @"<u>{$0}</u>"}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"underscore"] isEqual:tdt.tokenNames]);

    
    tdt = [[TMLHtmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello World]"];
    expectation = @"<b>Hello World</b>";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": ^(NSString *value) {
        return [NSString stringWithFormat:@"<b>%@</b>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"bold"] isEqual:tdt.tokenNames]);
    
    tdt = [[TMLHtmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello [italic: World]]"];
    expectation = @"<b>Hello <i>World</i></b>";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>",
                                                     @"italic": ^(NSString *value) {
        return [NSString stringWithFormat:@"<i>%@</i>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    NSArray *tokens = @[@"bold", @"italic"];
    XCTAssert([tokens isEqual:tdt.tokenNames]);
    
    tdt = [[TMLHtmlDecorationTokenizer alloc] initWithLabel: @"[bold]Hello [italic: World][/bold]"];
    expectation = @"<b>Hello <i>World</i></b>";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>",
                                                     @"italic": ^(NSString *value) {
        return [NSString stringWithFormat:@"<i>%@</i>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    tokens = @[@"bold", @"italic"];
    XCTAssert([tokens isEqual:tdt.tokenNames]);
    
}

@end
