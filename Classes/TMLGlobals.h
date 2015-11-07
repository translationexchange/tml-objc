//
//  TMLGlobals.h
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TMLRaiseAbstractInvocation() TMLAbstractInvocation(_cmd, self)

void TMLAbstractInvocation(SEL selector,id object);