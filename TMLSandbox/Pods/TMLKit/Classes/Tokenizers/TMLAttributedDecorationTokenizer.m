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

#import "MPColorTools.h"
#import "TML.h"
#import "TMLAttributedDecorationTokenizer.h"
#import "TMLConfiguration.h"

@interface TMLAttributedDecorationTokenizer ()

@end

@implementation TMLAttributedDecorationTokenizer

+ (void)addStroke:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    NSDictionary *styles = ((NSDictionary *) data);

    if ([styles objectForKey:@"color"]) {
        [attributedString addAttribute: NSStrokeColorAttributeName value: [self colorFromData:[styles objectForKey:@"color"]] range:range];
    }

    if ([styles objectForKey:@"width"]) {
        float width = [[styles objectForKey:@"width"] floatValue];
        [attributedString addAttribute: NSStrokeWidthAttributeName value: @(width) range:range];
    }
}

+ (void)addShadow:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    NSDictionary *styles = ((NSDictionary *) data);

    NSShadow *shadow = [[NSShadow alloc] init];
    if ([styles objectForKey:@"offset"]) {
        NSArray *parts = [[styles objectForKey:@"offset"] componentsSeparatedByString:@","];
        if ([parts count] == 2)
            shadow.shadowOffset = CGSizeMake([[parts objectAtIndex:0] floatValue], [[parts objectAtIndex:1] floatValue]);
    }
    
    if ([styles objectForKey:@"radius"]) {
        shadow.shadowBlurRadius = [[styles objectForKey:@"radius"] floatValue];
    }

    if ([styles objectForKey:@"color"]) {
        shadow.shadowColor = [self colorFromData:[styles objectForKey:@"color"]];
    }
    
    [attributedString addAttribute: NSShadowAttributeName value: shadow range:range];
}

+ (void)addTextEffects:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    NSString *style = ((NSString *) data);
    if ([style isEqualToString:@"letterpress"]) {
        [attributedString addAttribute: NSTextEffectAttributeName value: NSTextEffectLetterpressStyle range:range];
    }
}

+ (void)addParagraphStyles:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    NSDictionary *styles = ((NSDictionary *) data);
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    if ([styles objectForKey:@"line-spacing"])
        paragraphStyle.lineSpacing = [[styles objectForKey:@"line-spacing"] floatValue];

    if ([styles objectForKey:@"paragraph-spacing"])
        paragraphStyle.paragraphSpacing = [[styles objectForKey:@"paragraph-spacing"] floatValue];

    if ([styles objectForKey:@"alignment"]) {
        NSString *alignment = [styles objectForKey:@"alignment"];
        if ([alignment isEqualToString:@"left"])
            paragraphStyle.alignment = NSTextAlignmentLeft;
        else if ([alignment isEqualToString:@"right"])
            paragraphStyle.alignment = NSTextAlignmentRight;
        else if ([alignment isEqualToString:@"center"])
            paragraphStyle.alignment = NSTextAlignmentCenter;
        else if ([alignment isEqualToString:@"justified"])
            paragraphStyle.alignment = NSTextAlignmentJustified;
        else if ([alignment isEqualToString:@"natural"])
            paragraphStyle.alignment = NSTextAlignmentNatural;
    }
    
    if ([styles objectForKey:@"first-line-head-indent"])
        paragraphStyle.firstLineHeadIndent = [[styles objectForKey:@"first-line-head-indent"] floatValue];

    if ([styles objectForKey:@"head-indent"])
        paragraphStyle.headIndent = [[styles objectForKey:@"head-indent"] floatValue];

    if ([styles objectForKey:@"tail-indent"])
        paragraphStyle.tailIndent = [[styles objectForKey:@"tail-indent"] floatValue];

    if ([styles objectForKey:@"line-breaking-mode"]) {
        NSString *mode = (NSString *) [styles objectForKey:@"line-breaking-mode"];
        if ([mode isEqualToString:@"word"])
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        else if ([mode isEqualToString:@"char"])
            paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        else if ([mode isEqualToString:@"clipping"])
            paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        else if ([mode isEqualToString:@"truncate-head"])
            paragraphStyle.lineBreakMode = NSLineBreakByTruncatingHead;
        else if ([mode isEqualToString:@"truncate-tail"])
            paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        else if ([mode isEqualToString:@"truncate-middle"])
            paragraphStyle.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }

    if ([styles objectForKey:@"minimum-line-height"])
        paragraphStyle.minimumLineHeight = [[styles objectForKey:@"minimum-line-height"] floatValue];
    
    if ([styles objectForKey:@"maximum-line-height"])
        paragraphStyle.maximumLineHeight = [[styles objectForKey:@"maximum-line-height"] floatValue];
    
    if ([styles objectForKey:@"writing-direction"]) {
        NSString *dir = (NSString *) [styles objectForKey:@"writing-direction"];
        if ([dir isEqualToString:@"natural"])
            paragraphStyle.baseWritingDirection = NSWritingDirectionNatural;
        else if ([dir isEqualToString:@"ltr"])
            paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
        else if ([dir isEqualToString:@"rtl"])
            paragraphStyle.baseWritingDirection = NSWritingDirectionRightToLeft;
    }

    if ([styles objectForKey:@"line-height-multiple"])
        paragraphStyle.lineHeightMultiple = [[styles objectForKey:@"line-height-multiple"] floatValue];

    if ([styles objectForKey:@"line-height-multiple"])
        paragraphStyle.paragraphSpacingBefore = [[styles objectForKey:@"line-height-multiple"] floatValue];
    
    [attributedString addAttribute: NSParagraphStyleAttributeName value:paragraphStyle range:range];
}

