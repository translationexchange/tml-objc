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

#import "TMLRulesEvaluator.h"
#import "TMLRulesParser.h"
#import "TMLTestBase.h"

@interface TMLRulesEvaluatorTest : TMLTestBase

@end

@implementation TMLRulesEvaluatorTest

- (void) testBasicFunctions {
    TMLRulesEvaluator *e = [[TMLRulesEvaluator alloc] init];
    
    NSObject *(^fn)(TMLRulesEvaluator *, NSArray *);
    NSArray *arr;
    NSArray *expectation;
    NSObject *result;
    
    fn = [e.context objectForKey:@"label"];
    result = fn(e, [NSArray arrayWithObjects:@"greeting", @"Hello World", nil]);
    XCTAssert([result isEqual:@"Hello World"]);
    XCTAssert([[e variableForKey:@"greeting"] isEqual:@"Hello World"]);

    fn = [e.context objectForKey:@"quote"];
    arr = [NSArray arrayWithObjects:@1, @2, @3, nil];
    result = fn(e, [NSArray arrayWithObject: arr]);
    XCTAssert([result isEqual:arr]);

    arr = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    result = fn(e, [NSArray arrayWithObject: arr]);
    XCTAssert([result isEqual:arr]);

    fn = [e.context objectForKey:@"car"];
    arr = [NSArray arrayWithObjects:@"+", @1, @2, nil];
    result = fn(e, [NSArray arrayWithObject: arr]);
    XCTAssert([result isEqual:@1]);

    fn = [e.context objectForKey:@"cdr"];
    arr = [NSArray arrayWithObjects:@"+", @1, @2, nil];
    result = fn(e, [NSArray arrayWithObject: arr]);
    expectation = [NSArray arrayWithObjects:@1, @2, nil];
    XCTAssert([result isEqual:expectation]);

    fn = [e.context objectForKey:@"cons"];
    arr = [NSArray arrayWithObjects:@2, @3, nil];
    result = fn(e, [NSArray arrayWithObjects: @1, arr, nil]);
    expectation = [NSArray arrayWithObjects:@1, @2, @3, nil];
    XCTAssert([result isEqual:expectation]);

    fn = [e.context objectForKey:@"eq"];
    result = fn(e, [NSArray arrayWithObjects: @1, @1, nil]);
    XCTAssert([result isEqual:@YES]);

    result = fn(e, [NSArray arrayWithObjects: @1, @2, nil]);
    XCTAssert([result isEqual:@NO]);

    fn = [e.context objectForKey:@"+"];
    result = fn(e, [NSArray arrayWithObjects: @23, @10, nil]);
    XCTAssert([result isEqual:@33]);
    
    fn = [e.context objectForKey:@"%"];
    result = fn(e, [NSArray arrayWithObjects: @23, @10, nil]);
    XCTAssert([result isEqual:@3]);

    fn = [e.context objectForKey:@"mod"];
    result = fn(e, [NSArray arrayWithObjects: @23, @10, nil]);
    XCTAssert([result isEqual:@3]);

    fn = [e.context objectForKey:@"prepend"];
    result = fn(e, [NSArray arrayWithObjects: @"Hello ", @"World", nil]);
    XCTAssert([result isEqual:@"Hello World"]);
    
    fn = [e.context objectForKey:@"append"];
    result = fn(e, [NSArray arrayWithObjects: @"Hello ", @"World", nil]);
    XCTAssert([result isEqual:@"WorldHello "]);
    
}

- (void) testRegularExpressions {
    TMLRulesEvaluator *e = [[TMLRulesEvaluator alloc] init];
    
    NSObject *(^fn)(TMLRulesEvaluator *, NSArray *);
    NSObject *result;

    fn = [e.context objectForKey:@"match"];
    result = fn(e, [NSArray arrayWithObjects: @"hello", @"hello world", nil]);
    XCTAssert([result isEqual:@YES]);

    result = fn(e, [NSArray arrayWithObjects: @"/hello/", @"hello world", nil]);
    XCTAssert([result isEqual:@YES]);
    
    result = fn(e, [NSArray arrayWithObjects: @"hi", @"hello world", nil]);
    XCTAssert([result isEqual:@NO]);

    result = fn(e, [NSArray arrayWithObjects: @"/rld$/", @"hello world", nil]);
    XCTAssert([result isEqual:@YES]);

    result = fn(e, [NSArray arrayWithObjects: @"/^h.*d$/", @"hello world", nil]);
    XCTAssert([result isEqual:@YES]);

    fn = [e.context objectForKey:@"replace"];
    result = fn(e, [NSArray arrayWithObjects: @"/^hello/", @"hi", @"hello world", nil]);
    XCTAssert([result isEqual:@"hi world"]);

    result = fn(e, [NSArray arrayWithObjects: @"o", @"a", @"hello world", nil]);
    XCTAssert([result isEqual:@"hella warld"]);

    result = fn(e, [NSArray arrayWithObjects: @"/world$/", @"moon", @"hello world", nil]);
    XCTAssert([result isEqual:@"hello moon"]);
    
    result = fn(e, [NSArray arrayWithObjects: @"/(vert|ind)ices$/i", @"$1ex", @"vertices", nil]);
    XCTAssert([result isEqual:@"vertex"]);
}

