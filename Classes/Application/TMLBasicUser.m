//
//  TMLBasicUser.m
//  
//
//  Created by Pasha on 5/4/16.
//
//

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