+ (void)addStrikeThrough:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    if ([data isKindOfClass:NSString.class]) {
        NSString *thickness = ((NSString *) data);
        [attributedString addAttribute: NSStrikethroughStyleAttributeName value:@([thickness intValue]) range:range];
        return;
    }
    
    if ([data isKindOfClass:NSDictionary.class]) {
        NSDictionary *options = (NSDictionary *) data;
        if ([options objectForKey:@"thickness"]) {
            [attributedString addAttribute: NSStrikethroughStyleAttributeName value: @([[options objectForKey:@"thickness"] intValue]) range:range];
        }
        NSString *color = [options objectForKey:@"color"];
        if (color) {
            [attributedString addAttribute: NSStrikethroughColorAttributeName value: [self colorFromData:color] range:range];
        }
    }
}

+ (NSUnderlineStyle) underlineOptionsFromData: (NSObject *)data {
    NSUnderlineStyle opts = NSUnderlineStyleNone;
    
    if ([data isKindOfClass:NSString.class]) {
        if ([data isEqual:@"none"]) {
            opts = NSUnderlineStyleNone;
        } else if ([data isEqual:@"single"]) {
            opts = NSUnderlineStyleSingle;
        } else if ([data isEqual:@"double"]) {
            opts = NSUnderlineStyleDouble;
        } else if ([data isEqual:@"thick"]) {
            opts = NSUnderlineStyleThick;
        }
        return opts;
    }
    
    if ([data isKindOfClass:NSDictionary.class]) {
        NSDictionary *options = (NSDictionary *) data;
        
        NSString *style = [options objectForKey:@"style"];
        if (style == nil) style = @"single";
        NSString *pattern = [options objectForKey:@"pattern"];
        if (pattern == nil) pattern = @"solid";
        NSString *byword = [options objectForKey:@"byword"];
        if (byword == nil) byword = @"false";
        
        if ([style isEqual:@"none"]) {
            opts = NSUnderlineStyleNone;
        } else if ([style isEqual:@"single"]) {
            opts = NSUnderlineStyleSingle;
        } else if ([style isEqual:@"double"]) {
            opts = NSUnderlineStyleDouble;
        } else if ([style isEqual:@"thick"]) {
            opts = NSUnderlineStyleThick;
        }
        
        if ([pattern isEqual:@"solid"]) {
            opts = opts | NSUnderlinePatternSolid;
        } else if ([pattern isEqual:@"dot"]) {
            opts = opts | NSUnderlinePatternDot;
        } else if ([pattern isEqual:@"dash"]) {
            opts = opts | NSUnderlinePatternDash;
        } else if ([pattern isEqual:@"dashdot"]) {
            opts = opts | NSUnderlinePatternDashDot;
        } else if ([pattern isEqual:@"dashdotdot"]) {
            opts = opts | NSUnderlinePatternDashDotDot;
        } else if ([pattern isEqual:@"dashdotdot"]) {
            opts = opts | NSUnderlinePatternDashDotDot;
        }
        
        if ([byword isEqual:@"true"]) {
            opts = opts | NSUnderlineByWord;
        }
        return opts;
    }
    
    return opts;
}