- (void) testRanges {
    TMLRulesEvaluator *e = [[TMLRulesEvaluator alloc] init];
    
    NSObject *(^fn)(TMLRulesEvaluator *, NSArray *);
    NSObject *result;
    
    fn = [e.context objectForKey:@"in"];
    result = fn(e, [NSArray arrayWithObjects: @"1,2,3,4,5", @"5", nil]);
    XCTAssert([result isEqual:@YES]);

    fn = [e.context objectForKey:@"in"];
    result = fn(e, [NSArray arrayWithObjects: @"1..5", @"1", nil]);
    XCTAssert([result isEqual:@YES]);
    
    fn = [e.context objectForKey:@"in"];
    result = fn(e, [NSArray arrayWithObjects: @"1..5", @"5", nil]);
    XCTAssert([result isEqual:@YES]);

    fn = [e.context objectForKey:@"in"];
    result = fn(e, [NSArray arrayWithObjects: @"1,2,3..5,6,7", @"4", nil]);
    XCTAssert([result isEqual:@YES]);

    fn = [e.context objectForKey:@"in"];
    result = fn(e, [NSArray arrayWithObjects: @"1,2,3..5,7", @"6", nil]);
    XCTAssert([result isEqual:@NO]);

    fn = [e.context objectForKey:@"in"];
    result = fn(e, [NSArray arrayWithObjects: @"a,b,c", @"a", nil]);
    XCTAssert([result isEqual:@YES]);

//    fn = [e.context objectForKey:@"in"];
//    result = fn(e, [NSArray arrayWithObjects: @"a..c", @"f", nil]);
//    XCTAssert([result isEqual:@NO]);
    
}

- (void) testBooleanExpressions {
    TMLRulesEvaluator *e = [[TMLRulesEvaluator alloc] init];
    
    NSObject *result;
    
    result = [e evaluateExpression: @[@"=", @1, @1]];
    XCTAssert([result isEqual:@YES]);
    
    result = [e evaluateExpression: @[@"=", @"1", @"1"]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"=", @1, @"1"]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"=", @"1", @1]];
    XCTAssert([result isEqual:@YES]);
    
    result = [e evaluateExpression: @[@"=", @"abc", @"abc"]];
    XCTAssert([result isEqual:@YES]);
    
    result = [e evaluateExpression: @[@"!=", @2, @1]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"!=", @"2", @1]];
    XCTAssert([result isEqual:@YES]);
    
    result = [e evaluateExpression: @[@">", @2, @1]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@">", @2, @"1"]];
    XCTAssert([result isEqual:@YES]);
    
    result = [e evaluateExpression: @[@"<", @2, @1]];
    XCTAssert([result isEqual:@NO]);

    result = [e evaluateExpression: @[@"<", @"2", @1]];
    XCTAssert([result isEqual:@NO]);
}

