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

#import "TmlConfiguration.h"
#import <CommonCrypto/CommonDigest.h>
#import "Tml.h"

@interface TmlConfiguration () {
    NSCalendar *calendar;
    NSDateFormatter *dateFormatter;
}
@end

@implementation TmlConfiguration
@synthesize currentLocale, defaultLocale, contextRules, defaultTokens, viewingUser;
@synthesize inContextTranslatorEnabled, defaultLocalization;

+ (id) persistentValueForKey: (NSString *) key {
    return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

+ (void) setPersistentValue:(id) value forKey: (NSString *) key {
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *) uuid {
    NSString *uuid = [self persistentValueForKey:@"tr8nUUID"];
    if (!uuid) {
        CFUUIDRef uuidRef = CFUUIDCreate(NULL);
        CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
        CFRelease(uuidRef);
        uuid = (__bridge_transfer NSString *)uuidStringRef;
        [self setPersistentValue:uuid forKey:@"tr8nUUID"];
    }
    return uuid;
}

+ (NSString *) md5: (NSString *) value {
    const char *cStr = [value UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return  output;
}

+ (BOOL) isHostAvailable: (NSString *) host {
    return YES;
//    CFNetDiagnosticRef dReference;
//    dReference = CFNetDiagnosticCreateWithURL (NULL, (__bridge CFURLRef)[NSURL URLWithString:host]);
//    
//    CFNetDiagnosticStatus status;
//    status = CFNetDiagnosticCopyNetworkStatusPassively (dReference, NULL);
//    CFRelease (dReference);
//    
//    if ( status == kCFNetDiagnosticConnectionUp )
//    {
//        TmlDebug (@"Connection is Available");
//        return YES;
//    }
//    else
//    {
//        TmlDebug (@"Connection is down");
//        return NO;
//    }
}

- (id) init {
    if (self == [super init]) {
        if ([self.class persistentValueForKey:@"default_locale"] == nil) {
            self.defaultLocale = @"en-US";
        } else {
            self.defaultLocale = [self.class persistentValueForKey:@"default_locale"];
        }

        if ([self.class persistentValueForKey:@"current_locale"] == nil) {
            self.currentLocale = [self deviceLocale]; // @"en-US";
            TmlDebug(@"Current locale: %@", self.currentLocale);
        } else {
            self.currentLocale = [self.class persistentValueForKey:@"current_locale"];
        }

        [self setupDefaultContextRules];
        [self setupDefaultTokens];
        [self setupLocalization];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ (currentLocale: %@; defaultLocalte: %@)", [super description], self.currentLocale, self.defaultLocale];
}

- (NSString *) deviceLocale {
    NSLocale *locale = [NSLocale currentLocale];
    NSString *deviceLocale = [locale localeIdentifier];
    deviceLocale = [deviceLocale componentsSeparatedByString:@"_"][0];
    //        deviceLocale = [deviceLocale stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    return deviceLocale;
}

- (void) setCurrentLocale:(NSString *)newLocale {
    currentLocale = newLocale;
    [TmlConfiguration setPersistentValue:newLocale forKey:@"current_locale"];
}

- (void) setDefaultLocale:(NSString *)newLocale {
    defaultLocale = newLocale;
    [TmlConfiguration setPersistentValue:newLocale forKey:@"default_locale"];
}

- (void) setupDefaultContextRules {
    self.contextRules = [NSMutableDictionary dictionaryWithDictionary: @{
      @"number": @{
              @"variables": [NSMutableDictionary dictionaryWithDictionary: @{}]         // if variable method is not specified, the object itself will be used as value
      },
      
      @"gender": [NSMutableDictionary dictionaryWithDictionary:@{
              @"variables": [NSMutableDictionary dictionaryWithDictionary:@{
                      @"@gender": @"@gender"                                            // @ - refers to a property of an object, @@ - refers to a method of an object
              }]
      }],
      
      @"genders": [NSMutableDictionary dictionaryWithDictionary:@{
              @"variables": [NSMutableDictionary dictionaryWithDictionary: @{
                      @"@genders": ^(NSObject *object) {                                // Anonymous functions can also be used
                          NSArray *list = (NSArray *) object;
                          NSMutableArray *genders = [NSMutableArray array];
                          for (NSObject *obj in list) {
                              [genders addObject:[obj valueForKey:@"gender"]];
                          }
                          return genders;
                      }
               }]
      }],

      @"list": [NSMutableDictionary dictionaryWithDictionary:@{
              @"variables": [NSMutableDictionary dictionaryWithDictionary:@{
                      @"@count": ^(NSObject *object) {
                          NSArray *list = (NSArray *) object;
                          return [list count];
                      }
              }]
      }],

      @"date": [NSMutableDictionary dictionaryWithDictionary:@{
              @"variables": [NSMutableDictionary dictionaryWithDictionary:@{}]
      }]
    }];
}


- (NSMutableDictionary *) dictionary: (NSDictionary *) dictionary {
    return [NSMutableDictionary dictionaryWithDictionary: dictionary];
}

- (void) setupDefaultTokens {
    self.defaultTokens = [self dictionary:@{
        @"html": [self dictionary: @{
               @"data": [self dictionary: @{
                       @"ndash":    @"&ndash;",       // –
                       @"mdash":    @"&mdash;",       // —
                       @"iexcl":    @"&iexcl;",       // ¡
                       @"iquest":   @"&iquest;",      // ¿
                       @"quot":     @"&quot;",        // "
                       @"ldquo":    @"&ldquo;",       // “
                       @"rdquo":    @"&rdquo;",       // ”
                       @"lsquo":    @"&lsquo;",       // ‘
                       @"rsquo":    @"&rsquo;",       // ’
                       @"laquo":    @"&laquo;",       // «
                       @"raquo":    @"&raquo;",       // »
                       @"nbsp":     @"&nbsp;",        // space
                       @"lsaquo":   @"&lsaquo;",      // ‹
                       @"rsaquo":   @"&rsaquo;",      // ›
                       @"br":       @"<br/>",         // line break
                       @"lbrace":   @"{",
                       @"rbrace":   @"}",
                       @"trade":    @"&trade;"        // TM
                }],
               @"decoration": [self dictionary: @{
                       @"strong":   @"<strong>{$0}</strong>",
                       @"bold":     @"<strong>{$0}</strong>",
                       @"b":        @"<strong>{$0}</strong>",
                       @"em":       @"<em>{$0}</em>",
                       @"italic":   @"<i>{$0}</i>",
                       @"i":        @"<i>{$0}</i>",
                       @"link":     @"<a href='{$href}'>{$0}</a>",
                       @"br":       @"<br>{$0}",
                       @"strike":   @"<strike>{$0}</strike>",
                       @"div":      @"<div id='{$id}' class='{$class}' style='{$style}'>{$0}</div>",
                       @"span":     @"<span id='{$id}' class='{$class}' style='{$style}'>{$0}</span>",
                       @"h1":       @"<h1>{$0}</h1>",
                       @"h2":       @"<h2>{$0}</h2>",
                       @"h3":       @"<h3>{$0}</h3>"
                }]
        }],
        @"attributed": [self dictionary: @{
              @"data":  [self dictionary: @{
                      @"ndash":    @"–",        // –
                      @"mdash":    @"–",        // —
                      @"iexcl":    @"¡",        // ¡
                      @"iquest":   @"¿",        // ¿
                      @"quot":     @"\"",       // "
                      @"ldquo":    @"“",        // “
                      @"rdquo":    @"”",        // ”
                      @"lsquo":    @"‘",        // ‘
                      @"rsquo":    @"’",        // ’
                      @"laquo":    @"«",        // «
                      @"raquo":    @"»",        // »
                      @"nbsp":     @" ",        // space
                      @"lsaquo":   @"‹",        // ‹
                      @"rsaquo":   @"›",        // ›
                      @"br":       @"\n",       // line break
                      @"lbrace":   @"{",
                      @"rbrace":   @"}",
                      @"trade":    @"™"         // TM
                }],
              @"decoration": [self dictionary: @{
                      @"strong":   @{@"font": @{@"name": @"system", @"size": @14, @"type": @"bold"}},
                      @"bold":     @{@"font": @{@"name": @"system", @"size": @14, @"type": @"bold"}},
                      @"b":        @{@"font": @{@"name": @"system", @"size": @14, @"type": @"bold"}},
                      @"em":       @{@"font": @{@"name": @"system", @"size": @14, @"type": @"bold"}},
                      @"italic":   @{@"font": @{@"name": @"system", @"size": @14, @"type": @"italic"}},
                      @"i":        @{@"font": @{@"name": @"system", @"size": @14, @"type": @"italic"}},
                      @"link":     @"{$0}",
                      @"br":       @"\n{$0}",
                      @"strike":   @{@"strike": @"1"},
                      @"div":      @"{$0}",
                      @"span":     @"{$0}",
                      @"h1":       @{@"font": @{@"name": @"system", @"size": @20, @"type": @"bold"}},
                      @"h2":       @{@"font": @{@"name": @"system", @"size": @18, @"type": @"bold"}},
                      @"h3":       @{@"font": @{@"name": @"system", @"size": @16, @"type": @"bold"}},
            }]
        }]
    }];
}

- (void) setupLocalization {
    self.defaultLocalization = [self dictionary:@{
      @"default_day_names": @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"],
      @"default_abbr_day_names": @[@"Sun", @"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat"],
      @"default_month_names": @[@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"],
      @"default_abbr_month_names": @[@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"],
      @"custom_date_formats": [self dictionary:@{
        @"default"               : @"mm/d/yyyy",             // 07/4/2008
        @"short_numeric"         : @"mm/d",                  // 07/4
        @"short_numeric_year"    : @"mm/d/yy",               // 07/4/08
        @"long_numeric"          : @"mm/d/yyyy",             // 07/4/2008
        @"verbose"               : @"eeee, MMMM d, yyyy",    // Friday, July  4, 2008
        @"monthname"             : @"MMMM d",                // July 4
        @"monthname_year"        : @"MMMM d, yyyy",          // July 4, 2008
        @"monthname_abbr"        : @"MMMM d",                // Jul 4
        @"monthname_abbr_year"   : @"MMM d, yyyy",           // Jul 4, 2008
        @"date_time"             : @"mm/dd/yyyy at h:m",     // 01/03/1010 at 5:30
    }],
    @"token_mapping": [self dictionary:@{
        @"G": @"{era}",
        @"y": @"{short_year_digit}",
        @"yy": @"{short_year}",
        @"yyyy": @"{year}",
        @"M": @"{month}",
        @"MM": @"{month_padded}",
        @"MMM": @"{short_month_name}",
        @"MMMM": @"{month_name}",
        @"MMMMM": @"{month_letter}",
        @"w": @"{week_of_year}",
        @"ww": @"{week_of_year}",
        @"W": @"{week_num}",
        @"d": @"{day}",
        @"dd": @"{day_padded}",
        @"D": @"{day_of_year}",
        @"DD": @"{day_of_year_padded}",
        @"DDD": @"{day_of_year}",
        @"F": @"{day_of_week_in_month}",
        @"E": @"{day_of_week}",
        @"EE": @"{day_of_week_padded2}",
        @"EEE": @"{day_of_week_padded3}",
        @"EEEE": @"{short_weekday_name}",
        @"EEEE": @"{weekday_name}",
        @"a": @"{am_pm}",
        @"h": @"{hour}",
        @"hh": @"{hour_padded}",
        @"H": @"{hour24}",
        @"HH": @"{hour24_padded}",
        @"m": @"{minute}",
        @"mm": @"{minute_padded}",
        @"s": @"{second}",
        @"ss": @"{second_padded}",
    }]
   }];
}

- (NSString *) customDateFormatForKey: (NSString *) key {
    return [[self.defaultLocalization objectForKey:@"custom_date_formats"] objectForKey:key];
}

- (NSString *) dateTokenNameForKey: (NSString *) key {
    return [[self.defaultLocalization objectForKey:@"token_mapping"] objectForKey:key];
}

- (NSObject *) dateValueForToken: (NSString *) token inDate: (NSDate *) date  {
    if (![self.defaultLocalization objectForKey:@"token_mapping_reversed"]) {
        NSArray *keys = [[self.defaultLocalization objectForKey:@"token_mapping"] allKeys];
        NSMutableDictionary *reversed = [NSMutableDictionary dictionary];
        for (NSString *key in keys) {
            [reversed setObject:key forKey: [[self.defaultLocalization objectForKey:@"token_mapping"] objectForKey:key]];
        }
        [self.defaultLocalization setObject:reversed forKey:@"token_mapping_reversed"];
    }

    NSString *format = [[self.defaultLocalization objectForKey:@"token_mapping_reversed"] objectForKey:token];
    if (!format) return token;
    
    if (calendar == nil)
        calendar = [NSCalendar currentCalendar];
    
    // Handle string values
    if ([token isEqualToString:@"{month_name}"]) {
        NSDateComponents *comps = [calendar components:NSCalendarUnitMonth fromDate:date];
        NSString *monthName = [[self.defaultLocalization objectForKey:@"default_month_names"] objectAtIndex:comps.month-1];
        return TmlLocalizedStringWithDescriptionAndOptions(monthName, @"Month name", (@{@"locale": @"en"}));
    }

    if ([token isEqualToString:@"{short_month_name}"]) {
        NSDateComponents *comps = [calendar components:NSCalendarUnitMonth fromDate:date];
        NSString *monthName = [[self.defaultLocalization objectForKey:@"default_abbr_month_names"] objectAtIndex:comps.month-1];
        return TmlLocalizedStringWithDescriptionAndOptions(monthName, @"Abbreviated month name", (@{@"locale": @"en"}));
    }

    if ([token isEqualToString:@"{weekday_name}"]) {
        NSDateComponents *comps = [calendar components:NSCalendarUnitWeekday fromDate:date];
        NSString *weekdayName = [[self.defaultLocalization objectForKey:@"default_day_names"] objectAtIndex:comps.weekday];
        return TmlLocalizedStringWithDescriptionAndOptions(weekdayName, @"Weekday name", (@{@"locale": @"en"}));
    }

    if ([token isEqualToString:@"{short_weekday_name}"]) {
        NSDateComponents *comps = [calendar components:NSCalendarUnitWeekday fromDate:date];
        NSString *weekdayName = [[self.defaultLocalization objectForKey:@"default_abbr_day_names"] objectAtIndex:comps.weekday];
        return TmlLocalizedStringWithDescriptionAndOptions(weekdayName, @"Abbreviated weekday name", (@{@"locale": @"en"}));
    }
    
    if (dateFormatter == nil)
        dateFormatter = [[NSDateFormatter alloc] init];

    [dateFormatter setDateFormat:format];
    return [dateFormatter stringFromDate:date];
}

- (id) variableMethodForContext:(NSString *) keyword andVariableName: (NSString *) varName {
    NSDictionary *contextConfig = [self.contextRules objectForKey:keyword];
    if (contextConfig == nil)
        return nil;
    
    NSDictionary *variables = [contextConfig objectForKey:@"variables"];
    if (variables == nil)
        return nil;
    
    return [variables objectForKey:varName];
}

- (void) setVariableMethod: (id) method forContext:(NSString *) keyword andVariableName: (NSString *) varName {
    NSMutableDictionary *contextConfig = [self.contextRules objectForKey:keyword];
    if (contextConfig == nil) {
        contextConfig = [NSMutableDictionary dictionary];
        [self.contextRules setObject:contextConfig forKey:keyword];
    }
    
    NSMutableDictionary *variables = [contextConfig objectForKey:@"variables"];
    if (variables == nil) {
        variables = [NSMutableDictionary dictionary];
        [contextConfig setObject:variables forKey:@"variables"];
    }
    
    [variables setObject:method forKey:varName];
}

- (id) defaultTokenValueForName: (NSString *) name {
    return [self defaultTokenValueForName: name type: @"data" format:@"html"];
}

- (void) setDefaultTokenValue: (id) value forName: (NSString *) name {
    [self setDefaultTokenValue:value forName:name type:@"data" format:@"html"];
}

- (id) defaultTokenValueForName: (NSString *) name type: (NSString *) type {
    return [self defaultTokenValueForName: name type: type format:@"html"];
}

- (void) setDefaultTokenValue: (id) value forName: (NSString *) name  type: (NSString *) type {
    [self setDefaultTokenValue:value forName:name type:type format:@"html"];
}

- (id) defaultTokenValueForName: (NSString *) name type: (NSString *) type format: (NSString *) format {
    return [[[self.defaultTokens objectForKey:format] objectForKey:type] objectForKey:name];
}

- (void) setDefaultTokenValue: (id) value forName: (NSString *) name type: (NSString *) type format: (NSString *) format {
    NSMutableDictionary *dictFormat = (NSMutableDictionary *) [self.defaultTokens objectForKey:format];
    if (dictFormat == nil) {
        dictFormat = [NSMutableDictionary dictionary];
        [self.defaultTokens setObject:dictFormat forKey:format];
    }

    NSMutableDictionary *dictType = (NSMutableDictionary *) [dictFormat objectForKey:type];
    if (dictType == nil) {
        dictType = [NSMutableDictionary dictionary];
        [dictFormat setObject:dictType forKey:format];
    }

    [dictType setObject:value forKey:name];
}

@end