+ (void)addUnderline:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    [attributedString addAttribute: NSUnderlineStyleAttributeName value:@([self underlineOptionsFromData:data]) range:range];

    if ([data isKindOfClass:NSDictionary.class]) {
        NSDictionary *options = (NSDictionary *) data;
        NSString *color = [options objectForKey:@"color"];
        if (color) {
            [attributedString addAttribute: NSUnderlineColorAttributeName value: [self colorFromData:color] range:range];
        }
    }
}

/**
 * @{@"font": [UIFont fontWithName....]}
 * @{@"font": @{@"name": @"Arial", @"size": @8}}
 * @{@"font": @"Arial, 8"}
 */

+ (UIFont *) fontFromData: (NSObject *)data {
    if ([data isKindOfClass: UIFont.class]) {
        return (UIFont *) data;
    }
    
    if ([data isKindOfClass: NSDictionary.class]) {
        NSDictionary *settings = (NSDictionary *) data;
        NSString *fontName = [settings objectForKey:@"name"];
        NSNumber *fontSize = [settings objectForKey:@"size"];
        
        if ([fontName isEqualToString:@"system"]) {
            if ([[settings objectForKey:@"type"] isEqualToString:@"bold"]) {
                return [UIFont boldSystemFontOfSize:[fontSize floatValue]];
            }
            if ([[settings objectForKey:@"type"] isEqualToString:@"italic"]) {
                return [UIFont italicSystemFontOfSize:[fontSize floatValue]];
            }
            return [UIFont systemFontOfSize:[fontSize floatValue]];
        }

        return [UIFont fontWithName:fontName size:[fontSize floatValue]];
    }
    
    if ([data isKindOfClass: NSString.class]) {
        NSArray *elements = [((NSString *) data) componentsSeparatedByString:@","];
        if ([elements count] < 2) return nil;
        NSString *fontName = [elements objectAtIndex:0];
        float fontSize = [[elements objectAtIndex:1] floatValue];
        return [UIFont fontWithName:fontName size:fontSize];
    }
    
    return nil;
}

+ (void)addFont:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    UIFont *font = [self fontFromData:data];
    if (font == nil) return;
    [attributedString addAttribute: NSFontAttributeName value:font range:range];
}

/**
 * @{@"color": [UIColor ...]}
 * @{@"color": @{@"red": @111, @"green": @8 ...}}
 * @{@"color": @"fbc"}
 */
+ (UIColor *) colorFromData: (NSObject *)data {
    if ([data isKindOfClass: UIColor.class]) {
        return (UIColor *) data;
    }
    
    if ([data isKindOfClass: NSDictionary.class]) {
        NSDictionary *settings = (NSDictionary *) data;
         UIColor *color = [UIColor colorWithRed:[[settings objectForKey:@"red"] floatValue]
                                green:[[settings objectForKey:@"green"] floatValue]
                                 blue:[[settings objectForKey:@"blue"] floatValue]
                                alpha:[[settings objectForKey:@"alpha"] floatValue]];
        
        return color;
    }
    
    if ([data isKindOfClass: NSString.class]) {
        NSString *name = ((NSString *) data);
        
        if ([name isEqualToString:@"black"]) return [UIColor blackColor];
        if ([name isEqualToString:@"dark-gray"]) return [UIColor darkGrayColor];
        if ([name isEqualToString:@"light-gray"]) return [UIColor lightGrayColor];
        if ([name isEqualToString:@"white"]) return [UIColor whiteColor];
        if ([name isEqualToString:@"gray"]) return [UIColor grayColor];
        if ([name isEqualToString:@"red"]) return [UIColor redColor];
        if ([name isEqualToString:@"green"]) return [UIColor greenColor];
        if ([name isEqualToString:@"blue"]) return [UIColor blueColor];
        if ([name isEqualToString:@"cyan"]) return [UIColor cyanColor];
        if ([name isEqualToString:@"yellow"]) return [UIColor yellowColor];
        if ([name isEqualToString:@"magenta"]) return [UIColor magentaColor];
        if ([name isEqualToString:@"orange"]) return [UIColor orangeColor];
        if ([name isEqualToString:@"purple"]) return [UIColor purpleColor];
        if ([name isEqualToString:@"brown"]) return [UIColor brownColor];
        if ([name isEqualToString:@"clear"]) return [UIColor clearColor];
        
        return MP_HEX_RGB(name);
    }
    
    return nil;
}

+ (void)addColor:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    [attributedString addAttribute: NSForegroundColorAttributeName value:[self colorFromData:data] range:range];
}

+ (void)addBackgroundColor:(NSObject *)data toRange: (NSRange) range inAttributedString: (NSMutableAttributedString *) attributedString {
    [attributedString addAttribute: NSBackgroundColorAttributeName value:[self colorFromData:data] range:range];
}

