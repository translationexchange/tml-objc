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

@interface TMLDataTokenTest : TMLTestBase

@end


@implementation TMLDataTokenTest

- (void) testParsing {
    TMLDataToken *token = [[TMLDataToken alloc] initWithString:@"{user}"];
    XCTAssert([@"{user}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLDataToken alloc] initWithString:@"{ user }"];
    XCTAssert([@"{ user }" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
    
    token = [[TMLDataToken alloc] initWithString:@"{user:gender}"];
    XCTAssert([@"{user:gender}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[@"gender"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLDataToken alloc] initWithString:@"{user : gender}"];
    XCTAssert([@"{user : gender}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[@"gender"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
    
    token = [[TMLDataToken alloc] initWithString:@"{user::gen}"];
    XCTAssert([@"{user::gen}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[@"gen"] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLDataToken alloc] initWithString:@"{user:gender::gen}"];
    XCTAssert([@"{user:gender::gen}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[@"gender"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[@"gen"] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLDataToken alloc] initWithString:@"{user : gender :: gen}"];
    XCTAssert([@"{user : gender :: gen}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[@"gender"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[@"gen"] isEqual: [token.caseKeys allObjects]]);
}

- (void) testContextForLanguage {
    TMLLanguage *language = [self languageForLocale:@"en-US"];

    TMLDataToken *token;

    token = [[TMLDataToken alloc] initWithString:@"{user:gender}"];
    TMLLanguageContext *context = [token contextForLanguage:language];
    XCTAssert([context.keyword isEqual: @"gender"]);

    token = [[TMLDataToken alloc] initWithString:@"{user}"];
    context = [token contextForLanguage:language];
    XCTAssert([context.keyword isEqual: @"gender"]);

    token = [[TMLDataToken alloc] initWithString:@"{count}"];
    context = [token contextForLanguage:language];
    XCTAssert([context.keyword isEqual: @"number"]);
    
}

- (void) testTokenValue {
    TMLDataToken *token = [[TMLDataToken alloc] initWithString:@"{user}"];
    
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
    
    TMLDataToken *token = [[TMLDataToken alloc] initWithString:@"{user}"];
    
    TMLTestUser *user = [[TMLTestUser alloc] initWithFirstName:@"Michael" andLastName:@"Berkovich" andGender:@"male"];
    
    NSString *result = [token substituteInLabel:@"Hello {user}" tokens:@{@"user": user} language:language];
    XCTAssert([result isEqual: @"Hello Michael Berkovich"]);
    
    result = [token substituteInLabel:@"Hello {user}" tokens:@{@"user": @{@"object": @{@"name": @"Mike", @"gender": @"male"}, @"value": @"Michael"}} language:language ];
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
