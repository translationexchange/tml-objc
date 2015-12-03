/*
 *  Copyright (c) 2015 Translation Exchange, Inc. All rights reserved.
 *
 *  _______                  _       _   _             ______          _
 * |__   __|                | |     | | (_)           |  ____|        | |
 *    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
 *    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
 *    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
 *    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
 *                                                                                        __/ |
 *                                                                                       |___/
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

#import "TranslationViewController.h"

@interface TranslationViewController ()

@property (weak, nonatomic) IBOutlet UITextView *originalTextView;

@property (weak, nonatomic) IBOutlet UITextView *translationTextView;

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

@property (weak, nonatomic) IBOutlet UILabel *originalLabel;

@property (weak, nonatomic) IBOutlet UILabel *translationLabel;

@end

@implementation TranslationViewController





- (void)viewDidLoad {
    [super viewDidLoad];
    [self translate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSDictionary *) parsedTokens {
    if ([self.tokens length] == 0) {
        return @{};
    }
    
    NSError *error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:[self.tokens dataUsingEncoding:NSUTF8StringEncoding]
                                                           options:NSJSONReadingAllowFragments
                                                             error:&error];
    
    if (result == nil) {
        result = [NSDictionary dictionary];
    }
    
    return  result;
}

- (NSDictionary *) parsedOptions {
    if ([self.options length] == 0) {
        return @{};
    }
    
    NSError *error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:[self.options dataUsingEncoding:NSUTF8StringEncoding]
                                                           options:NSJSONReadingAllowFragments
                                                             error:&error];
    
    if (result == nil) {
        result = [NSDictionary dictionary];
    }
    
    return  result;
}

- (IBAction)translate:(id)sender {
    self.originalTextView.text = self.label;

    TMLBeginSource(@"samples");
    
    NSObject *translation = TMLLocalizedAttributedStringWithDescriptionAndTokensAndOptions(self.label, self.description, [self parsedTokens], [self parsedOptions]);
    [self setTextValue:translation toField:self.translationTextView];
    
    TMLEndSource
}

- (IBAction)changeLanguage:(id)sender {
    [TMLLanguageSelectorViewController changeLanguageFromController:self];
}

- (IBAction)openTranslator:(id)sender {
    [TMLTranslatorViewController translateFromController:self];
}

- (void) tmlLanguageSelectorViewController:(TMLLanguageSelectorViewController *) tmlLanguageSelectorViewController didSelectLanguage: (TMLLanguage *) language {
    [self translate:self];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  
    TMLBeginSource(@"Translations");

    NSString *languageName = [[[TML sharedInstance] currentLanguage] englishName];
    [self setTextValue:TMLLocalizedStringWithTokens(@"{language} Translation", @{@"language": TMLLocalizedString(languageName)}) toField:self.navigationItem];
    [self setTextValue:TMLLocalizedString(@"Original Label") toField:self.originalLabel];
    [self setTextValue:TMLLocalizedString(@"Translation") toField:self.translationLabel];

    TMLEndSource
}

@end
