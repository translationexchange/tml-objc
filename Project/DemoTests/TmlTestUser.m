//
//  TmlTestUser.m
//  Tml
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import "TmlTestUser.h"

@implementation TmlTestUser

@synthesize firstName, lastName, gender, age;

- (id) initWithFirstName: (NSString *) fName {
    return [self initWithFirstName:fName andLastName:@""];
}

- (id) initWithFirstName: (NSString *) fName andGender: (NSString *) gen {
    return [self initWithFirstName:fName andLastName:@"" andGender:gen];
}

- (id) initWithFirstName: (NSString *) fName andLastName: (NSString *) lName {
    return [self initWithFirstName:fName andLastName:lName andGender:@"male"];
}

- (id) initWithFirstName: (NSString *) fName andLastName: (NSString *) lName andGender: (NSString *) gen {
    if (self = [super init]) {
        self.firstName = fName;
        self.lastName = lName;
        self.gender = gen;
        self.age = [NSNumber numberWithInt:36];
    }
    return self;
}

- (NSString *) name {
    NSMutableString *name = [NSMutableString stringWithString:firstName];
    if ([self.lastName length] > 0) {
        [name appendFormat:@" %@", self.lastName];
    }
    return name;
}

- (NSString *) description {
    return [self name];
}
@end
