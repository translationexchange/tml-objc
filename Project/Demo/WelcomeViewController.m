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

#import "WelcomeViewController.h"
#import "Tml.h"
#import "UIViewController+Tml.h"

@interface WelcomeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UILabel *welcomeText;

@end

@implementation WelcomeViewController

- (void) localize {
//   self.welcomeLabel.text = NSLocalizedString(@"Welcome To Tml Demo", @"Welcome message");
    
//    TmlLocalizeViewWithLabelAndDescription(self.welcomeLabel, @"Welcome To Tml Demo", @"Welcome message");
  
    TmlLocalizeView(self.view);
    
//    self.welcomeLabel.text = TmlLocalizedString(@"Welcome");
    

    //    TmlBeginSource(@"Welcome Screen");
//
////    NSDictionary *user = @{@"name": @"Michael", @"gender": @"male"};
////    {user:gender::possesive || male: himself, female: herself}
////    {birthday:date || past: liked, present: likes, future: will like}
////    self.welcomeLabel.attributedText = TmlLocalizedAttributedStringWithTokens(@"{user} uploaded {count || photo} of {user | himself, herself} to {user | his, her} photo album", (@{@"count": @5, @"user": @{@"object": user, @"attribute": @"name"}, @"bold": @{@"font": @{@"family": @"Arial", @"size": @20}, @"color": @"green"}})); //, (@{@"user": @"Michael", @"another": @"test"}));
//    
////    [self setTextValue: TmlLocalizedStringWithDescription(@"Welcome", @"Welcome title") toField:self.titleLabel];
////    [self setTextValue: TmlLocalizedAttributedStringWithTokens(@"You have [bold: {count || message}]", (@{@"count": @1, @"bold": @{
////                                                                     @"color": @"green",
////                                                                     @"font": @{@"name": @"ChalkboardSE", @"size": @18}
////                                                                 }}))
////               toField:self.welcomeLabel];
//    
////    TmlLocalizeViewWithLabel(self.titleLabel, @"Welcome");
////    TmlLocalizeViewWithLabelAndTokens(self.welcomeLabel, @"Welcome to [bold: Tml Demo]",
////                                        (@{@"bold": @{
////                                                   @"underline": @"double",
////                                                   @"font": @{@"name": @"ChalkboardSE", @"size": @42}
////                                            }
////                                        }));
////    TmlLocalizeView(self.welcomeText);
//    
////    
////    [self setTextValue: TmlLocalizedString(@"Welcome") toField:self.titleLabel];
////    [self setTextValue: TmlLocalizedString(@"Welcome to Tml Demo") toField:self.self.welcomeLabel];
////    [self setTextValue: TmlLocalizedString(@"This application demonstrates Tml's capabilities. Use the menu on the left to choose a sample.")
////               toField:self.welcomeText];
//    
//    TmlLocalizeView(self.view);
//    
//    TmlEndSource
}


@end

