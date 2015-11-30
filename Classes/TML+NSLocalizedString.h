//
//  TML+NSLocalizedString.h
//  Demo
//
//  Created by Pasha on 11/29/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#ifndef TML_NSLocalizedString_h
#define TML_NSLocalizedString_h

#undef NSLocalizedString
#define NSLocalizedString(key, comment) \
[TML translate:key withDescription:comment]

#undef NSLocalizedStringFromTable
#define NSLocalizedStringFromTable(key, tbl, comment) \
[TML translate:key withDescription:comment]

#undef NSLocalizedStringFromTableInBundle
#define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) \
[TML translate:key withDescription:comment]

#undef NSLocalizedStringWithDefaultValue
#define NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) \
[TML translate:key withDescription:comment]

#endif /* TML_NSLocalizedString_h */
