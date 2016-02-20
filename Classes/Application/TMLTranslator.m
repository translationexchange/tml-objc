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
NSString * const TMLTranslatorMugshotKey = @"mugshot";
NSString * const TMLTranslatorInlineModeKey = @"inline_mode";

@implementation TMLTranslator

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userID forKey:TMLTranslatorIDKey];
    [aCoder encodeObject:self.firstName forKey:TMLTranslatorFirstNameKey];
    [aCoder encodeObject:[self.mugshotURL absoluteString] forKey:TMLTranslatorMugshotKey];
    [aCoder encodeBool:self.inlineTranslationAllowed forKey:TMLTranslatorInlineModeKey];
}

- (void)decodeWithCoder:(NSCoder *)aDecoder {
    self.userID = [aDecoder decodeObjectForKey:TMLTranslatorIDKey];
    self.firstName = [aDecoder decodeObjectForKey:TMLTranslatorFirstNameKey];
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
    NSString *shortName = self.firstName;
    NSInteger max = 24;
    if (shortName.length > max) {
        shortName = [[shortName substringToIndex:max-3] stringByAppendingString:@"..."];
    }
    return [NSString stringWithFormat:@"<%@:%@: %p>", [self class], shortName, self];
}

@end
