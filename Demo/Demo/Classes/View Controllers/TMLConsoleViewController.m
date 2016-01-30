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

#import "TMLConsoleViewController.h"
#import "TMLTableViewCell.h"
#import "TranslationViewController.h"

@interface TMLConsoleViewController ()

@property (weak, nonatomic) IBOutlet UITableView *itemsTableView;

@property (weak, nonatomic) IBOutlet UITextView *selectedTextView;

@property (strong, nonatomic) IBOutlet UIToolbar *textViewToolbar;

@end

@implementation TMLConsoleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.textViewToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    _textViewToolbar.items = [NSArray arrayWithObjects:
                             [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc]initWithTitle:@"Translate" style:UIBarButtonItemStyleDone target:self action:@selector(submitTML:)],
                             [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           nil];
    [_textViewToolbar sizeToFit];
    
    self.label = @"Hello World";
    self.context = @"";
    self.tokens = @"{}";
    self.options = @"{}";
    
	if (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPhone) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardDidShow:)
													 name:UIKeyboardDidShowNotification
												   object:self.view.window];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillHide:)
													 name:UIKeyboardWillHideNotification
												   object:self.view.window];
	}

}

- (IBAction) submitTML: (id)sender {
    [_selectedTextView resignFirstResponder];

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    TranslationViewController *controller = [mainStoryboard instantiateViewControllerWithIdentifier:@"TranslationViewController"];
    controller.label = _label;
    controller.context = _context;
    controller.tokens = _tokens;
    controller.options = _options;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TMLTableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"TMLTableViewCell"];
    
    if (cell == nil) {
        cell = [[TMLTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TMLTableViewCell"];
    }
    
    TMLBeginBlockWithOptions(@{@"source": @"TML Labels"});
    
    if (indexPath.row == 0) {
        cell.titleLabel.text = TMLLocalizedString(@"Label");
        cell.descriptionLabel.text = TMLLocalizedString(@"Text to be translated");
        cell.textView.delegate = self;
        cell.textView.inputAccessoryView = _textViewToolbar;
        cell.textView.tag = 0;
        cell.textView.text = _label;
        cell.optionalLabel.text = TMLLocalizedString(@"required");
    } else if (indexPath.row == 1) {
        cell.titleLabel.text = TMLLocalizedString(@"Description");
        cell.descriptionLabel.text = TMLLocalizedString(@"Context of the label");
        cell.textView.delegate = self;
        cell.textView.inputAccessoryView = _textViewToolbar;
        cell.textView.tag = 1;
        cell.textView.text = _context;
        cell.optionalLabel.text = TMLLocalizedString(@"optional");
    } else if (indexPath.row == 2) {
        cell.titleLabel.text = TMLLocalizedString(@"Tokens");
        cell.descriptionLabel.text = TMLLocalizedString(@"Token values");
        cell.textView.delegate = self;
        cell.textView.inputAccessoryView = _textViewToolbar;
        cell.textView.tag = 2;
        cell.textView.text = _tokens;
        cell.optionalLabel.text = TMLLocalizedString(@"optional");
    } else if (indexPath.row == 3) {
        cell.titleLabel.text = TMLLocalizedString(@"Options");
        cell.descriptionLabel.text = TMLLocalizedString(@"Additional options");
        cell.textView.delegate = self;
        cell.textView.inputAccessoryView = _textViewToolbar;
        cell.textView.tag = 3;
        cell.textView.text = _options;
        cell.optionalLabel.text = TMLLocalizedString(@"optional");
    }
    
    TMLEndBlockWithOptions();
    
    return cell;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.selectedTextView  = textView;
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	[textView resignFirstResponder];
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    switch (textView.tag) {
        case 0:
            self.label = textView.text;
            break;
        case 1:
            self.context = textView.text;
            break;
        case 2:
            self.tokens = textView.text;
            break;
        case 3:
            self.options = textView.text;
            break;
            
        default:
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification {
	if (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPhone) {
//		NSDictionary *userInfo = [notification userInfo];
//		CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
		TMLDebug(@"%@", NSStringFromCGRect(self.itemsTableView.frame));
		CGRect newTableViewFrame = CGRectMake(self.itemsTableView.frame.origin.x,
											  self.itemsTableView.frame.origin.y,
											  self.itemsTableView.frame.size.width,
                                              screenRect.size.height - 300);
		self.itemsTableView.frame = newTableViewFrame;
//        self.itemsTableView.contentInset = UIEdgeInsetsMake(self.itemsTableView.contentInset.top, 0, size.height, 0);
//		TMLDebug(@"%@", NSStringFromCGRect(self.itemsTableView.frame));
//		self.itemsTableView.contentSize = CGSizeMake(self.itemsTableView.contentSize.width, self.itemsTableView.contentSize.height-size.height);
	}
}

- (void)keyboardWillHide:(NSNotification *)notification {
	if (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPhone) {
//        NSDictionary *userInfo = [notification userInfo];
    //    CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGRect newTableViewFrame = CGRectMake(self.itemsTableView.frame.origin.x,
                                          self.itemsTableView.frame.origin.y,
                                          self.itemsTableView.frame.size.width,
                                          screenRect.size.height);
        self.itemsTableView.frame = newTableViewFrame;
    //    self.itemsTableView.contentInset = UIEdgeInsetsMake(self.itemsTableView.contentInset.top, 0, 0, 0);
    //	TMLDebug(@"%@", NSStringFromCGRect(self.itemsTableView.frame));
    //    self.itemsTableView.contentSize = CGSizeMake(self.itemsTableView.contentSize.width, self.itemsTableView.contentSize.height+size.height);
    }
}

- (void)scrollToRectOfTextField {
	UITableViewCell *cell = (UITableViewCell*)[self.selectedTextView superview];
	CGRect r = CGRectMake(self.selectedTextView.frame.origin.x,
						  cell.frame.origin.y+self.selectedTextView.frame.origin.y,
						  self.selectedTextView.frame.size.width,
						  self.selectedTextView.frame.size.height);
	[self.itemsTableView scrollRectToVisible:r animated:YES];
}

- (void) translationsLoaded {
    [self.itemsTableView reloadData];
}

@end
