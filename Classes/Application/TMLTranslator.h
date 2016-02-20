//
//  TMLTranslatorUser.h
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMLTranslator : NSObject
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSURL *mugshotURL;
@property (assign, nonatomic) BOOL inlineTranslationAllowed;
@end
