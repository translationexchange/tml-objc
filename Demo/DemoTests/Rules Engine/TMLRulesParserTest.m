/*
 *  Copyright (c) 2014 Michael Berkovich, http://tr8nhub.com All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

#import "TMLRulesParser.h"
#import <Foundation/Foundation.h>
#import "TMLTestBase.h"

@interface TMLRulesParserTest : TMLTestBase

@end

@implementation TMLRulesParserTest

- (void)testSplitting {
    TMLRulesParser *p = [TMLRulesParser parserWithExpression: @"(= 1 (mod n 10))"];
    NSArray *expected = @[@"(", @"=", @"1", @"(", @"mod", @"n", @"10", @")", @")"];
    XCTAssert([expected isEqual:p.tokens], @"Tokens are split correctly");
    
    p = [TMLRulesParser parserWithExpression: @"(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))"];
    expected = @[@"(", @"&&", @"(", @"=", @"1", @"(", @"mod", @"@n", @"10", @")", @")", @"(", @"!=", @"11", @"(", @"mod", @"@n", @"100", @")", @")", @")"];
    XCTAssert([expected isEqual:p.tokens], @"Tokens are split correctly");
}


- (void)testParsing {
  NSDictionary *tests = @{
    @"(= 1 1)":
            @[@"=", @"1", @"1"],
    @"(+ 1 1)":
            @[@"+", @"1", @"1"],
    @"(= 1 (mod n 10))":
            @[@"=", @"1", @[@"mod", @"n", @"10"]],
    @"(&& 1 1)":
            @[@"&&", @"1", @"1"],
    @"(mod @n 10)":
            @[@"mod", @"@n", @"10"],
    @"(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))":
            @[@"&&", @[@"=", @"1", @[@"mod", @"@n", @"10"]], @[@"!=", @"11", @[@"mod", @"@n", @"100"]]],
    
    @"(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))":
            @[@"&&", @[@"in", @"2..4", @[@"mod", @"@n", @"10"]], @[@"not", @[@"in", @"12..14", @[@"mod", @"@n", @"100"]]]],
    @"(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))":
        @[@"||", @[@"=", @"0", @[@"mod", @"@n", @"10"]], @[@"in", @"5..9", @[@"mod", @"@n", @"10"]], @[@"in", @"11..14", @[@"mod", @"@n", @"100"]]]
    };
    
    for (NSString *key in [tests allKeys]) {
        NSArray *expected = [tests objectForKey:key];
        TMLRulesParser *p = [TMLRulesParser parserWithExpression: key];
        XCTAssert([expected isEqual:[p parse]], @"Tokens are parsed correctly");
    }
    
}

@end
