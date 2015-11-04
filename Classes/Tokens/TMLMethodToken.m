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

#import "TMLMethodToken.h"

@implementation TMLMethodToken

@synthesize objectMethod, objectName;

+ (NSString *) pattern {
    return @"(\\{[^_:.][\\w]*(\\.[\\w]+)(:[\\w]+)*(::[\\w]+)*\\})";
}

- (void) parse {
    [super parse];
    
    NSArray *parts = [self.shortName componentsSeparatedByString:@"."];
    self.objectName = [parts objectAtIndex:0];
    self.objectMethod = [parts objectAtIndex:1];
}

- (NSString *) valueForObject: (NSObject *) object andMethod: (NSString *) method {
    if (object == nil) {
//        TML::ins
        return self.fullName;
    }
  
    return @"";
}

- (NSString *) substituteInLabel: (NSString *) translatedLabel usingTokens: (NSDictionary *) tokens forLanguage: (TMLLanguage *) language withOptions: (NSDictionary *) options {
    
    NSObject *object = [self.class tokenObjectForName:self.objectName fromTokens:tokens];
    
    NSString *tokenValue;
    
    if (object == nil)
       tokenValue = [NSString stringWithFormat:@"{%@: missing value}", self.shortName];
    else if ([object respondsToSelector:NSSelectorFromString(self.objectMethod)]) {
        tokenValue = [object valueForKey:self.objectMethod];
    } else {
        tokenValue = [NSString stringWithFormat:@"{%@: undefined property}", self.shortName];
    }
    
    return [translatedLabel stringByReplacingOccurrencesOfString:self.fullName withString:tokenValue];
}

@end
