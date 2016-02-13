//
//  TMLStringTests.m
//  TMLKit
//
//  Created by Pasha on 2/12/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSAttributedString+TML.h"

@interface TMLStringTests : XCTestCase

@end

@implementation TMLStringTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)_testString:(NSString *)string attributes:(NSDictionary *)attrs {
    NSDictionary *expectedTokens = @{@"style": @{@"attributes": attrs}};
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string
                                                                           attributes:attrs];
//    NSString *expectedString = [[attributedString string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *expectedString = [attributedString string];
    NSDictionary *tokens = nil;
    NSString *result = [attributedString tmlAttributedString:&tokens implicit:YES];
    XCTAssert([expectedString isEqualToString:result], @"Invalid tml attributed string: '%@'", string);
    if (string.length == 0) {
        // empty attributed strings don't have any attributes
        XCTAssert(tokens == nil, @"Unexpected tokens");
    }
    else {
        XCTAssert([tokens isEqualToDictionary:expectedTokens], @"Unexpected tokens");
    }
}

- (void)testTMLAttributedStringsWithWhiteSpace {
    NSDictionary *attrs = @{
                            NSFontAttributeName: [UIFont systemFontOfSize:10.]
                            };
    [self _testString:@"" attributes:attrs];
    [self _testString:@" " attributes:attrs];
    [self _testString:@"       " attributes:attrs];
    [self _testString:@" \n" attributes:attrs];
    [self _testString:@"\n   " attributes:attrs];
    [self _testString:@"\n\n\n\n\n" attributes:attrs];
    [self _testString:@"\n \n" attributes:attrs];
    [self _testString:@"\t" attributes:attrs];
    [self _testString:@" \t\n\t \n" attributes:attrs];
}

@end
