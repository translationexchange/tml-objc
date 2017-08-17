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

#import "TMLBasicUser.h"

NSString * const TMLUserUsernameKey = @"username";
NSString * const TMLUserEmailKey = @"email";
NSString * const TMLUserUserIDKey = @"id";
NSString * const TMLUserFirstNameKey = @"first_name";
NSString * const TMLUserLastNameKey = @"last_name";
NSString * const TMLUserDisplayNameKey = @"display_name";
NSString * const TMLUserMugshotKey = @"mugshot";
NSString * const TMLUserUUIDKey = @"uuid";

@implementation TMLBasicUser

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.username forKey:TMLUserUsernameKey];
    [aCoder encodeObject:self.firstName forKey:TMLUserFirstNameKey];
    [aCoder encodeObject:self.lastName forKey:TMLUserLastNameKey];
    [aCoder encodeObject:self.displayName forKey:TMLUserDisplayNameKey];
    
    [aCoder encodeInteger:self.userID forKey:TMLUserUserIDKey];
    [aCoder encodeObject:self.uuid forKey:TMLUserUUIDKey];
    
    [aCoder encodeObject:self.email forKey:TMLUserEmailKey];
    [aCoder encodeObject:[self.mugshotURL absoluteString] forKey:TMLUserMugshotKey];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.username = [aDecoder decodeObjectForKey:TMLUserUsernameKey];
    self.firstName = [aDecoder decodeObjectForKey:TMLUserFirstNameKey];
    self.lastName = [aDecoder decodeObjectForKey:TMLUserLastNameKey];
    self.displayName = [aDecoder decodeObjectForKey:TMLUserDisplayNameKey];
    
    self.userID = [aDecoder decodeIntegerForKey:TMLUserUserIDKey];
    self.uuid = [aDecoder decodeObjectForKey:TMLUserUUIDKey];
    
    self.email = [aDecoder decodeObjectForKey:TMLUserEmailKey];
    self.mugshotURL = [NSURL URLWithString:[aDecoder decodeObjectForKey:TMLUserMugshotKey]];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    else if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    else {
        TMLBasicUser *anotherUser = object;
        return (self.uuid == anotherUser.uuid || [self.uuid isEqualToString:anotherUser.uuid]);
    }
}

- (NSString *) description {
    NSString *shortName = self.displayName;
    NSInteger max = 24;
    if (shortName.length > max) {
        shortName = [[shortName substringToIndex:max-3] stringByAppendingString:@"..."];
    }
    return [NSString stringWithFormat:@"<%@:%@: %p>", [self class], shortName, self];
}

- (NSString *)initials {
    NSMutableString *string = [NSMutableString string];
    NSString *firstName = self.firstName;
    NSString *lastName = self.lastName;
    if (firstName.length > 0) {
        [string appendString:[[firstName substringToIndex:1] uppercaseString]];
    }
    if (lastName.length > 0) {
        [string appendString:[[lastName substringToIndex:1] uppercaseString]];
    }
    return [string copy];
}


@end
