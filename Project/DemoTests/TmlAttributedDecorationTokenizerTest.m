//
//  TmlAttributedDecorationTokenizer.m
//  Tml
//
//  Created by Michael Berkovich on 1/31/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import "TmlAttributedDecorationTokenizer.h"
#import <Foundation/Foundation.h>
#import "TmlTestBase.h"

@interface TmlAttributedDecorationTokenizerTest : TmlTestBase

@end

@implementation TmlAttributedDecorationTokenizerTest

- (void) testEvaluating {
    TmlAttributedDecorationTokenizer *tdt;
    NSObject *result;
    NSMutableAttributedString *expectation;
    NSDictionary *attributes;
//    NSArray *tokens;
    
    tdt = [[TmlAttributedDecorationTokenizer alloc] initWithLabel: @"Hello World"];
    expectation = [[NSMutableAttributedString alloc] initWithString: @"Hello World" attributes:@{}];
    result = [tdt substituteTokensInLabelUsingData:@{}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[] isEqual:tdt.tokenNames]);
//    TmlDebug(@"%@", tdt.attributes);
    attributes = @{@"tr8n": @[@{@"length":@11, @"location": @0}]};
    XCTAssert([attributes isEqual:tdt.attributes]);

    tdt = [[TmlAttributedDecorationTokenizer alloc] initWithLabel: @"Hello [bold: World]"];
    expectation = [[NSMutableAttributedString alloc] initWithString: @"Hello World"];
    [expectation addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Arial" size:10] range:NSMakeRange(6, 5)];
    
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @{@"font": [UIFont fontWithName:@"Arial" size:10]}}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"bold"] isEqual:tdt.tokenNames]);
//    TmlDebug(@"%@", tdt.attributes);
    attributes = @{@"tr8n": @[@{@"length":@11, @"location": @0}], @"bold": @[@{@"length":@5, @"location": @6}]};
    XCTAssert([attributes isEqual:tdt.attributes]);

//    tdt = [[TmlAttributedDecorationTokenizer alloc] initWithLabel: @"[bold: Hello [italic: World]]"];
//    expectation = @"Hello World";
//    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>", @"italic": @"<b>{$0}</b>"}];
//    XCTAssert([result isEqual:expectation]);
//    tokens = @[@"bold", @"italic"];
//    XCTAssert([tokens isEqual:tdt.tokenNames]);
////    TmlDebug(@"%@", tdt.attributes);
//    attributes = @{@"tr8n": @[@{@"length":@11, @"location": @0}], @"bold": @[@{@"length":@11, @"location": @0}], @"italic": @[@{@"length":@5, @"location": @6}]};
//    XCTAssert([attributes isEqual:tdt.attributes]);
//
//    tdt = [[TmlAttributedDecorationTokenizer alloc] initWithLabel: @"You have [bold: 10 [italic: messages]]"];
//    expectation = @"You have 10 messages";
//    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>", @"italic": @"<b>{$0}</b>"}];
//    XCTAssert([result isEqual:expectation]);
//    tokens = @[@"bold", @"italic"];
//    XCTAssert([tokens isEqual:tdt.tokenNames]);
////    TmlDebug(@"%@", tdt.attributes);
//    attributes = @{@"tr8n": @[@{@"length":@20, @"location": @0}], @"bold": @[@{@"length":@11, @"location": @9}], @"italic": @[@{@"length":@8, @"location": @12}]};
//    XCTAssert([attributes isEqual:tdt.attributes]);
//
//    tdt = [[TmlAttributedDecorationTokenizer alloc] initWithLabel: @"[bold: You] have [bold: 10] [italic: messages]"];
//    expectation = @"You have 10 messages";
//    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>", @"italic": @"<b>{$0}</b>"}];
//    XCTAssert([result isEqual:expectation]);
//    tokens = @[@"bold", @"italic"];
//    XCTAssert([tokens isEqual:tdt.tokenNames]);
//    TmlDebug(@"%@", tdt.attributes);
//    attributes = @{@"tr8n": @[@{@"length":@20, @"location": @0}], @"bold": @[@{@"length":@3, @"location": @0}, @{@"length":@2, @"location": @9}], @"italic": @[@{@"length":@8, @"location": @12}]};
//    XCTAssert([attributes isEqual:tdt.attributes]);
}

@end
