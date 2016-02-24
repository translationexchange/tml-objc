//
//  TMLTranslatorUser.m
//  TMLKit
//
//  Created by Pasha on 2/19/16.
//  Copyright © 2016 Translation Exchange. All rights reserved.
//

#import "TMLTranslator.h"

NSString * const TMLTranslatorIDKey = @"id";
NSString * const TMLTranslatorFirstNameKey = @"first_name";
NSString * const TMLTranslatorLastNameKey = @"last_name";
NSString * const TMLTranslatorDisplayNameKey = @"display_name";
NSString * const TMLTranslatorMugshotKey = @"mugshot";
NSString * const TMLTranslatorInlineModeKey = @"inline_mode";

@implementation TMLTranslator

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userID forKey:TMLTranslatorIDKey];
    [aCoder encodeObject:self.firstName forKey:TMLTranslatorFirstNameKey];
    [aCoder encodeObject:self.lastName forKey:TMLTranslatorLastNameKey];
    [aCoder encodeObject:self.displayName forKey:TMLTranslatorDisplayNameKey];
    [aCoder encodeObject:[self.mugshotURL absoluteString] forKey:TMLTranslatorMugshotKey];
    [aCoder encodeBool:self.inlineTranslationAllowed forKey:TMLTranslatorInlineModeKey];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.userID = [aDecoder decodeObjectForKey:TMLTranslatorIDKey];
    self.firstName = [aDecoder decodeObjectForKey:TMLTranslatorFirstNameKey];
    self.lastName = [aDecoder decodeObjectForKey:TMLTranslatorLastNameKey];
    self.displayName = [aDecoder decodeObjectForKey:TMLTranslatorDisplayNameKey];
    self.mugshotURL = [NSURL URLWithString:[aDecoder decodeObjectForKey:TMLTranslatorMugshotKey]];
    self.inlineTranslationAllowed = [aDecoder decodeBoolForKey:TMLTranslatorInlineModeKey];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    else if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    else {
        return [self isEqualToTranslator:(TMLTranslator *)object];
    }
}

- (BOOL)isEqualToTranslator:(TMLTranslator *)translator {
    return (self.userID == translator.userID
            || [self.userID isEqualToString:translator.userID]);
}

- (NSString *) description {
    NSString *shortName = self.displayName;
    NSInteger max = 24;
    if (shortName.length > max) {
        shortName = [[shortName substringToIndex:max-3] stringByAppendingString:@"..."];
    }
    return [NSString stringWithFormat:@"<%@:%@: %p>", [self class], shortName, self];
}

#pragma mark -

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
