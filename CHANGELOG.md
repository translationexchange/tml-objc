# Tml CHANGELOG

## 0.1.10

Added support for automatic UIView localization


## 0.1.0

Initial release.

# Tml renamed as TMLKit

## 1.0.0

First release as **TMLKit**, built as a dynamic framework. The SDK underwent several major changes:

* Macros have changed. Greatly simplifying numerous localization macros to simply TMLLocalizedString(), TMLLocalizedAttributedString(), TMLLocalizedDate() and TMLLocalizedAttributedDate(). See TML.h for definitions, and corresponding comment for TMLLocalize() C function, found in TML.m.
* Support for reusable localized strings added via (see below on details about reusable strings):
  * TMLLocalizedStringWithReuseIdenitifer()
  * TMLLocalizedAttributedStringWithReuseIdenitifer()
  * TMLLocalizedDateWithReuseIdenitifer()
  * TMLLocalizedAttributedDateWithReuseIdenitifer() 
* Additional macros:
  * TMLApplicationKey() - shared application key used to initialize shared TML object
  * TMLSharedApplication() - shared TMLApplication object (corresponds to Project on [TranslationExchange](http://TranslationExchange.com))
  * TMLSharedConfiguration() - current TMLConfiguration object
  * TMLLanguages() - array of languages support by shared application
  * TMLLocales() - array of locales supported by shared application (locales are string like @"en", while languages are instances of TMLLanguage)
  * TMLAvailableLocales() - array of locales that are currently available locally
  * TMLCurrentLanguage() - TMLLanguage object corresponding to current locale
  * TMLCurrentLocale() - current locale
  * TMLDefaultLanguage() - TMLLanguage corresponding to default locale
  * TMLDefaultLocale() - default locale
  * TMLCurrentSource() - name of the current source context
  * TMLHasLocalTranslationsForLocale() - returns BOOL indicating whether translation data for a locale is available locale
  * TMLSetTranslationEnabled() - enables/disables inline translation mode
  * TMLPresentLanguagePicker() - presents default Language Picker UI
  * TMLChangeLocale() - sets current locale
  * TMLPresentTranslatorForKey() - presents translation UI for a translation key identified by given hash
* New methods of handling localization data. Introducing concept of language bundles (TMLBundle). Bundle is a collection of application metadata (application being synonymous with TranslationExchange Project) and localization data:
  * It is now possible to bundle ""tml_<VERSION>.{zip,.gz,tar,tar.gz}" files with an application that uses TMLKit. Upon application launch, TMLKit will unarchive those files and install them as language bundles.
  * TMLKit will periodically check and, if needed, downloaded latest language bundles from CDN - these are published via the [Dashboard](https://dashboard.translationexchange.com). Localization data is downloaded on-demand.
  * When Inline Translation is enabled - a special bundle is created (TMLAPIBundle) to manage localization data. That localization data is retrieved via API, and is always up-to-date, unlike data that's manually published to CDN.
  * TMLBundle's are managed via TMLBundleManager, with ability to query, install and remove bundles. TMLBundle objects also utilize TMLBundleManager to post notifications about changes.
  