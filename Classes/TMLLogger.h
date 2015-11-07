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

#ifndef TMLLogger_h
#define TMLLogger_h

#define TMLLogLevelError 0
#define TMLLogLevelWarning 1
#define TMLLogLevelInfo 2
#define TMLLogLevelDebug 3

typedef NSInteger TMLLogLevel;

static inline void TMLLog(TMLLogLevel level, NSString *format, ...) {
    __block va_list arg_list;
    va_start (arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    va_end(arg_list);
    NSString *levelString = nil;
    switch (level) {
        case TMLLogLevelError:
            levelString = @"Error";
            break;
        case TMLLogLevelInfo:
            levelString = @"Info";
            break;
        case TMLLogLevelWarning:
            levelString = @"Warning";
            break;
        case TMLLogLevelDebug:
            levelString = @"Debug";
            break;
        default:
            levelString = @"Unknown";
            break;
    }
    NSLog(@"[TML %@] %@", levelString, formattedString);
}

#if TML_DEBUG >= TMLLogLevelError
#define TMLError(...) TMLLog(TMLLogLevelError, __VA_ARGS__)
#else
#define TMLError(...)
#endif

#if TML_DEBUG >= TMLLogLevelWarning
#define TMLWarn(...) TMLLog(TMLLogLevelWarning, __VA_ARGS__)
#else 
#define TMLWarn(...)
#endif

#if TML_DEBUG >= TMLLogLevelInfo
#define TMLInfo(...) TMLLog(TMLLogLevelInfo, __VA_ARGS__)
#else
#define TMLInfo(...)
#endif

#if TML_DEBUG >= TMLLogLevelDebug
#define TMLDebug(...) TMLLog(TMLLogLevelDebug, __VA_ARGS__)
#else
#define TMLDebug(...)
#endif

#ifdef TML_MESSAGING_DEBUG
#define MessagingDebug(...) TMLLog(__VA_ARGS__)
#else
#define MessagingDebug(...)
#endif

#endif
