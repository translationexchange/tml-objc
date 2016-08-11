# Tml CHANGELOG

## 0.1.10

Added support for automatic UIView localization


## 0.1.0

Initial release.

# Tml renamed as TMLKit

## 1.0.0

First release as TMLKit, built as a dynamic framework. The SDK underwent several major changes:

* TMLKit initialization changed - accepts mandatory application key and optional access token. Latter is required for Inline Translation Mode, or otherwise communicating with the server via API.
* Two ways to initialize TMLKit:
  * [TML sharedInstanceWithApplicationKey:accessToken:] - mandatory application key, optional accessToken. Arguments are used to construct default TMLConfiguration object and general purpose initializer...
  * [TML sharedInstanceWithConfiguration:] - more general initializer which allows custom configuration objects to be used.
  * -[TMLConfiguration isValidConfiguration] was added to indicate whether configuration object is valid. At the moment it checks if you have sensible values such as application key.
* Macros have changed. Greatly simplifying numerous localization macros to simply:
  * TMLLocalizedString()
  * TMLLocalizedAttributedString()
  * TMLLocalizedDate()
  * TMLLocalizedAttributedDate()
  * See TML.h for definitions, and corresponding comment for TMLLocalize() C function, found in TML.m.
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
* Tracking of previous locale, when switching locales.
* TMLKit tracks new translation keys, but only submits them to the server when Inline Translation mode is activated. Avoiding loss of new translation keys...
* TMLKit's Inline Translation mode listens to the TranslationExchange Project settings - making it possible to control the behavior remotely, independently of released apps.
* Automatic NIB localization is configurable via TMLConfiguration
* Completely reworked dynamic reloading of localized strings:
  * Using macros like TMLLocalizedStringWithReuseIdentifier() automatically register senders and localization data
  * -[TML registerObjectWithReusableLocalizedStrings:] allows registration of arbitrary objects with TML
  * TMLReusableLocalization protocol defines methods that TML invokes on objects that were registered as objects with reusable localized strings.
  * Default implementation for handling dynamic re-localization of strings invokes -[NSObject updateReusableTMLStrings], which in turn invokes -[NSObject updateTMLLocalizedStringWithInfo:forReuseIdentifier:] for each reuse identifier. Subclasses are free to control all aspects of re-localization via -[NSObject updateReusableTMLStrings], or atomically via -[NSObject updateTMLLocalizedStringWithInfo:forReuseIdentifier:]. The latter's default implementation treats reuse identifiers as key paths into the sender object, simplifying the process.
* Added gesture recognizer for invoking Inline Translation Mode. It is possible to use custom gesture recognizer via TML shared instance's delegate property (see TMLDelegate protocol).
* Single gesture recognizer for initiating actual translation. This too can be custom via the delegate object, similar to Inline Translation Mode gesture recognizer. Implementation was changed in a way to allow any UIResponder object to respond to user interaction with appropriate translation key, which is used to invoke translation UI. Technically it is possible for say UIImageView's to respond with translation keys particular to text that appears in a specific region of an image.
* Changes to NSNotifications:
  * TMLLanguageChangedNotification - TMLKit changed language - this can be due to user changing default locale, or due to a change in bundle, where previously used locale is no longer available.
  * TMLLocalizationDataChangedNotification - any time localization data is changed (say you published new update via Dashboard, and TMLKit picked it up; or if you're using Inline Translation Mode and made some changes).
  * TMLDidStartSyncNotification - When using Inline Translation Mode - indicates that TMLAPIBundle started synchronizing data
  * TMLDidFinishSyncNotification - When using Inline Translation Mode - indicates that TMLAPIBundle finished synchronizing data
  * TMLLocalizationUpdatesInstalledNotification - when TMLKit installs new localization bundle (for example when you published new localization data via Dashboard).
* Various improvements to TMLAPIClient and associated models. TMLAPIModel serves as the base; all models are meant compliant with NSCopying and NSCoding in order to facilitate serialization/materialization and copying. Equality methods were added to ease working with collections etc...
* Various improvements to Demo application
* Added analytics

## 1.0.1
* Addressing issues related to using TMLKit as static lib via cocoapods
* Minor bug fixes

## 1.0.2
* Fixes parsing of tml attributed strings

## 1.0.3
* Confiugration change to accomodate automatic reloading of both UICollectionView's and UITableView's. Deprecated: -[TMLConfiguration automaticallyReloadTableViewsWithReusableLocalizedStrings] in favor of a more general -[TMLConfiguration automaticallyReloadDataBackedViews]. Deprecated property forwards to the new one.
* Performance optimization in string tokenizing.

## 1.0.4
* Fixed issue with using incomplete language objects for translation, which manifested itself by not localizing piped tokens.

## 1.0.5
* Fixed static analyzer warnings along with some bugs.

## 1.0.6
* Fix issue with referring to localized data using case-sensitive locale names.
* Modularize framework
* Address issue with including TMLKit with use_framework! directive sepcified in Pod, for Swift projects

## 1.0.7
* Fix sync loop
* Fix API Client POST encoding
* Change downloads directory path to avoid permission problems

## 1.0.8
* Fix issue with incessant default source, especially when it comes to registering new translation keys
* Allow users to provide custom default source name via TMLConfiguration

## 1.0.9
* Several changes to how translation bundles are handled: increased interval between checks, post notifications about failures to update bundles
* Add configuration option for timeoutIntervalForRequest which is used in all url requests
* Current locale, unless specified manually, now defaults to device's locale
* Better matching of locales against project data

## 10.0.10
* Support for handling bundled tar, gz and tar.gz archives
* Minor bug fixes around bundle management
