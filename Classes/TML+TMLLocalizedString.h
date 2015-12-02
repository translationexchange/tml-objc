//
//  TML+TMLLocalizedString.h
//  Demo
//
//  Created by Pasha on 11/30/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#ifndef TML_TMLLocalizedString_h
#define TML_TMLLocalizedString_h

#define TMLTranslationKey(label, description) \
[TMLTranslationKey generateKeyForLabel: label andDescription: description]

#define TMLLocalizedString(string) \
[TML localizeString:string description:nil tokens:nil options:nil]

#define TMLLocalizedStringWithOptions(string, description, tokens, options) \
[TML localizeString:string description:description tokens:tokens options:options]

#define TMLLocalizedAttributedString(attributedString) \
[TML localizeAttributedString:attributedString description:nil tokens:nil options:nil]

#define TMLLocalizedAttributedStringWithOptions(attributedString, description, tokens, options) \
[TML localizeAttributedString:string description:description tokens:tokens options:options]

#define TMLLocalizedDateWithFormat(date, format, description) \
[TML localizeDate:date withFormat:format description:description];

#define TMLLocalizedAttributedDateWithFormat(date, format, description) \
[TML localizeAttributedDate:date withFormat:format description:description];

#define TMLBeginSource(name) \
[TML beginBlockWithOptions: @{@"source": name}];

#define TMLEndSource \
[TML endBlockWithOptions];

#define TMLBeginBlockWithOptions(options) \
[TML beginBlockWithOptions:options];

#define TMLEndBlockWithOptions \
[TML endBlockWithOptions];

#endif /* TML_TMLLocalizedString_h */
