//
//  TMLBasicUser.h
//  
//
//  Created by Pasha on 5/4/16.
//
//

#import "TMLModel.h"

extern NSString * const TMLUserUsernameKey;
extern NSString * const TMLUserFirstNameKey;
extern NSString * const TMLUserLastNameKey;
extern NSString * const TMLUserDisplayNameKey;
extern NSString * const TMLUserEmailKey;
extern NSString * const TMLUserMugshotKey;
extern NSString * const TMLUserUUIDKey;
extern NSString * const TMLUserUserIDKey;

@interface TMLBasicUser : TMLModel

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *displayName;
@property (readonly, nonatomic) NSString *initials;

@property (strong, nonatomic) NSString *uuid;
@property (assign, nonatomic) NSInteger userID;

@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSURL *mugshotURL;


@end
