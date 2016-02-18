//
//  NSURL+TML.h
//  TMLKit
//
//  Created by Pasha on 12/7/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (TML)

- (NSURL *)URLByAppendingQueryParameters:(NSDictionary *)queryParameters;

@end
