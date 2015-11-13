//
//  TMLTranslationKeyTest.m
//  TML
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import "TML.h"
#import "TMLConfiguration.h"
#import "TMLTestBase.h"
#import "TMLTranslationKey.h"

@interface TMLTranslationKeyTest : TMLTestBase

@end

@implementation TMLTranslationKeyTest

- (void) testSubstitution {
    TMLApplication *app = [self application];
    TMLLanguage *en = [self languageForLocale:@"en-US"];
    
    TMLTranslationKey *tk = [[TMLTranslationKey alloc] initWithAttributes:@{@"locale": @"en-US", @"label": @"Hello World", @"application": app}];
    XCTAssertEqualObjects([tk translateToLanguage:en], @"Hello World");

    tk = [[TMLTranslationKey alloc] initWithAttributes:@{@"locale": @"en-US", @"label": @"[bold: Hello World]", @"application": app}];
    XCTAssertEqualObjects([tk translateToLanguage:en withTokens:@{@"bold": @"<b>{$0}</b>"}], @"<b>Hello World</b>");
}


- (void) testDefaultTokens {
    TMLApplication *app = [self application];
    TMLLanguage *en = [self languageForLocale:@"en-US"];
    
    [TML configure:^(TMLConfiguration *config) {
        [config setDefaultTokenValue:@"<strong>{$0}</strong>" forName:@"indent" type:@"decoration"];
        [config setDefaultTokenValue:@"World" forName:@"world" type:@"data"];
    }];
    
    TMLTranslationKey *tk = [[TMLTranslationKey alloc] initWithAttributes:@{@"locale": @"en-US", @"label": @"[indent: Hello World]", @"application": app}];
    XCTAssertEqualObjects([tk translateToLanguage:en], @"<strong>Hello World</strong>");
    
    tk = [[TMLTranslationKey alloc] initWithAttributes:@{@"locale": @"en-US", @"label": @"[indent: Hello {world}]", @"application": app}];
    XCTAssertEqualObjects([tk translateToLanguage:en], @"<strong>Hello World</strong>");
}


@end
