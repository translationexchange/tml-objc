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

#import "TokensDemoViewController.h"
#import "TMLSampleTableViewCell.h"

@interface TokensDemoViewController ()

@property (nonatomic, retain) IBOutlet UILabel *descriptionLabel;

@end

@implementation TokensDemoViewController

- (void) prepareSamples {
    // Overload in the extending class
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareSamples];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 260;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TMLSampleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TMLSampleTableViewCell"];
    
    if (cell == nil) {
        cell = [[TMLSampleTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TMLSampleTableViewCell"];
    }
    
    NSDictionary *section = (NSDictionary *) [self.items objectAtIndex:indexPath.section];
    NSDictionary *item = (NSDictionary *) [[section objectForKey:@"items"] objectAtIndex:indexPath.row];
    
    cell.translationLabel.text = TMLLocalizedString(@"Translation");
    cell.tokensLabel.text = TMLLocalizedString(@"Tokens");
    cell.tmlLabel.text = TMLLocalizedString(@"Label");
    
    cell.tml.text = [item objectForKey:@"tml"];
    if ([item objectForKey:@"tokens_desc"])
        cell.tokens.text = [item objectForKey:@"tokens_desc"];
    else if ([item objectForKey:@"tokens"]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject: [item objectForKey:@"tokens"]
                                                           options: NSJSONWritingPrettyPrinted
                                                             error: &error];
        
        if (jsonData) {
           cell.tokens.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    } else {
        cell.tokens.text = @"";
    }
    
    id result = nil;
    NSString *label = item[@"tml"];
    NSDictionary *tokens = item[@"tokens"];
    if ([label tmlContainsDecoratedTokens] == YES) {
        result = TMLLocalizedAttributedString(label, tokens);
    } else {
        result = TMLLocalizedString(label, tokens);
    }
    if ([result isKindOfClass:[NSAttributedString class]] == YES) {
        cell.translation.attributedText = result;
    }
    else {
        cell.translation.text = result;
    }
    
    cell.translation.frame = CGRectMake(2, 2, 302, 52);
    [cell.translation setNumberOfLines:0];
    [cell.translation sizeToFit];
    
    return cell;
}

@end
