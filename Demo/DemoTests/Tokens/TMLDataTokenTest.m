//
//  TMLDataTokenTest.m
//  TML
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import "TMLDataToken.h"
#import "TMLLanguageContext.h"
#import "TMLTestBase.h"
#import "TMLTestUser.h"
#import <Foundation/Foundation.h>

@interface TMLDataTokenTest : TMLTestBase

@end


@implementation TMLDataTokenTest

- (void) testParsing {
    TMLDataToken *token = [[TMLDataToken alloc] initWithName:@"{user}"];
    XCTAssert([@"{user}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    token = [[TMLDataToken alloc] initWithName:@"{ user }"];
    XCTAssert([@"{ user }" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
    
    token = [[TMLDataToken alloc] initWithName:@"{user:gender}"];
    XCTAssert([@"{user:gender}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[@"gender"] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    token = [[TMLDataToken alloc] initWithName:@"{user : gender}"];
    XCTAssert([@"{user : gender}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[@"gender"] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
    
    token = [[TMLDataToken alloc] initWithName:@"{user::gen}"];
    XCTAssert([@"{user::gen}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[@"gen"] isEqual: token.caseKeys]);

    token = [[TMLDataToken alloc] initWithName:@"{user:gender::gen}"];
    XCTAssert([@"{user:gender::gen}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[@"gender"] isEqual: token.contextKeys]);
    XCTAssert([@[@"gen"] isEqual: token.caseKeys]);

    token = [[TMLDataToken alloc] initWithName:@"{user : gender :: gen}"];
    XCTAssert([@"{user : gender :: gen}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[@"gender"] isEqual: token.contextKeys]);
    XCTAssert([@[@"gen"] isEqual: token.caseKeys]);
}

- (void) testNameWithOptions {
    TMLDataToken *token;
    
    token = [[TMLDataToken alloc] initWithName:@"{user}"];
    XCTAssert([[token nameWithOptions:@{}] isEqual: @"user"]);
    XCTAssert([[token nameWithOptions:@{@"parens": @YES}] isEqual: @"{user}"]);
    
    NSString *name = [token nameWithOptions:@{@"parens": @YES, @"context_keys": @YES}];
    XCTAssert([name isEqual: @"{user}"]);
    name = [token nameWithOptions:@{@"parens": @YES, @"case_keys": @YES}];
    XCTAssert([name isEqual: @"{user}"]);
    name = [token nameWithOptions:@{@"parens": @YES, @"context_keys": @YES, @"case_keys": @YES}];
    XCTAssert([name isEqual: @"{user}"]);
    
    token = [[TMLDataToken alloc] initWithName:@"{user:gender::gen}"];
    XCTAssert([[token nameWithOptions:@{}] isEqual: @"user"]);
    XCTAssert([[token nameWithOptions:@{@"parens": @YES}] isEqual: @"{user}"]);

    name = [token nameWithOptions:@{@"parens": @YES, @"context_keys": @YES}];
    XCTAssert([name isEqual: @"{user:gender}"]);
    name = [token nameWithOptions:@{@"parens": @YES, @"case_keys": @YES}];
    XCTAssert([name isEqual: @"{user::gen}"]);
    name = [token nameWithOptions:@{@"parens": @YES, @"context_keys": @YES, @"case_keys": @YES}];
    XCTAssert([name isEqual: @"{user:gender::gen}"]);

}

- (void) testContextForLanguage {
    TMLLanguage *language = [self languageForLocale:@"en-US"];

    TMLDataToken *token;

    token = [[TMLDataToken alloc] initWithName:@"{user:gender}"];
    TMLLanguageContext *context = [token contextForLanguage:language];
    XCTAssert([context.keyword isEqual: @"gender"]);

    token = [[TMLDataToken alloc] initWithName:@"{user}"];
    context = [token contextForLanguage:language];
    XCTAssert([context.keyword isEqual: @"gender"]);

    token = [[TMLDataToken alloc] initWithName:@"{count}"];
    context = [token contextForLanguage:language];
    XCTAssert([context.keyword isEqual: @"number"]);
    
}

- (void) testTokenValue {
    TMLDataToken *token = [[TMLDataToken alloc] initWithName:@"{user}"];
    
    TMLTestUser *user = [[TMLTestUser alloc] initWithFirstName:@"Michael" andLastName:@"Berkovich" andGender:@"male"];
    
    NSString *value = [token tokenValue:@{@"user": user}];
    XCTAssertEqualObjects(@"Michael Berkovich", value);

    value = [token tokenValue:@{@"user": @[user, user.firstName]}];
    XCTAssertEqualObjects(@"Michael", value);

    value = [token tokenValue:@{@"user": @[user, @"Mike"]}];
    XCTAssert([value isEqual: @"Mike"]);

    value = [token tokenValue:@{@"user": @{@"object": @{@"name": @"Mike", @"gender": @"male"}, @"property": @"name"}}];
    XCTAssert([value isEqual: @"Mike"]);
    
    value = [token tokenValue:@{@"user": @{@"object": @{@"name": @"Mike", @"gender": @"male"}, @"value": @"Michael"}}];
    XCTAssert([value isEqual: @"Michael"]);
    
}

- (void) testSubstitution {
    TMLLanguage *language = [self languageForLocale:@"en-US"];
    
    TMLDataToken *token = [[TMLDataToken alloc] initWithName:@"{user}"];
    
    TMLTestUser *user = [[TMLTestUser alloc] initWithFirstName:@"Michael" andLastName:@"Berkovich" andGender:@"male"];
    
    NSString *result = [token substituteInLabel:@"Hello {user}" usingTokens:@{@"user": user} forLanguage:language withOptions:@{}];
    XCTAssert([result isEqual: @"Hello Michael Berkovich"]);
    
    result = [token substituteInLabel:@"Hello {user}" usingTokens:@{@"user": @{@"object": @{@"name": @"Mike", @"gender": @"male"}, @"value": @"Michael"}} forLanguage:language withOptions:@{}];
    XCTAssert([result isEqual: @"Hello Michael"]);
    
}

- (void) testTokenObjectForName {
    TMLTestUser *user = [[TMLTestUser alloc] initWithFirstName:@"Michael" andLastName:@"Berkovich" andGender:@"male"];

    NSObject *result = [TMLDataToken tokenObjectForName:@"user" fromTokens:@{@"user": user}];
    XCTAssert([user isEqual:result]);

    result = [TMLDataToken tokenObjectForName:@"user" fromTokens:@{@"user": @[user, user.firstName]}];
    XCTAssert([user isEqual:result]);
    
    result = [TMLDataToken tokenObjectForName:@"user" fromTokens:@{@"user": @[user, @"Mike"]}];
    XCTAssert([user isEqual:result]);

    result = [TMLDataToken tokenObjectForName:@"user" fromTokens:@{@"user": @{@"object": user}}];
    XCTAssert([user isEqual:result]);

    NSDictionary *object = @{@"name": @"Mike", @"gender": @"male"};
    result = [TMLDataToken tokenObjectForName:@"user" fromTokens:@{@"user": @{@"object": @{@"name": @"Mike", @"gender": @"male"}}}];
    XCTAssert([object isEqual:result]);
}

@end
