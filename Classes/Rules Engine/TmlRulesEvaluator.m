/*
 *  Copyright (c) 2015 Translation Exchange, Inc. All rights reserved.
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

#import "TmlRulesEvaluator.h"

@interface TmlRulesEvaluator (Private)

- (NSObject *) applyFunction:(NSString *) name withArguments: (NSArray *) args;

- (BOOL) isNestedFunction: (NSString *) fn;

+ (NSDictionary *) defaultContext;

@end

@implementation TmlRulesEvaluator

@synthesize context, variables;

+ (NSDictionary *) defaultContext {
    NSDictionary *defaultCtx =
    @{
      // McCarthy's Elementary S-functions and Predicates
      @"label": ^(TmlRulesEvaluator *e, NSArray *args) {
          [e setVariable:[args objectAtIndex:1] forKey:[args objectAtIndex:0]];
          return [args objectAtIndex:1];
      },
    
      @"quote": ^(TmlRulesEvaluator *e, NSArray *args) {
          return [args objectAtIndex:0];
      },

      @"car": ^(TmlRulesEvaluator *e, NSArray *args) {
          return [[args objectAtIndex:0] objectAtIndex:1];
      },

      @"cdr": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSMutableArray *elements = [NSMutableArray arrayWithArray: [args objectAtIndex:0]];
          [elements removeObjectAtIndex:0];
          return elements;
      },

      @"cons": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSMutableArray *elements = [NSMutableArray arrayWithObject:[args objectAtIndex:0]];
          [elements addObjectsFromArray:[args objectAtIndex:1]];
          return elements;
      },
      
      @"eq": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *v1 = [NSString stringWithFormat:@"%@", [args objectAtIndex:0]];
          NSString *v2 = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          return [NSNumber numberWithBool: [v1 isEqual:v2]];
      },
      
      @"atom": ^(TmlRulesEvaluator *e, NSArray *args) {
          return ([[args objectAtIndex:0] isKindOfClass: NSArray.class] ? @NO : @YES);
      },

      @"cond": ^(TmlRulesEvaluator *e, NSArray *args) {
          if ([[e evaluateExpression: [args objectAtIndex:0]] isEqual: @YES]) {
              return [args objectAtIndex:1];
          } else {
              return [args objectAtIndex:2];
          }
      },
      
      // Tml Extensions
      @"=": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [e.context objectForKey:@"eq"];
          return fn(e, args);
      },
      
      @"!=": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [e.context objectForKey:@"eq"];
          return ([fn(e, args) isEqual:@YES] ? @NO : @YES);
      },
      
      @"<": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *v1 = [NSString stringWithFormat:@"%@", [args objectAtIndex:0]];
          NSString *v2 = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          return ([v1 doubleValue] < [v2 doubleValue] ? @YES : @NO);
      },
      
      @">": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *v1 = [NSString stringWithFormat:@"%@", [args objectAtIndex:0]];
          NSString *v2 = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          return ([v1 doubleValue] > [v2 doubleValue] ? @YES : @NO);
      },

      @"+": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *v1 = [NSString stringWithFormat:@"%@", [args objectAtIndex:0]];
          NSString *v2 = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          return [NSNumber numberWithDouble: ([v1 doubleValue] + [v2 doubleValue])];
      },
      
      @"-": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *v1 = [NSString stringWithFormat:@"%@", [args objectAtIndex:0]];
          NSString *v2 = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          return [NSNumber numberWithDouble: ([v1 doubleValue] - [v2 doubleValue])];
      },
      
      @"*": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *v1 = [NSString stringWithFormat:@"%@", [args objectAtIndex:0]];
          NSString *v2 = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          return [NSNumber numberWithDouble: ([v1 doubleValue] * [v2 doubleValue])];
      },

      @"/": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *v1 = [NSString stringWithFormat:@"%@", [args objectAtIndex:0]];
          NSString *v2 = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          return [NSNumber numberWithDouble: ([v1 doubleValue] / [v2 doubleValue])];
      },

      @"%": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *v1 = [NSString stringWithFormat:@"%@", [args objectAtIndex:0]];
          NSString *v2 = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          return [NSNumber numberWithInt: ([v1 intValue] % [v2 intValue])];
      },

      @"mod": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [e.context objectForKey:@"%"];
          return fn(e, args);
      },

      @"true": ^(TmlRulesEvaluator *e, NSArray *args) {
          return @YES;
      },

      @"false": ^(TmlRulesEvaluator *e, NSArray *args) {
          return @NO;
      },

      @"!": ^(TmlRulesEvaluator *e, NSArray *args) {
          return ([[args objectAtIndex:0] isEqual:@YES] ? @NO : @YES);
      },

      @"not": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [e.context objectForKey:@"!"];
          return fn(e, args);
      },

      @"&&": ^(TmlRulesEvaluator *e, NSArray *args) {
          for (NSObject *expr in args) {
            if ([[e evaluateExpression:expr] isEqual:@NO])
                return @NO;
          }
          return @YES;
      },

      @"and": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [e.context objectForKey:@"&&"];
          return fn(e, args);
      },
      
      @"||": ^(TmlRulesEvaluator *e, NSArray *args) {
          for (NSObject *expr in args) {
              if ([[e evaluateExpression:expr] isEqual:@YES])
                  return @YES;
          }
          return @NO;
      },
      
      @"or": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [e.context objectForKey:@"||"];
          return fn(e, args);
      },
      
      @"if": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [e.context objectForKey:@"cond"];
          return fn(e, args);
      },

      @"let": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [e.context objectForKey:@"label"];
          return fn(e, args);
      },

      @"date": ^(TmlRulesEvaluator *e, NSArray *args) {
          // TODO: finsih implementation
      },
      
      @"today": ^(TmlRulesEvaluator *e, NSArray *args) {
          return [NSDate date];
      },

      @"time": ^(TmlRulesEvaluator *e, NSArray *args) {
          // TODO: finsih implementation
      },

      @"now": ^(TmlRulesEvaluator *e, NSArray *args) {
          return [NSDate date];
      },
      
      @"append": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *str1 = [args objectAtIndex:0];
          NSString *str2 = [args objectAtIndex:1];
          return [str2 stringByAppendingString:str1];
      },

      @"prepend": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSString *str1 = [args objectAtIndex:0];
          NSString *str2 = [args objectAtIndex:1];
          return [str1 stringByAppendingString:str2];
      },
      
      @"match": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSRegularExpression *regex = [self.class regularExpressionWithPattern: [args objectAtIndex:0]];
          NSString *value = [NSString stringWithFormat:@"%@", [args objectAtIndex:1]];
          NSRange firstMatch = [regex rangeOfFirstMatchInString:value options: kNilOptions range:NSMakeRange(0, [value length])];

          if (firstMatch.location == NSNotFound) {
              return @NO;
          }
          return @YES;
      },
      
      @"replace": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSRegularExpression *regex = [self.class regularExpressionWithPattern: [args objectAtIndex:0]];
          NSString *replacement = [args objectAtIndex:1];
          NSString *value = [args objectAtIndex:2];
          return [regex stringByReplacingMatchesInString:value options:0 range:NSMakeRange(0, [value length]) withTemplate:replacement];
      },
      
      @"in": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSObject *obj = [args objectAtIndex:1];
          NSString *search = [NSString stringWithFormat:@"%@", obj];
          search = [search stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

          NSArray *values = [[args objectAtIndex:0] componentsSeparatedByString: @","];
          for (NSString *value in values) {
              NSString *val = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
           
              // TODO: add support for character ranges
              if ([val rangeOfString:@".."].location != NSNotFound) {
                  NSArray *bounds = [val componentsSeparatedByString: @".."];
                  int start = [[bounds objectAtIndex:0] intValue];
                  NSInteger length = [[bounds objectAtIndex:1] intValue] - start + 1;
                  NSRange range = NSMakeRange(start, length);
                  if (NSLocationInRange([search intValue], range)) {
                      return @YES;
                  }
              } else if ([val isEqual: search]) {
                  return @YES;
              }
          }
          return @NO;
      },
      
      @"within": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSArray *bounds = [[args objectAtIndex:0] componentsSeparatedByString: @".."];
          double value = [[args objectAtIndex:1] doubleValue];
          double left = [[bounds objectAtIndex:0] doubleValue];
          double right = [[bounds objectAtIndex:1] doubleValue];
          if (left <= value && value <= right)
              return @YES;
          return @NO;
      },
      
      
      @"count": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSArray *list;
          if ([[args objectAtIndex:0] isKindOfClass: NSString.class]) {
              list = (NSArray*) [e variableForKey:[args objectAtIndex:0]];
          } else {
              list = [args objectAtIndex:0];
          }
          
          return [NSNumber numberWithLong:[list count]];
      },
      
      @"all": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSArray *list;
          if ([[args objectAtIndex:0] isKindOfClass: NSString.class]) {
              list = (NSArray*) [e variableForKey:[args objectAtIndex:0]];
          } else {
              list = [args objectAtIndex:0];
          }
          if ([list count] == 0)
              return @NO;
          
          for (NSString *val in list) {
              if (![val isEqual: [args objectAtIndex:1]])
                  return @NO;
          }
          
          return @YES;
      },
      
      @"any": ^(TmlRulesEvaluator *e, NSArray *args) {
          NSArray *list;
          if ([[args objectAtIndex:0] isKindOfClass: NSString.class]) {
              list = (NSArray*) [e variableForKey:[args objectAtIndex:0]];
          } else {
              list = [args objectAtIndex:0];
          }
          if ([list count] == 0)
              return @NO;
          
          for (NSString *val in list) {
              if ([val isEqual: [args objectAtIndex:1]])
                  return @YES;
          }
          
          return @NO;
      }
      
    };
    
    return defaultCtx;
}

+ (NSRegularExpression *) regularExpressionWithPattern: (NSString *) pattern {
    if ([pattern hasPrefix:@"/"]) {
        pattern = [pattern substringWithRange: NSMakeRange(1, [pattern length]-1)];
    }
    if ([pattern hasSuffix:@"/"]) {
        pattern = [pattern substringWithRange: NSMakeRange(0, [pattern length]-1)];
    } else if ([pattern hasSuffix:@"/i"]) {
        pattern = [pattern substringWithRange: NSMakeRange(0, [pattern length]-2)];
    }
    
//    if ([[pattern substringToIndex:1] isEqualToString:@"/"]) {
//        pattern = [pattern substringWithRange: NSMakeRange(1, [pattern length]-2)];
//    }
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern: pattern
                                  options: NSRegularExpressionCaseInsensitive
                                  error: &error];
    // TODO: check for errors
    return regex;
}

- (id) init {
    if (self = [super init]) {
        self.context = [NSMutableDictionary dictionaryWithDictionary: [self.class defaultContext]];
        self.variables = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (id) initWithVariables: (NSDictionary *) vars {
    return [self initWithVariables:vars andContext:@{}];
}

- (id) initWithVariables: (NSDictionary *) vars andContext: (NSDictionary *) ctx {
    if (self = [self init]) {
        [self.variables addEntriesFromDictionary:vars];
        [self.context addEntriesFromDictionary:ctx];
    }
    
    return self;
}

- (void) setVariable: (NSObject *) var forKey: (NSString *) key {
    [self.variables setObject:var forKey:key];
}

- (NSObject *) variableForKey: (NSString *) key {
    return [self.variables objectForKey:key];
}

- (BOOL) isNestedFunction: (NSString *) fn {
    NSArray *nested = @[@"quote", @"car", @"cdr", @"cond", @"if",
                        @"&&", @"||", @"and", @"or", @"true",
                        @"false", @"let", @"count", @"all", @"any"];
    return [nested containsObject:fn];
}

- (void) reset {
    self.variables = [NSMutableDictionary dictionary];
}

- (NSObject *) applyFunction:(NSString *) name withArguments: (NSArray *) args {
    if ([self variableForKey:name] != nil)
        return [self variableForKey:name];
    
    NSObject *(^fn)(TmlRulesEvaluator *, NSArray *) = [self.context objectForKey:name];
    return fn(self, args);
}

- (NSObject *) evaluateExpression:(NSObject *) expr {
    if ([expr isKindOfClass:NSString.class]) {
        if ([self variableForKey: (NSString *) expr] != nil)
            return [self variableForKey: (NSString *) expr];
        return expr;
    }

    if (![expr isKindOfClass:NSArray.class]) {
        return expr;
    }
    
    NSMutableArray *args = [NSMutableArray arrayWithArray: (NSArray *) expr];
    NSString *fn = [args objectAtIndex:0];
    [args removeObjectAtIndex: 0];
    
    if (![self isNestedFunction:fn]) {
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:[args count]];
        [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [results addObject: [self evaluateExpression:(NSObject *) obj]];
        }];
        args = results;
    }
    
    return [self applyFunction:fn withArguments:args];
}

@end
