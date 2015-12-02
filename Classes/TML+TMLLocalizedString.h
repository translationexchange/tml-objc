//
//  TML+TMLLocalizedString.h
//  Demo
//
//  Created by Pasha on 11/30/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#ifndef TML_TMLLocalizedString_h
#define TML_TMLLocalizedString_h

#define TMLTranslationKey(label, desc) \
[TMLTranslationKey generateKeyForLabel:label description:desc]

#define TMLLocalizedString(string) \
[TML localizeString:string description:nil tokens:nil options:nil]

#define TMLLocalizedStringWithOptions(string, desc, tkns, opts) \
[TML localizeString:string description:desc tokens:tkns options:opts]

#define TMLLocalizedAttributedString(attributedString) \
[TML localizeAttributedString:attributedString description:nil tokens:nil options:nil]

#define TMLLocalizedAttributedStringWithOptions(attributedString, desc, tkns, opts) \
[TML localizeAttributedString:string description:desc tokens:tkns options:opts]

#define TMLLocalizedDateWithFormat(date, format, desc) \
[TML localizeDate:date withFormat:format description:desc];

#define TMLLocalizedAttributedDateWithFormat(date, format, desc) \
[TML localizeAttributedDate:date withFormat:format description:desc];

#define TMLBeginSource(name) \
[TML beginBlockWithOptions: @{@"source": name}];

#define TMLEndSource \
[TML endBlockWithOptions];

#define TMLBeginBlockWithOptions(options) \
[TML beginBlockWithOptions:options];

#define TMLEndBlockWithOptions \
[TML endBlockWithOptions];

#endif /* TML_TMLLocalizedString_h */
