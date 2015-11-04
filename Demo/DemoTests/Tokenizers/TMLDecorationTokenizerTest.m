//
//  TMLDecorationTokenizerTest.m
//  TML
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import  "TMLDecorationTokenizer.h"
#import <Foundation/Foundation.h>
#import "TMLTestBase.h"

@interface TMLDecorationTokenizerTest : TMLTestBase

@end

@implementation TMLDecorationTokenizerTest

- (void) testParsing {
    TMLDecorationTokenizer *tdt;
    NSArray *expectation;
    
    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"Hello World"];
    expectation = @[@"[tml]", @"Hello World", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @"Hello World"];
    XCTAssert([tdt.expression isEqual:expectation]);
    
    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold: Hello World]"];
    expectation = @[@"[tml]", @"[bold:", @" Hello World", @"]", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"bold", @"Hello World"]];
    XCTAssert([tdt.expression isEqual:expectation]);

    // broken
    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold: Hello World"];
    expectation = @[@"[tml]", @"[bold:", @" Hello World", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"bold", @"Hello World"]];
    XCTAssert([tdt.expression isEqual:expectation]);

    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold: Hello [strong: World]]"];
    expectation = @[@"[tml]", @"[bold:", @" Hello ", @"[strong:", @" World", @"]", @"]", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"bold", @"Hello ", @[@"strong", @"World"]]];
    XCTAssert([tdt.expression isEqual:expectation]);

    // broken
    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold: Hello [strong: World]"];
    expectation = @[@"[tml]", @"[bold:", @" Hello ", @"[strong:", @" World", @"]", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"bold", @"Hello ", @[@"strong", @"World"]]];
    XCTAssert([tdt.expression isEqual:expectation]);
    
    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold1: Hello [strong22: World]]"];
    expectation = @[@"[tml]", @"[bold1:", @" Hello ", @"[strong22:", @" World", @"]", @"]", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"bold1", @"Hello ", @[@"strong22", @"World"]]];
    XCTAssert([tdt.expression isEqual:expectation]);
    
    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold: Hello, [strong: how] [weak: are] you?]"];
    expectation = @[@"[tml]", @"[bold:", @" Hello, ", @"[strong:", @" how", @"]", @" ", @"[weak:", @" are", @"]", @" you?", @"]", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"bold", @"Hello, ", @[@"strong", @"how"], @" ", @[@"weak", @"are"], @" you?"]];
    XCTAssert([tdt.expression isEqual:expectation]);

    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold: Hello, [strong: how [weak: are] you?]"];
    expectation = @[@"[tml]", @"[bold:", @" Hello, ", @"[strong:", @" how ", @"[weak:", @" are", @"]", @" you?", @"]", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"bold", @"Hello, ", @[@"strong", @"how ", @[@"weak", @"are"], @" you?"]]];
    XCTAssert([tdt.expression isEqual:expectation]);

    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[link: you have [italic: [bold: {count}] messages] [light: in your mailbox]]"];
    expectation = @[@"[tml]", @"[link:", @" you have ", @"[italic:", @" ", @"[bold:", @" {count}", @"]", @" messages", @"]", @" ", @"[light:", @" in your mailbox", @"]", @"]", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"link", @"you have ", @[@"italic", @"", @[@"bold", @"{count}"], @" messages"], @" ", @[@"light", @"in your mailbox"]]];
    XCTAssert([tdt.expression isEqual:expectation]);

    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[link] you have [italic: [bold: {count}] messages] [light: in your mailbox] [/link]"];
    expectation = @[@"[tml]", @"[link]", @" you have ", @"[italic:", @" ", @"[bold:", @" {count}", @"]", @" messages", @"]", @" ", @"[light:", @" in your mailbox", @"]", @" ", @"[/link]", @"[/tml]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tml", @[@"link", @" you have ",@[@"italic", @"", @[@"bold", @"{count}"], @" messages"], @" ", @[@"light", @"in your mailbox"], @" "]];
//    TMLDebug(@"%@", result);
    XCTAssert([tdt.expression isEqual:expectation]);
}

- (void) testEvaluating {
    TMLDecorationTokenizer *tdt;
    NSObject *result;
    NSString *expectation;
    
    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"Hello World"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[] isEqual:tdt.tokenNames]);

    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold: Hello World]"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<strong>{$0}</strong>"}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"bold"] isEqual:tdt.tokenNames]);

    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": ^(NSString *value) {
        return [NSString stringWithFormat:@"<b>%@</b>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"bold"] isEqual:tdt.tokenNames]);

    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold: Hello [italic: World]]"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>",
                                                     @"italic": ^(NSString *value) {
        return [NSString stringWithFormat:@"<i>%@</i>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    NSArray *tokens = @[@"bold", @"italic"];
    XCTAssert([tokens isEqual:tdt.tokenNames]);

    tdt = [[TMLDecorationTokenizer alloc] initWithLabel: @"[bold]Hello [italic: World][/bold]"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>",
                                                     @"italic": ^(NSString *value) {
        return [NSString stringWithFormat:@"<i>%@</i>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    tokens = @[@"bold", @"italic"];
    XCTAssert([tokens isEqual:tdt.tokenNames]);
    
}

@end
