//
//  TmlTranslationKeyTest.m
//  Tml
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import "TMLTestBase.h"
#import "TmlTranslationKey.h"
#import "Tml.h"

@interface TMLTranslationKeyTest : TMLTestBase

@end

@implementation TMLTranslationKeyTest

- (void) testSubstitution {
    TmlApplication *app = [self application];
    TmlLanguage *en = [self languageForLocale:@"en-US"];
    
    TmlTranslationKey *tk = [[TmlTranslationKey alloc] initWithAttributes:@{@"locale": @"en-US", @"label": @"Hello World", @"application": app}];
    XCTAssertEqualObjects([tk translateToLanguage:en], @"Hello World");

    tk = [[TmlTranslationKey alloc] initWithAttributes:@{@"locale": @"en-US", @"label": @"[bold: Hello World]", @"application": app}];
    XCTAssertEqualObjects([tk translateToLanguage:en withTokens:@{@"bold": @"<b>{$0}</b>"}], @"<b>Hello World</b>");
}


- (void) testDefaultTokens {
    TmlApplication *app = [self application];
    TmlLanguage *en = [self languageForLocale:@"en-US"];
    
    [Tml configure:^(TmlConfiguration *config) {
        [config setDefaultTokenValue:@"<strong>{$0}</strong>" forName:@"indent" type:@"decoration"];
        [config setDefaultTokenValue:@"World" forName:@"world" type:@"data"];
    }];
    
    TmlTranslationKey *tk = [[TmlTranslationKey alloc] initWithAttributes:@{@"locale": @"en-US", @"label": @"[indent: Hello World]", @"application": app}];
    XCTAssertEqualObjects([tk translateToLanguage:en], @"<strong>Hello World</strong>");
    
    tk = [[TmlTranslationKey alloc] initWithAttributes:@{@"locale": @"en-US", @"label": @"[indent: Hello {world}]", @"application": app}];
    XCTAssertEqualObjects([tk translateToLanguage:en], @"<strong>Hello World</strong>");
}


@end
