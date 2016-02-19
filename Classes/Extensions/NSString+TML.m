//
//  NSString+TML.m
//  Demo
//
//  Created by Pasha on 10/29/15.
//  Copyright © 2015 TMLHub Inc. All rights reserved.
//

#import "NSString+TML.h"
#import "TMLDecorationTokenizer.h"
#import "TMLDataTokenizer.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>

@implementation NSString (TML)

- (NSString *)tmlTranslationBundleVersionFromPath {
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]+"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:&error];
        if (error != nil) {
            TMLError(@"Error constructing regexp for determinging version of local localization bundles: %@", error);
        }
    });
    
    if (regex == nil) {
        return nil;
    }
    
    NSString *filename = [[self lastPathComponent] stringByDeletingPathExtension];
    NSString *version = [regex stringByReplacingMatchesInString:filename
                                                        options:NSMatchingReportCompletion
                                                          range:NSMakeRange(0, filename.length)
                                                   withTemplate:@""];
    return version;
}

- (NSComparisonResult)compareToTMLTranslationBundleVersion:(NSString *)version {
    NSInteger ours = [self integerValue];
    NSInteger their = (version == nil) ? 0 : [version integerValue];
    if (ours < their) {
        return NSOrderedAscending;
    }
    else if (ours > their) {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

- (NSString *)tmlCamelCaseString {
    static NSCharacterSet *charSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mutableCharSet = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
        [mutableCharSet addCharactersInString:@"_"];
        charSet = [mutableCharSet copy];
    });
    NSArray *parts = [self componentsSeparatedByCharactersInSet:charSet];
    NSMutableString *result = [NSMutableString string];
    for (NSUInteger i=0; i<parts.count; i++) {
        if (i == 0) {
            [result appendString:parts[i]];
        }
        else {
            [result appendString:[parts[i] capitalizedString]];
        }
    }
    return result;
}

- (NSString *)tmlSnakeCaseString {
    NSCharacterSet *whiteSpaceCharSet = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet *upperCaseCharSet = [NSCharacterSet uppercaseLetterCharacterSet];
    NSMutableCharacterSet *lowerNumCharSet = [[NSCharacterSet lowercaseLetterCharacterSet] mutableCopy];
    [lowerNumCharSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.caseSensitive = YES;
    NSString *buffer = nil;
    NSMutableString *result = [NSMutableString string];
    while ([scanner isAtEnd] == NO) {
        if ([scanner scanCharactersFromSet:whiteSpaceCharSet intoString:&buffer] == YES) {
            [result appendString:@"_"];
        }
        if ([scanner scanCharactersFromSet:upperCaseCharSet intoString:&buffer] == YES) {
            if (buffer.length == 1 || [scanner isAtEnd] == YES) {
                [result appendString:[NSString stringWithFormat:@"_%@", [buffer lowercaseString]]];
            }
            else {
                [result appendString:[NSString stringWithFormat:@"_%@_%@", [[buffer substringWithRange:NSMakeRange(0, buffer.length - 1)] lowercaseString], [[buffer substringFromIndex:buffer.length-1] lowercaseString]]];
            }
        }
        if ([scanner scanCharactersFromSet:lowerNumCharSet intoString:&buffer] == YES) {
            [result appendString:buffer];
        }
    }
    return result;
}

- (BOOL)tmlContainsDataTokens {
    return [TMLDataTokenizer stringContainsApplicableTokens:self];
}

- (BOOL)tmlContainsDecoratedTokens {
    return [TMLDecorationTokenizer stringContainsApplicableTokens:self];
}

- (NSArray *)tmlDataTokens {
    TMLDataTokenizer *tokenizer = [[TMLDataTokenizer alloc] initWithLabel:self];
    return tokenizer.tokenNames;
}

- (NSArray *)tmlDecoratedTokens {
    TMLDecorationTokenizer *tokenizer = [[TMLDecorationTokenizer alloc] initWithLabel:self];
    return tokenizer.tokenNames;
}

#pragma mark - Utils

- (NSString *)tmlMD5 {
    NSString *result = objc_getAssociatedObject(self, "_tmlMD5");
    if (result == nil) {
        const char *cStr = [self UTF8String];
        unsigned char digest[16];
        CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
        
        NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
        for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [output appendFormat:@"%02x", digest[i]];
        }
        result = [output copy];
        objc_setAssociatedObject(self, "_tmlMD5", result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return result;
}

@end
