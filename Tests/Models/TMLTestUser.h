//
//  TMLTestUser.h
//  TML
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

@interface TMLTestUser : NSObject

@property (nonatomic, strong) NSString *firstName;

@property (nonatomic, strong) NSString *lastName;

@property (nonatomic, strong) NSString *gender;

@property (nonatomic, strong) NSNumber *age;

- (id) initWithFirstName: (NSString *) fName;

- (id) initWithFirstName: (NSString *) fName andGender: (NSString *) gen;

- (id) initWithFirstName: (NSString *) fName andLastName: (NSString *) lName;

- (id) initWithFirstName: (NSString *) fName andLastName: (NSString *) lName andGender: (NSString *) gen;

- (NSString *) name;

@end
