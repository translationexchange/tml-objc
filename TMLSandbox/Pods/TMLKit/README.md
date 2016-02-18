<p align="center">
  <img src="https://avatars0.githubusercontent.com/u/1316274?v=3&s=200">
</p>

TML for Objective C
==================

[![Version](http://cocoapod-badges.herokuapp.com/v/TMLKit/badge.png)](http://cocoadocs.org/docsets/TMLKit/1.0.0/)
[![Platform](http://cocoapod-badges.herokuapp.com/p/TMLKit/badge.png)](http://cocoadocs.org/docsets/TMLKit)
[![Build Status](https://travis-ci.org/translationexchange/tml-objc.svg?branch=master)](https://travis-ci.org/translationexchange/tml-objc)

TMLKit is an Objective-C SDK for an integrated cloud-based translation solution for iOS applications.

It reduces the number of steps required for internationalization and localization of your mobile applications.

TMLKit integrates with TranslationExchange.com service, where you can manage the entire translation process - enable languages, invite translators, manage translation keys, and much more.

You never have to touch the resource bundle files - translation keys are extracted from your app's source code on the fly and kept up to date by the SDK.

Once your app is translated, the translations will automatically be downloaded and installed by the SDK. You DO NOT need to submit a new application to the App Store. You can simply enable a new language on TranslationExchange.com and it will immediately be available in your application.

<p align="center">
  <img src="https://github.com/translationexchange/tml-docs/blob/master/objc/iphone.gif">
</p>


Requirements
==================

	iOS 8
	CocoaPods


Demo Application
==================

This repository comes with a Demo application. To run it, follow these steps:

```sh
$ git clone https://github.com/translationexchange/tml-objc.git
$ cd tml-objc/Demo
$ pod install
$ open Demo.xcworkspace
```

Configure TMLKit by editing main.m and setting *application key* and *access token* parameters to match your TranslationExchange project. Finally, run the application from XCode.

Once the Demo application is running, open the side panel and enable **In-App Translation**. That will cause TMLKit to register all of the localizable strings in your application with your TranslationExchange project. Select **Change Language** from the side panel. You should see all of the languages currently used in your project listed here. TMLKit provides a default language picker. Creating a custom one is a breeze - see [TMLLanguageSelectorViewController](https://github.com/translationexchange/tml-objc/blob/dev/Classes/Controllers/TMLLanguageSelectorViewController.m) for details.

Head over to [dashboard](https://dashboard-translationexchange.com) and add a new language to your project. Now, switch back to the Demo app, background and foreground it - that will trigger TMLKit to instantly update information about your project, and, subsequently, list of available languages.

**In-App Translation** mode allows you to also add translation right from within the app. Make sure you select a non-default languages from the language picker, then simply tap and hold over any text you see on the screen. TMLKit will bring up interface for translating the string you tapped. You can manually add a translation, or pick one of the machine translations listed at the bottom if they are to your satisfaction. Once you've added a translation - dismiss the translation view and watch the original string get updated to its translation.


Another sample application is located here:

https://github.com/translationexchange/tml-objc-samples-wammer


Installation
==================

To install the SDK through [CocoaPods](http://cocoapods.org), simply add the following line to your Podfile:

```sh
pod "TMLKit"
```

and run

```sh
pod install
```

Alternatively, you can clone this repository:

```sh
$ git clone https://github.com/translationexchange/tml-objc.git
$ cd tml-objc/TMLKit
$ pod install
```

And build TMLKit.xcodeproj and simply include the build framework in your project, or, drag TMLKit.xcodeproj into your application's Xcode project and have it configured as a [linked framework](https://developer.apple.com/library/ios/recipes/xcode_help-project_editor/Articles/AddingaLibrarytoaTarget.html).


Integration
==================


Before you can proceed with the integration, please visit https://TranslationExchange.com - open an account and create a project for your application. Each project is assigned a unique *application key* and *access token* which you will use to configure TMLKit.

While *application key* is mandatory, configuring TMLKit with the *access token* is optional and allows your app to register new translation keys on the server and utilize *In-App Translation* mode. When you release your application you should remove *access token* and only supply the *application key*.

Here's how you would configure TMLKit:

```objc
#import <TMLKit/TMLKit.h>

int main(int argc, char * argv[])
{
    @autoreleasepool {
        
        [TML sharedInstanceWithApplicationKey:@"<APPLICATION KEY>" accessToken:@"<ACCESS TOKEN>"];
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

**Note:** TML is capable of automatically localizing strings in NIB files. It's a configurable option that is enabled by default. This automatic localization happens during decoding of NIB files, which may happen before your app delegate is called with application:didFinishLaunchingWithOptions:. This is why the above example uses main.m to configure TMLKit. If you are not using automatic NIB localization - you can move that configuration over to your app delegate...

TMLKit comes with a variety of macros to help with localization. TMLLocalizedString() should be familiar to you if you've used NSLocalizedString() before. To avoid having to include TMLKit.h in every file it's probably best to import it in the prefix header file, along with your foundation framework includes:

```objc
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <TMLKit/TMLKit.h>
#endif
```

If your project uses NSLocalizedString and you have no intention of using TML markup language, or simply eager to see some results, TMLKit comes with redefined NSLocalizedString macros. Simply add:

```objc
#import <TMLKit/TMLKit+NSLocalizedString.h>
```

However, you only get full use of TML via TMLLocalizedString() macros. TML supports default inflectors, pluralizers, contextualizer and language cases, which to better code and much better localization.


How does it work?
==================

TMLKit does all the hard work for you. When you use TML's macros (see TML.h), the library automatically registers translation keys with Translation Exchange service and generates resource bunldes for your app on the fly. TMLKit always keep your local cache up to date by downloading the latest translations from the service when they become available. At run-time, your app will use translations from your local app cache so your users will not experience any delays. When new localized data becomes available it is possible for your application to update translations dynamically, without needing to restart the application.

You also have an option to bundle all your translations with your app before you release it - allowing your application to function in offline mode. By default, whenever your application becomes active and has connectivity to the internet - TMLKit will check for new translation releases (published via the [dashboard](https://dashboard-translationexchange.com)). When updates are available they are downloaded on-demand. Translations for default and current locales are downloaded immediately, and additional data is downloaded when TMLKit is told to change current locale.

TMLKit also reports analytics data, allowing you to see what languages are used in your app, what the default languages of your users are, where your users are coming from, etc...


Internationalization & TML
==================

If your application is already internationalized using the standard NSLocalizedString methods, you can simply import the TML+NSLocalizedString.h header in your .m file and TML will take over the internationalization macros.

```objc
#import "<TMLKit/TML+NSLocalizedString.h>"
```
However, these macros are rather limited as they don't allow full TML syntaxt (data tokens, etc).

TML also provides its own macros for internationalization which significantly enhance the standard iOS macros.

Basic example:

```objc
TMLLocalizedString(label);
TMLLocalizedString(label, description);

TMLLocalizedString(@"Invite");
TMLLocalizedString(@"Invite", @"Invite someone to join the group");
```

This macro is similar to NSLocalizedString, and it does not require the optional comment parameter.

Unlike NSLocalizedString, where the second parameter is a comment for a translator, TML uses the description to contextualize the key. So the above example would actually register two distinct keys, where each would have its own translations.

Another example:

```objc
TMLLocalizedString(label, tokens);

TMLLocalizedStringWithTokens(@"You have {count || message}.", @{@"count": @4});
TMLLocalizedStringWithTokens(@"Hello {user}.", @{@"user": @"Michael"});
```

Tokens can be passed in many different ways. If the token is passed as a primitive type, it would be used for both context rules and displayed value. If it is passed a class or a structure, you can separate the object being used for context rules and the value that would be substituted for the token.

More examples of using tokens:

```objc
User *user  = [[User alloc] initWithName: @"Michael" gender: @"male"];
// will use [user description] for substitution value
TMLLocalizedStringWithTokens(@"Hello {user}.", @{@"user": user})
// second parameter is used for substitution value
TMLLocalizedStringWithTokens(@"Hello {user}.", @{@"user": @[user, user.name]})
TMLLocalizedStringWithTokens(@"Hello {user}.", @{@"user": @[user, @"Mike"]})
```

```objc
NSDictionary *user = @{@"name": @"Michael", @"gender": @"male"};
// can be used for context rules, but not substitution value
TMLLocalizedStringWithTokens(@"{user | Born On}.", @{@"user": user})
TMLLocalizedStringWithTokens(@"Hello {user}.", @{
          @"user": @{@"object": user, @"property": @"name"}
})
TMLLocalizedStringWithTokens(@"Hello {user}.", @{
          @"user": @{@"object": user, @"value": @"Michael"}
})
```

You might have noticed that we're using the same macro with a variety of arguments. The full syntax of TMLLocalizedString() is:

```objc
TMLLocalizedString(NSString *localizedString, NSString *description, NSDictionary *tokens, NSDictionary *userOptions);
```

Only the first argument is mandatory...

```objc
TMLLocalizedString(
    @"Hello {user}",  // localized string
    @"A greeting message",  // description
    @{@"user": @"Michael"}  // tokens
)
```

```objc
TMLLocalizedString(
    @"Hello {user}",  // localized string
    @"A greeting message",  // description
    @{@"user": @"Michael"}, // tokens
    @{@"level": @5, @"max-length": @20} // options
)
```

```objc
TMLLocalizedString(
    @"Hello {user}",  // localized string
    @{@"user": @"Michael"}, // tokens
)
```

```objc
TMLLocalizedString(
    @"Hello {user}",  // localized string
    @{}, // no tokens
    @{@"level": @5, @"max-length": @20} // options
)
```

Options are TML specic options. Some are used for formatting strings, some are purely administrative. For example, in the above code snippet options specify that only translators of a specific rank are allowed to translate keys of a specific level. The constraint indicate that the translations of this key may not be longer than 20 chars. See wiki.translationexchage.com for more details.


All of the above macros assume that you are working with plain text and will return NSString's. It is also possible to work with attributed strings, in a fashion similar to data token (delimited with '{}'):

```objc
TMLLocalizedAttributedString(
    @"You have completed [bold: {count || mile}] on your last run.",
    @{@"count": @4.2}
)
```

Notice that we are now using TMLLocalizedAttributedString() macro. It is synonymous to TMLLocalizedString() and exists solely to make a distinction in the return type. TMLLocalizedString() returns NSString's, and TMLLocalizedAttributedString() returns NSAttributedString's. Secondly, you'll notice that decorated tokens are delimited with '[]' square brackets, as opposed to data tokens, which are delimited using '{}' curly brackets.

All in all, the above example will return:

```
	"You have completed **4.2 miles** on your last run."
```

TMLKit supports both NSAttributedString format and HTML. Here's the HTML equivalent:

```objc
TMLLocalizedString(
    @"You have completed [bold: {count || mile}] on your last run.",
    @{@"count": @4.2},
    @{TMLTokenFormatOptionName: TMLHTMLTokenFormatString}
)
```

which results in: 

```hTML
	"You have completed <strong>4.2 miles</strong> on your last run."
```

Do notice that if you are expecting an NSString - use TMLLocalizedString(); if you are expecting NSAttributedString - use TMLLocalizedAttributedString();


Default Tokens
======================

It is also possible to define default tokens and refer to them by name throughout your code, instead of having to supplying identical data structures. You get cleaner, more consistent code this way.

```objc
TMLConfiguration *config = TMLSharedConfiguration();
// Data Tokens
[config setDefaultTokenValue: @"My App Name"
                     forName: @"app_name"
                        type: TMLDataTokenType];

// Decorated Tokens with attributed strings
[config setDefaultTokenValue: @{
                   @"font": @{
                      @"name": @"system",
                      @"size": @12,
                      @"type": @"italic"
                   },
                   @"color": @"blue"
                 }
                     forName: @"bold"
                        type: TMLDecorationTokenType
                      format: TMLAttributedTokenFormat];

[config setDefaultTokenValue: @{
                   @"shadow": @{
                      @"offset": @1,1,
                      @"radius": @0.5,
                      @"color": @"grey"
                   },
                   @"color": @"black"
                                 }
                     forName: @"shadow"
                        type: TMLDecorationTokenType
                      format: TMLAttributedTokenFormat];

[config setDefaultTokenValue: @{
                   @"attributes": @{
                     UIFontDescriptorNameAttribute: @"Arial"
                     UIFontDescriptorNameAttribute: @(12.), 
                     UIFontDescriptorSymbolicTraits: UIFontDescriptorTraitItalic
                   }
                 }
                     forName: @"italic"
                        type: TMLDecorationTokenType
                      format: TMLAttributedTokenFormat];

// Decorated tokens with HTML strings
[config setDefaultTokenValue: @"<strong>{$0}</strong>"
                     forName: @"bold"
                        type: TMLDecorationTokenType
                      format: TMLHTMLTokenFormat];

[config setDefaultTokenValue: @"<span style='color:green'>{$0}</span>"
                     forName: @"green"
                        type: TMLDecorationTokenType
                      format: TMLHTMLTokenFormat];

```

Alternatively, you can provide token values inline, which would overwrite the default token definitions.

The following examples will use the above pre-defined tokens:

```objc
TMLLocalizedAttributedString(@"Hello [bold: World]");
TMLLocalizedAttributedString(@"[italic: Hello World]");
TMLLocalizedAttributedString(@"This [bold: technology is [shadow: very cool]].");
```

Notice that "very cool" will be bold and have a shadow. Nesting tokens inherits the parent token traits.


Benefits of TMLLocalizedAttributedString()
==================

The benefits of using TML with NSAttributedString is that labels get translated in context. If you tried the above example without using TML, you would end up with code similar to the following:


```objc
NSDictionary *bold = @{[UIFont boldSystemFontOfSize:@12], NSFontAttributeName};

NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
[str appendString : NSLocalizedString(@"You have completed ")];

if (distance_in_miles == 1)
   [str appendAttributedString:
          [[NSAttributedString alloc] initWithString: NSLocalizedString(@"1 mile")]
                      attributes: bold];
else
   [str appendAttributedString:
          [[NSAttributedString alloc] initWithString:
              [NSString stringWithFormat: NSLocalizedString(@"%d miles"), distance_in_miles]]
                      attributes: bold];

[str appendString: NSLocalizedString(@" on your last run.")];
```

The above code has the following issues:

* The (distance_in_miles == 1) check fails for languages that have more complicated numeric rules, like Russian or Arabic.
* "You have completed " and " on your last run" will been translated outside of the context of the entire sentence. In some languages some words must be switched around. So it fails in both contextualization and composition.
* "1 mile" and "%d miles" are also translated outside of the context.


All of the above code can be replaced with a single line using TML:

```objc
TMLLocalizedAttributedString(
    @"You have completed [bold: {count || mile}] on your last run.",
    @{@"count": @4.2}
)
```

Which is easily translated to Russian:

    "Вы пробежали [bold: {count || милю, мили, миль}] в вашем последнем забеге."


Since there are languages, like Hebrew, which depend on the gender of the viewing user, any time you refer to "You", you should always pass the viewing_user as a token.

```objc
TMLLocalizedAttributedString(@"You have completed [bold: {count || mile}] on your last run.", @{@"count": @4.2, @"viewing_user": currentUser})
```

Or better yet, set it in the configuration, and then you never have to pass it as a token:

```objc
TMLSharedConfiguration().viewingUser = currentUser;
```

Here is a more complicated example:

```objc
TMLLocalizedAttributedString(
    @"[bold: {user}] has completed [bold: {count || mile}] on {user| his, her} last run.",
    @{
        @"user": friend,
        @"count": @4.2,
        @"link": @{@"color": @"blue"}
        @"bold": @{@"font":@{@"name": @"system", @"size": @12, @"type": @"bold"}}
    }
)
```

In English, this will render as:

    "**Michael** has completed **4.2 miles** on his last run."

Translated to Russian as:

    "[link: {user}] {user | пробежал, пробежала} [bold: {count || милю, мили, миль}] в своем последнем забеге."

Will render as:

    "**Michael** пробежал **4.2 мили** в своем последнем забеге."



Switching Locales At Runtime
==================

It is possible to tell TMLKit to change local at runtime. Whether you would like to provide that functionality in your released version of the app is up to you and your interpretation of Apple's rules and guidelines. However, it does come in handy when testing the application with various languages and when using *In-App Translation* mode.

For that reason, TMLKit comes with a simple language picker that you can use in your application. To open the langugae picker programmatically, use the following code:

```objc
TMLPresentLanguagePicker();
```

To change current locale programmatically:

```objc
TMLChangeLocale(@"ru"); // will change to Russian locale
```

There's one thing worth noting here - unless you've bundled all of your translation data with the app, your app may not have the translation data available locally for the new locale. In which case - TMLKit will download all of the required data in the background. What this means is that the actual change of locale may be deferred. If you'd like to, for example, present a progress indicator while the data is being downloaded, you can use the following call:

```objc
TML *tml = [TML sharedInstance];
MBProgressHUD *hud = nil;

if ([tml hasLocalTranslationsForLocale:newLocale] == NO) {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = TMLLocalizedString(@"Switching language...");
    [hud show:YES];
}

[tml changeLocale:newLocale
  completionBlock:^(BOOL success) {
    [hud hide:YES];
  }];
```

And this is roughly how TMLLanguageSelectorViewController works.

Off course this means that all of your views that have alraedy presented localized strings need to be updated with new localized strings. See [Reusable Localized Strings] for details...


Reusable Localized Strings
==================

If you'd like to provide dynamic language switching (see [Switching Locales At Runtime]), your app needs to be able to update all of the required objects that have already utilized localized string. Consider a basic UILabel:

```objc
UILabel *label = self.titleLabel;
label.attributedText = TMLLocalizedAttributedString(@"[bold:Title]: {title}", @{@"title": @"My Title"});
```

When your application changes locale this label need to be updated with a localized string corresponding to the new locale. To facilitate these updates, TMLKit provides additional macros: TMLLocalizedStringWithReuseIdenitifer() and TMLLocalizedAttributedStringWithReuseIdenitifer():

Basic usage:

```objc
TMLLocalizedStringWithReuseIdenitifer(string, reuseIdentifier, ...);
TMLLocalizedAttributedStringWithReuseIdenitifer(string, reuseIdentifier, ...);
```

It is identical to the already familiar TMLLocalizedString() and TMLLocalizedAttributedString() macros, accept they take a second mandatory parameter - and identifier.

Thus, the above UILabel example becomes:

```objc
UILabel *label = self.titleLabel;
label.attributedText = TMLLocalizedAttributedStringWithReuseIdenitifer(@"[bold:Title]: {title}", @{@"title": @"My Title"}, @"titleLabel");
```

This causes TMLKit to register the caller (what is 'self' in the context of when the call is made), and when there comes time to update the localized string, it calls that caller's updateTMLLocalizedStringWithInfo:forReuseIdentifier: method, if one is defined.

The method is defined as optional in TMLReusableLocalization protocol. TMLKit extends NSObject by conforming to that protocol.

```objc
@protocol TMLReusableLocalization <NSObject>
@optional
- (void)updateTMLLocalizedStringWithInfo:(NSDictionary *)info forReuseIdentifier:(NSString *)reuseIdentifier;
@end
```

We'll get back to this in a second, but first let's finish up with our UILabel example. Within the same class, let's define:

```objc
- (void)updateTMLLocalizedStringWithInfo:(NSDictionary *)info forReuseIdentifier:(NSString *)reuseIdentifier {
  if ([reuseIdentifier isEqualToString:@"titleLabel"] == YES) {
    self.titleLabel.attributedText = info[TMLLocalizedStringInfoKey];
  }
  else {
    [super updateTMLLocalizedStringWithInfo:info forReuseIdentifier:reuseIdentifier];
  }
}
```

Notice that the info object passed to updateTMLLocalizedStringWithInfo:forReuseIdentifier: already contains the new localized string; it also contains all of the data used to construct it in the first place. That means that TMLLocalizedStringWithReuseIdentifier() captures (strongly) all of its arguments. It's worth mentioning that this data is tied to the sender object, and TMLKit captures sender objects weakly. So, once the sender object is released - all of the captured localization data is released with it.

Also notice that we are calling super's implementation...

TMLKit defines default behavior for updating reusable localized strings - it treats reuseIdentifier as a key path into the sender object. If the sender responds to -[NSObject valueForKeyPath:], it will attempt to update the value via -[NSObject setValue:forKeyPath:]. This is how TMLKit handles automatic NIB localization.

Let's simplify our UILabel example a little:

```objc
@interface MyViewController : UIViewController
@property (strong, nonatomic) UILabel *titleLabel;
@end

@implementation MyViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  UIlabel *titleLabel = [[UILabel alloc] init];
  titleLabel.attributedText = TMLLocalizedAttributedStringWithReuseIdenitifer(@"[bold:Title]: {title}", @{@"title": @"My Title"}, @"titleLabel.attributedText");
  self.titleLabel = titleLabel;
}
@end
```

This is all you have to do, as TMLKit's default implementation will simply call setValue:forKeyPath: on the controller, using "titleLabel.attributedText" as the keyPath.


Let's say you are not comfortable with TMLKit capturing data used to create localized strings:

```objc
@implementation MyViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  UILabel *titleLabel = [[UIlabel alloc] init];
  self.titleLabel = titleLabel;
  [self configureView];
  [[TML sharedInstance] registerObjectWithReusableLocalizedStrings:self];
}

- (void)configureView {
  self.titleLabel.attributedText = TMLLocalizedAttributedString(@"[bold:Title]: {title}", @{@"title": @"My Title"});
}

- (void)updateReusableTMLStrings {
  [super updateReusableTMLStrings];
  [self configureView];
}
@end
```

First of all - notice that we are using TMLLocalizedAttributedString() and not TMLLocalizedAttributedStringWithReuseIdentifier() - so we are not capturing any localization data here. Secondly - we are registering the view controller with TML via registerObjectWithReusableLocalizedStrings:. When it's time to update localized strings - TML will call this controller's updateReusableTMLStrings method. We respond by calling configureView, which re-localizes the label anew.


In-App Translator
==================

TMLKit supports translation of strings right from within the app. Assuming your application is configured with both *application key* and *access token*, you can enable **In-App Translation** mode like this:

```objc
TMLSetTranslationEnabled(YES); // NO argument disables
```

Please note, that if your TranslationExchange project configuration disallows **Inline Translations** - TMLKit will honor that setting and ignore TMLSetTranslationEnabled() call.

Once the **In-App Translation** mode is enabled - tap and hold on any localized string on the screen - TMLKit will bring up Translator interface for that specific string. From there you can add/remove and otherwise manage translations of that string.

You can also bring up that interface programmatically:

```objc
TMLPresentTranslatorForKey([TMLTranslationKey generateKeyForLabel:@"<localized string>" description:@"<optional comment>"]);
```


Links
==================

* Register on TranslationExchange.com: http://translationexchange.com

* Read TranslationExchange's documentation: http://www.translationexchange.com/docs

* Follow TranslationExchange on Twitter: https://twitter.com/translationx

* Connect with TranslationExchange on Facebook: https://www.facebook.com/translationexchange

* If you have any questions or suggestions, contact us: info@translationexchange.com


Copyright and license
==================

Copyright (c) 2015 TranslationExchange.com

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