- (void) testNumericExpressions {
    TMLRulesEvaluator *e = [[TMLRulesEvaluator alloc] init];
    
    NSObject *result;

    result = [e evaluateExpression: @[@"+", @2, @1]];
    XCTAssert([result isEqual:@3]);

    result = [e evaluateExpression: @[@"+", @-2, @1]];
    XCTAssert([result isEqual:@-1]);

    result = [e evaluateExpression: @[@"*", @2, @10]];
    XCTAssert([result isEqual:@20]);

    result = [e evaluateExpression: @[@"true"]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"false"]];
    XCTAssert([result isEqual:@NO]);

    result = [e evaluateExpression: @[@"!", @[@"=", @2, @1]]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"!", @[@"!=", @2, @1]]];
    XCTAssert([result isEqual:@NO]);

    result = [e evaluateExpression: @[@"&&", @[@"=", @1, @1], @[@"=", @10, @[@"/", @20, @2]]]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"&&", @[@"=", @1, @2], @[@"=", @10, @[@"/", @20, @2]]]];
    XCTAssert([result isEqual:@NO]);

    result = [e evaluateExpression: @[@"and", @[@"=", @1, @2], @[@"=", @10, @[@"/", @20, @2]]]];
    XCTAssert([result isEqual:@NO]);
    
    result = [e evaluateExpression: @[@"||", @[@"=", @1, @2], @[@"=", @10, @[@"/", @20, @2]]]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"or", @[@"=", @1, @2], @[@"=", @10, @[@"/", @20, @2]]]];
    XCTAssert([result isEqual:@YES]);
    
    result = [e evaluateExpression: @[@"if", @[@"=", @1, @2], @1, @2]];
    XCTAssert([result isEqual:@2]);

    result = [e evaluateExpression: @[@"match", @"hello", @"hello world"]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"match", @"/hello/", @"hello world"]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"match", @"/^h/", @"hello world"]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"match", @"/^e/", @"hello world"]];
    XCTAssert([result isEqual:@NO]);

    result = [e evaluateExpression: @[@"match", @"/^h.*d$/", @"hello world"]];
    XCTAssert([result isEqual:@YES]);
    
    [e evaluateExpression: @[@"let", @"@n", @1]];
    XCTAssert([[e variableForKey:@"@n"] isEqual:@1]);

    result = [e evaluateExpression: @[@"=", @"@n", @1]];
    XCTAssert([result isEqual:@YES]);

    [e evaluateExpression: @[@"let", @"@n", @11]];
    XCTAssert([[e variableForKey:@"@n"] isEqual:@11]);
    
    result = [e evaluateExpression: @[@"=", @"@n", @11]];
    XCTAssert([result isEqual:@YES]);

    result = [e evaluateExpression: @[@"and", @[@"=", @"@n", @11], @[@"=", @22, @[@"*", @"@n", @2]]]];
    XCTAssert([result isEqual:@YES]);
    
}

- (void) testListExpressions {
    TMLRulesEvaluator *e = [[TMLRulesEvaluator alloc] init];
    
    NSObject *result;
    
    [e evaluateExpression: @[@"let", @"@arr", @[@1, @2, @3]]];
    NSArray *arr = @[@1, @2, @3];
    XCTAssert([[e variableForKey:@"@arr"] isEqual: arr]);
    
    result = [e evaluateExpression: @[@"count", @"@arr"]];
    XCTAssert([result isEqual:@3]);
    
    [e evaluateExpression: @[@"let", @"@genders", @[@"male", @"female", @"unknown"]]];
    arr = @[@"male", @"female", @"unknown"];
    XCTAssert([[e variableForKey:@"@genders"] isEqual: arr]);
    
    result = [e evaluateExpression: @[@"all", @"@genders", @"male"]];
    XCTAssert([result isEqual:@NO]);
    
    result = [e evaluateExpression: @[@"any", @"@genders", @"male"]];
    XCTAssert([result isEqual:@YES]);
    
    [e evaluateExpression: @[@"let", @"@genders", @[@"male", @"male", @"male"]]];
    result = [e evaluateExpression: @[@"all", @"@genders", @"male"]];
    XCTAssert([result isEqual:@YES]);
    
}

- (void) testParseAndEvaluate {
    TMLRulesParser *p;
    TMLRulesEvaluator *e;

    p = [[TMLRulesParser alloc] initWithExpression:@"(= 0 (mod @n 10))"];
    NSObject *expr = [p parse];
    NSArray *expectation = @[@"=", @"0", @[@"mod", @"@n", @"10"]];
    XCTAssert([expectation isEqual:expr]);
    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @1}];
    NSObject *result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@NO]);

    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @50}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@YES]);
    
    p = [[TMLRulesParser alloc] initWithExpression:@"(in '5..9' (mod @n 10))"];
    expr = [p parse];
    expectation = @[@"in", @"5..9", @[@"mod", @"@n", @"10"]];
    XCTAssert([expectation isEqual:expr]);
    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @1}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@NO]);
    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @"1"}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@NO]);
    
    p = [[TMLRulesParser alloc] initWithExpression:@"(in '11..14' (mod @n 100))"];
    expr = [p parse];
    expectation = @[@"in", @"11..14", @[@"mod", @"@n", @"100"]];
    XCTAssert([expectation isEqual:expr]);
    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @1}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@NO]);
    
    p = [[TMLRulesParser alloc] initWithExpression:@"(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))"];
    expr = [p parse];
    expectation = @[@"||", @[@"=", @"0", @[@"mod", @"@n", @"10"]], @[@"in", @"5..9", @[@"mod", @"@n", @"10"]], @[@"in", @"11..14", @[@"mod", @"@n", @"100"]]];
    XCTAssert([expectation isEqual:expr]);
    
    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @1}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@NO]);
    
    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @2}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@NO]);
    
    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @5}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@YES]);

    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @50}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@YES]);

    e = [[TMLRulesEvaluator alloc] initWithVariables:@{@"@n": @11}];
    result = [e evaluateExpression:expr];
    XCTAssert([result isEqual:@YES]);
    
}

@end
