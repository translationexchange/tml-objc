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

#import "DecorationTokensDemoViewController.h"
#import "TMLSampleTableViewCell.h"

@interface DecorationTokensDemoViewController ()

@end

@implementation DecorationTokensDemoViewController

- (void) prepareSamples {
    [TML configure:^(TMLConfiguration *config) {
        [config setDefaultTokenValue:@{@"font": @{@"name": @"ChalkboardSE-Bold", @"size": @14}} forName:@"font1" type:TMLDecorationTokenType format:TMLAttributedTokenFormat];
        [config setDefaultTokenValue:@{@"font": [UIFont fontWithName:@"ChalkboardSE-Bold" size:14]} forName:@"font2" type:TMLDecorationTokenType format:TMLAttributedTokenFormat];
        [config setDefaultTokenValue:@{@"font": @{@"name": @"system", @"size": @14, @"type": @"bold"}} forName:@"bold" type:TMLDecorationTokenType format:TMLAttributedTokenFormat];
        [config setDefaultTokenValue:@{@"font": @{@"name": @"system", @"size": @14, @"type": @"italic"}} forName:@"italic" type:TMLDecorationTokenType format:TMLAttributedTokenFormat];
        [config setDefaultTokenValue:@{@"color": @"red"} forName:@"red" type:TMLDecorationTokenType format:TMLAttributedTokenFormat];
        [config setDefaultTokenValue:@{@"color": [UIColor greenColor]} forName:@"green" type:TMLDecorationTokenType format:TMLAttributedTokenFormat];
    }];
    
    self.items = @[
                   @{
                       @"title": @"Fonts",
                       @"items": @[
                               @{
                                   @"tml": @"[font1: Adjust fonts] using an attribute dictionary.",
                                   @"tokens": @{@"font1": @{@"font": @{@"name": @"ChalkboardSE-Bold", @"size": @14}}},
                                },
                               @{
                                   @"tml": @"Adjust fonts using the [font2: UIFont class].",
                                   @"tokens": @{@"font2": @{@"font": [UIFont fontWithName:@"ChalkboardSE-Bold" size:14]}},
                                   @"tokens_desc": @"{'font2': {'font': [UIFont fontWithName:@\"ChalkboardSE-Bold\" size:14]}",
                                },
                               @{
                                   @"tml": @"System [bold: bold font] followed by [italic: italic font].",
                                   @"tokens": @{
                                           @"bold": @{@"font": @{@"name": @"system", @"size": @14, @"type": @"bold"}},
                                           @"italic": @{@"font": @{@"name": @"system", @"size": @14, @"type": @"italic"}}
                                   }
                                }
                            ]
                       },
                   @{
                       @"title": @"Colors",
                       @"items": @[
                               @{
                                   @"tml": @"[red: Color] can be changed using a dictionary.",
                                   @"tokens": @{@"color": @"red"}
                                },
                               @{
                                   @"tml": @"Color [green: can also be changed] using a UIColor class.",
                                   @"tokens": @{@"color": [UIColor greenColor]},
                                   @"tokens_desc": @"{'green: {'color': [UIColor greenColor]}"
                                },
                               @{
                                   @"tml": @"You can even [external: overlap colors and [internal: use RGB] color scheme].",
                                   @"tokens": @{@"external": @{@"color": [UIColor grayColor]},
                                                @"internal": @{@"color": @{@"red": @0.5, @"green": @0.2, @"blue": @0.7, @"alpha": @1}}},
                                   @"tokens_desc": @"{'external: {'color': [UIColor grayColor]}, 'internal': {'color': {'red': 0.5, 'green': 0.2, 'blue': 0.7, 'alpha': 1}}}",
                                },
                               @{
                                   @"tml": @"[purple: Background color] can also be changed using the same methods.",
                                   @"tokens": @{@"purple": @{@"background-color": @"purple", @"color": @"white"}},
                                },
                               @{
                                   @"tml": @"You can [font1: mix fonts [font2: and colors] any way] you like.",
                                   @"tokens": @{
                                       @"font1": @{@"color": [UIColor grayColor], @"font": [UIFont fontWithName:@"ChalkboardSE-Bold" size:14]},
                                       @"font2": @{@"background-color": @"light-gray", @"color": @{@"red": @0.5, @"green": @0.2, @"blue": @0.7, @"alpha": @1}}
                                   },
                                   @"tokens_desc": @"{'external: {'color': [UIColor grayColor], 'font': [UIFont fontWithName:@\"ChalkboardSE-Bold\" size:14]}, 'internal': {'color': {'red': 0.5, 'green': 0.2, 'blue': 0.7, 'alpha': 1}}}",
                                   },
                               ]
                       },
                   
                   @{
                       @"title": @"Underline",
                       @"items": @[
                               @{
                                   @"tml": @"You can [under: underline any part] of text.",
                                   @"tokens": @{@"under": @{@"underline": @"single"}}
                                },
                               @{
                                   @"tml": @"You can even indicate [under: the thickness and pattern] of the line.",
                                   @"tokens": @{
                                        @"under": @{@"underline": @{@"style": @"thick", @"pattern": @"dot", @"byword": @"true", @"color": @"blue"}}
                                    },
                                },
                               ]
                       },
                   @{
                       @"title": @"Strike-through",
                       @"items": @[
                               @{
                                   @"tml": @"You can [strike: use a strike-through] as well.",
                                   @"tokens": @{@"strike": @{@"strike": @"1"}}
                                },
                               @{
                                   @"tml": @"You can indicate the [strike: strike-through color and thickness].",
                                   @"tokens": @{@"strike": @{@"strike": @{@"thickness": @"3", @"color": @"purple"}}}
                                }
                            ]
                       },
                   @{
                       @"title": @"Shadows",
                       @"items": @[
                               @{
                                   @"tml": @"[shadow: Shadows] are also very easy to add.",
                                   @"tokens": @{
                                           @"shadow": @{@"shadow": @{@"offset": @"1,1", @"radius": @"0.5", @"color": @"gray"}}
                                   },
                                },
                               @{
                                   @"tml": @"You can mix [decor: fonts, colors and shadows] are also very easy to add.",
                                   @"tokens": @{
                                           @"decor": @{
                                                   @"shadow": @{@"offset": @"1,1", @"radius": @"0.5", @"color": @"gray"},
                                                   @"font": [UIFont fontWithName:@"ChalkboardSE-Bold" size:14],
                                                   @"color": @"purple"
                                                   }
                                           },
                                   @"tokens_desc": @"{'shadow': {'offset': '1,1', 'radius': '0.5', 'color': 'gray'}}",
                                }
                            ]
                       },
                   @{
                       @"title": @"Defaults",
                       @"items": @[
                               @{
                                   @"tml": @"[bold: Adjust fonts] using default decorations.",
                                   @"tokens_desc": @"Using default decorations",
                                   @"tokens": @{}
                               }
                            ]
                       }
                   ];
}



@end
