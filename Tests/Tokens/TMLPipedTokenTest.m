//
//  TMLPipedTokenTest.m
//  TML
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import "TMLPipedToken.h"
#import "TMLLanguageContext.h"
#import "TMLTestBase.h"
#import "TMLAPISerializer.h"

@interface TMLPipedTokenTest : TMLTestBase

@end

@implementation TMLPipedTokenTest

/***********************************************************************
 #
 # Piped Token Form
 #
 # {count | message}   - will not include count value: "messages"
 # {count | message, messages}
 # {count:number | message, messages}
 # {user:gender | he, she, he/she}
 # {now:date | did, does, will do}
 # {users:list | all male, all female, mixed genders}
 #
 # {count || message, messages}  - will include count:  "5 messages"
 #
 ***********************************************************************/

- (TMLLanguageContext *)languageContextFromResource:(NSString *)fileName {
    NSData *jsonData = [self loadJSONDataFromResource:fileName];
    TMLLanguageContext *context = [TMLAPISerializer materializeData:jsonData withClass:[TMLLanguageContext class]];
    return context;
}

- (void) testParsing {
    TMLPipedToken *token;

    token = [[TMLPipedToken alloc] initWithString:@"{count | message}"];
    XCTAssert([@"{count | message}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    XCTAssert([@[@"message"] isEqualToArray: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLPipedToken alloc] initWithString:@"{count| message}"];
    XCTAssert([@"{count| message}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
    
    token = [[TMLPipedToken alloc] initWithString:@"{count|message}"];
    XCTAssert([@"{count|message}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
    
    token = [[TMLPipedToken alloc] initWithString:@"{count || message}"];
    XCTAssert([@"{count || message}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLPipedToken alloc] initWithString:@"{count|| message}"];
    XCTAssert([@"{count|| message}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
    
    token = [[TMLPipedToken alloc] initWithString:@"{count||message}"];
    XCTAssert([@"{count||message}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLPipedToken alloc] initWithString:@"{count:number||message}"];
    XCTAssert([@"{count:number||message}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[@"number"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
    
    token = [[TMLPipedToken alloc] initWithString:@"{count|| message, messages}"];
    XCTAssert([@"{count|| message, messages}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    NSArray *expectation = @[@"message", @"messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLPipedToken alloc] initWithString:@"{count|| one: message, other: messages}"];
    XCTAssert([@"{count|| one: message, other: messages}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    expectation = @[@"one: message", @"other: messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLPipedToken alloc] initWithString:@"{count||one:message,other:messages}"];
    XCTAssert([@"{count||one:message,other:messages}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    expectation = @[@"one:message", @"other:messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
    
    token = [[TMLPipedToken alloc] initWithString:@"{count:number || one: message, other: messages}"];
    XCTAssert([@"{count:number || one: message, other: messages}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    expectation = @[@"one: message", @"other: messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[@"number"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
 
    token = [[TMLPipedToken alloc] initWithString:@"{count : number || one : message, other : messages}"];
    XCTAssert([@"{count : number || one : message, other : messages}" isEqual: token.stringRepresentation]);
    XCTAssert([@"count" isEqual: token.name]);
    expectation = @[@"one : message", @"other : messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[@"number"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    XCTAssert([token isValueDisplayedInTranslation]);

    token = [[TMLPipedToken alloc] initWithString:@"{user| Born on}"];
    XCTAssert([@"{user| Born on}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[@"Born on"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    XCTAssert(![token isValueDisplayedInTranslation]);

    token = [[TMLPipedToken alloc] initWithString:@"{user:gender| Born on}"];
    XCTAssert([@"{user:gender| Born on}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[@"Born on"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[@"gender"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);

    token = [[TMLPipedToken alloc] initWithString:@"{user:gender | Born on}"];
    XCTAssert([@"{user:gender | Born on}" isEqual: token.stringRepresentation]);
    XCTAssert([@"user" isEqual: token.name]);
    XCTAssert([@[@"Born on"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[@"gender"] isEqual: [token.contextKeys allObjects]]);
    XCTAssert([@[] isEqual: [token.caseKeys allObjects]]);
}

- (void) testValueMapForContext {
    TMLPipedToken *token;
    NSDictionary *expectation;
    
    TMLLanguageContext *context = [self languageContextFromResource:@"ctx_en-US_gender"];

    token = [[TMLPipedToken alloc] initWithString:@"{user:gender| other: Born on}"];
    expectation = @{@"other": @"Born on"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    token = [[TMLPipedToken alloc] initWithString:@"{user| male: He, female: She}"];
    expectation = @{@"male": @"He", @"female": @"She"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TMLPipedToken alloc] initWithString:@"{user| male: He, female: She, other: He/She}"];
    expectation = @{@"male": @"He", @"female": @"She", @"other": @"He/She"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    token = [[TMLPipedToken alloc] initWithString:@"{user:gender| Born on}"];
    expectation = @{@"other": @"Born on"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    token = [[TMLPipedToken alloc] initWithString:@"{user| He, She}"];
    expectation = @{@"male": @"He", @"female": @"She", @"other": @"He/She"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TMLPipedToken alloc] initWithString:@"{user| He, She, She/He}"];
    expectation = @{@"male": @"He", @"female": @"She", @"other": @"She/He"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    context = [self languageContextFromResource:@"ctx_en-US_number"];
    
    token = [[TMLPipedToken alloc] initWithString:@"{count|| one: message, many: messages}"];
    expectation = @{@"one": @"message", @"many": @"messages"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TMLPipedToken alloc] initWithString:@"{count|| message, messages}"];
    expectation = @{@"one": @"message", @"other": @"messages"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
//    token = [[TMLPipedToken alloc] initWithString:@"{count|| message}"];
//    expectation = @{@"one": @"message", @"other": @"messages"};
//    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    context = [self languageContextFromResource:@"ctx_ru_gender"];
    
    token = [[TMLPipedToken alloc] initWithString:@"{user| female: родилась, other: родился}"];
    expectation = @{@"female": @"родилась", @"other": @"родился"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TMLPipedToken alloc] initWithString:@"{user| родился, родилась}"];
    expectation = @{@"female": @"родилась", @"other": @"родился"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TMLPipedToken alloc] initWithString:@"{user| родился}"];
    expectation = @{@"other": @"родился"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    context = [self languageContextFromResource:@"ctx_ru_number"];
    
    token = [[TMLPipedToken alloc] initWithString:@"{count|| one: сообщение, few: сообщения, other: сообщений}"];
    expectation = @{@"one": @"сообщение", @"few": @"сообщения", @"other": @"сообщений"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TMLPipedToken alloc] initWithString:@"{count|| сообщение, сообщения, сообщений}"];
    expectation = @{@"one": @"сообщение", @"few": @"сообщения", @"many": @"сообщений", @"other": @"сообщений"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TMLPipedToken alloc] initWithString:@"{count|| сообщение, сообщения, сообщений, сообщения}"];
    expectation = @{@"one": @"сообщение", @"few": @"сообщения", @"many": @"сообщений", @"other": @"сообщения"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
}

@end