- (void) applyStyles:(NSDictionary *)styles
            toRanges:(NSArray *)ranges
  inAttributedString:(NSMutableAttributedString *)attributedString
{
    for (NSString *styleName in [styles allKeys]) {
        NSObject *styleValue = [styles objectForKey:styleName];
        
        for (NSDictionary *rangeData in ranges) {
            NSRange range = NSMakeRange([[rangeData objectForKey:@"location"] intValue], [[rangeData objectForKey:@"length"] intValue]);

            if ([styleName isEqualToString:@"attributes"]) {
                NSDictionary *attrs = (NSDictionary *) styleValue;
                [attributedString addAttributes:attrs range:range];
                
            } else if ([styleName isEqualToString:@"font"]) {
                [self.class addFont: styleValue toRange: range inAttributedString: attributedString];
            } else if ([styleName isEqualToString:@"color"]) {
                [self.class addColor: styleValue toRange: range inAttributedString: attributedString];
            } else if ([styleName isEqualToString:@"background-color"]) {
                [self.class addBackgroundColor: styleValue toRange: range inAttributedString: attributedString];
            } else if ([styleName isEqualToString:@"underline"]) {
                [self.class addUnderline: styleValue toRange: range inAttributedString: attributedString];
            } else if ([styleName isEqualToString:@"strike"]) {
                [self.class addStrikeThrough: styleValue toRange: range inAttributedString: attributedString];
            } else if ([styleName isEqualToString:@"paragraph"]) {
                [self.class addParagraphStyles: styleValue toRange: range inAttributedString: attributedString];
            } else if ([styleName isEqualToString:@"effects"]) {
                [self.class addTextEffects: styleValue toRange: range inAttributedString: attributedString];
            } else if ([styleName isEqualToString:@"shadow"]) {
                [self.class addShadow: styleValue toRange: range inAttributedString: attributedString];
            } else if ([styleName isEqualToString:@"stroke"]) {
                [self.class addStroke: styleValue toRange: range inAttributedString: attributedString];
            }
            
        }
        
    }
}

- (NSString *) applyToken: (NSString *) token toValue: (NSString *) value {
    return value;
}

- (NSString *) evaluate: (NSObject *) expr location: (int) location {
    if (![expr isKindOfClass:NSArray.class])
        return (NSString *) expr;
    
    NSMutableArray *args = [NSMutableArray arrayWithArray:(NSArray *) expr];
    NSString *token = (NSString *) [args objectAtIndex:0];
    [args removeObjectAtIndex:0];

    NSMutableArray *attributeSet = [self.attributes objectForKey:token];
    if (attributeSet == nil) {
        attributeSet = [NSMutableArray array];
        [self.attributes setObject:attributeSet forKey:token];
    }
    
    NSMutableDictionary *attribute = [NSMutableDictionary dictionary];
    [attribute setObject:[NSNumber numberWithInteger:location] forKey:@"location"];
    
    NSMutableArray *processedValues = [NSMutableArray array];
    for (NSObject *arg in args) {
        NSString *value = (NSString *) [self evaluate:arg location: location];
        location += [value length];
        [processedValues addObject:value];
    }

    NSString *value = [processedValues componentsJoinedByString:@""];
    
    [attribute setObject:[NSNumber numberWithInteger:[value length]] forKey:@"length"];
    [attributeSet addObject:attribute];
    
    return [self applyToken:token toValue:value];
}

- (NSObject *) substituteTokensInLabelUsingData:(NSDictionary *)newTokensData {
    self.tokensData = newTokensData;
    self.attributes = [NSMutableDictionary dictionary];
    NSString *result = [self evaluate: self.expression location:0];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:result];
    
    for (NSString *tokenName in self.tokenNames) {
        if (![self isTokenAllowed:tokenName]) continue;
        
        NSDictionary *styles = [self.tokensData objectForKey:tokenName];
        if (styles == nil) {
            styles = [[[TML sharedInstance] configuration] defaultTokenValueForName:tokenName
                                                                               type:TMLDecorationTokenType
                                                                             format:TMLAttributedTokenFormat];
            if (styles == nil) continue;
        }
        
        NSArray *ranges = [self.attributes objectForKey:tokenName];
        if (ranges == nil) {
            continue;
        }
        
        [self applyStyles: styles toRanges: ranges inAttributedString: attributedString];
    }
    
    return attributedString;
}


@end