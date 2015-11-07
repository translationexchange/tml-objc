//
//  TMLGlobals.m
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "TMLGlobals.h"

void TMLAbstractInvocation(SEL selector,id object) {
    [NSException raise:NSInvalidArgumentException
                format:@"[%@ %@] forwards to an abstract invocation",
     NSStringFromClass([object class]),
     NSStringFromSelector(selector)
     ];
}