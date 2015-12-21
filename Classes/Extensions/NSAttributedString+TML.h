//
//  NSAttributedString+TML.h
//  TMLKit
//
//  Created by Pasha on 12/6/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (TML)

- (NSString *)tmlAttributedString:(NSDictionary **)tokens;
- (NSString *)tmlAttributedString:(NSDictionary **)tokens implicit:(BOOL)implicit;

@end
