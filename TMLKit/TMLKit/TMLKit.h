/*
 *  Copyright (c) 2017 Translation Exchange, Inc. All rights reserved.
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

#import "TMLGlobals.h"
#import "TMLLogger.h"
#import "TML.h"

#import "TMLModel.h"
#import "TMLApplication.h"
#import "TMLConfiguration.h"
#import "TMLSource.h"
#import "TMLLanguage.h"
#import "TMLTranslation.h"
#import "TMLTranslationKey.h"
#import "TMLBundle.h"
#import "TMLAPIBundle.h"
#import "TMLBundleManager.h"
#import "TMLUser.h"
#import "TMLTranslator.h"

#import "TMLBasicAPIClient.h"
#import "TMLAPIClient.h"
#import "TMLAPIResponse.h"
#import "TMLAPISerializer.h"

#import "TMLTokenizer.h"
#import "TMLAttributedDecorationTokenizer.h"
#import "TMLDataToken.h"
#import "TMLDataTokenizer.h"
#import "TMLDecorationTokenizer.h"
#import "TMLHtmlDecorationTokenizer.h"
#import "TMLMethodToken.h"
#import "TMLPipedToken.h"

#import "TMLJSONValueTransformer.h"
#import "TMLLanguageCase.h"
#import "TMLLanguageCaseRule.h"
#import "TMLLanguageContext.h"
#import "TMLLanguageContextRule.h"

#import "TMLRulesEvaluator.h"
#import "TMLRulesParser.h"

#import "UIViewController+TML.h"
#import "TMLTranslatorViewController.h"
#import "TMLLanguageSelectorViewController.h"
#import "TMLViewController.h"
#import "TMLWebViewController.h"

#import "NSAttributedString+TML.h"
#import "NSObject+TML.h"
#import "NSObject+TMLJSON.h"
#import "NSString+TML.h"
#import "UIActionSheet+TML.h"
#import "UIAlertView+TML.h"
#import "UIApplicationShortcutItem+TML.h"
#import "UIBarButtonItem+TML.h"
#import "UIBarItem+TML.h"
#import "UIButton+TML.h"
#import "UILabel+TML.h"
#import "UILocalNotification+TML.h"
#import "UINavigationItem+TML.h"
#import "UIRefreshControl+TML.h"
#import "UIResponder+TML.h"
#import "UISearchBar+TML.h"
#import "UISegmentedControl+TML.h"
#import "UICollectionView+TML.h"
#import "UITableView+TML.h"
#import "UITextField+TML.h"
#import "UITextView+TML.h"
#import "UIView+TML.h"
#import "UIViewController+TML.h"
#import "UIAlertController+TML.h"
#import "UITableViewRowAction+TML.h"
#import "UIMutableUserNotificationAction+TML.h"

//! Project version number for TMLKit.
FOUNDATION_EXPORT double TMLKitVersionNumber;

//! Project version string for TMLKit.
FOUNDATION_EXPORT const unsigned char TMLKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import "PublicHeader.h"


