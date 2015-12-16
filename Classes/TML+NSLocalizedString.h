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
TMLLocalizedString(key, comment)

#undef NSLocalizedStringFromTable
#define NSLocalizedStringFromTable(key, tbl, comment) \
TMLLocalizedString(key, comment, @{@"source": tbl})

#undef NSLocalizedStringFromTableInBundle
#define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) \
TMLLocalizedString(key, comment, @{@"source": tbl})

#undef NSLocalizedStringWithDefaultValue
#define NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) \
TMLLocalizedString(key, comment, @{@"source": tbl, @"defaultValue": val})

#endif /* TML_NSLocalizedString_h */
