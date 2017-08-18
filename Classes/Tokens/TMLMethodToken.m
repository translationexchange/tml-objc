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


#import "TMLMethodToken.h"

@implementation TMLMethodToken

+ (NSString *) pattern {
    return @"(\\{[^_:.][\\w]*(\\.[\\w]+)(:[\\w]+)*(::[\\w]+)*\\})";
}

- (void) parseFromString:(NSString *)string {
    [super parseFromString:string];
    
    NSArray *parts = [self.name componentsSeparatedByString:@"."];
    if (parts.count > 0) {
        self.objectName = [parts objectAtIndex:0];
    }
    if (parts.count > 1) {
        self.keyPath = [[parts subarrayWithRange:NSMakeRange(1, parts.count-1)] componentsJoinedByString:@"."];
    }
}

- (NSString *) substituteInLabel:(NSString *)translatedLabel
                          tokens:(NSDictionary *)tokens
                        language:(TMLLanguage *)language
{
    NSString *objectName = self.objectName;
    NSObject *object = [self.class tokenObjectForName:objectName fromTokens:tokens];
    
    NSString *result = translatedLabel;
    
    if (object == nil) {
        TMLError(@"Invalid object reference: %@", objectName);
    } else {
        @try {
            result = [object valueForKeyPath:self.keyPath];
            result = [translatedLabel stringByReplacingOccurrencesOfString:self.stringRepresentation withString:result];
        }
        @catch (NSException *exception) {
            TMLError(@"Error obtaining value of %@.%@: %@", self.objectName, self.keyPath);
        }
    }
    
    return result;
}

@end
