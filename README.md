<p align="center">
  <img src="https://avatars0.githubusercontent.com/u/1316274?v=3&s=200">
</p>

Tml for Objective C
==================

[![Version](http://cocoapod-badges.herokuapp.com/v/Tml/badge.png)](http://cocoadocs.org/docsets/Tml)
[![Platform](http://cocoapod-badges.herokuapp.com/p/Tml/badge.png)](http://cocoadocs.org/docsets/Tml)
[![Build Status](https://travis-ci.org/translationexchange/tml-objc.svg?branch=master)](https://travis-ci.org/translationexchange/tml-objc)

Tml SDK for Objective C is an integrated cloud-based translation solution for iOS applications.

It reduces the number of steps required for internationalization and localization of your mobile applications.

Tml SDK integrates with TranslationExchange.com service, where you can manage the entire translation process - enable languages, invite translators, manage translation keys, and much more.

You never have to touch the resource bundle files - translation keys are extracted from your app's source code on the fly and kept up to date by the SDK.

Once your app is translated, the translations will automatically be downloaded and installed by the SDK. You DO NOT need to submit a new application to the App Store. You can simply enable a new language on TranslationExchange.com and it will immediately be available in your application.

https://github.com/translationexchange/tml-docs/blob/master/objc/iphone.gif

Demo Applications
==================

To run the sample project, follow these steps:

```sh
$ git clone https://github.com/translationexchange/tml-objc.git
$ cd tml-objc/Project
$ pod install
$ open Demo.xcworkspace
```

Run the application. Open the language selector and change language.

Another sample application is located here:

https://github.com/translationexchange/tml-objc-samples-wammer


Requirements
==================

	iOS 7
	CocoaPods



Installation
==================


Tml SDK is available through [CocoaPods](http://cocoapods.org). To install the SDK, simply add the following line to your Podfile:

```ruby
pod "Tml"
```

Integration
==================


Before you can proceed with the integration, please visit https://TranslationExchange.com - open an account and register your application. Once you register your app, it will be assigned a unique key and secret.

You only need to provide the secret in the application while you test or translate your app. Apps that have a secret can register new translation keys on the server. When you release your application you should remove the secret and only supply the key.

Tml SDK comes with the English language configuration by default. So if your app's base language is English, you can try out the SDK without even having to initialize it. You get full power of TML and internationalization macros that would improve your code and provide powerful utilities for working with English language. Tml provides default inflectors, pluralizers, contextualizer and language cases.

On the other hand, you should initialize the Tml SDK if you plan on taking advantage of the continues integration with TranslationExchange platform, translation memory and analytics.


```objc
#import "Tml.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [Tml sharedInstanceWithToken: YOUR_TOKEN];

  return YES;
}
```

How does it work?
==================

Tml SDK does all the hard work for you. When you use Tml's macros, the library automatically registers translation keys with Translation Exchange service and generates resource bunldes for your app on the fly. Tml always keep your local cache up to date by downloading the latest translations from the service when they become available. At run-time, your app will use translations from your local app cache so your users will not experience any delays.

You have an option to pre-cache all your translations in your app before you release it. In that case, the SDK will run in the offline mode. But keeping the SDK connected allows you to release new languages without having to rebuild your app. You will also be able to take advantage of the analytics that show you what languages are used in your app, what the default languages of your users are, where your users are coming from, etc...


Internationalization & TML
==================

If your application is already internationalized using the standard NSLocalizedString methods, you can simply import the Tml.h header in your .m file and Tml will take over the internationalization macros.

```objc
#import "Tml.h"
```

Tml also provides its own macros for internationalization that enhance the standard iOS macros.

```objc
TmlLocalizedString(label)
```

Example:

```objc
TmlLocalizedString(@"Hello World")
```

This macro is similar to NSLocalizedString, but it does not require the optional comment to be passed as nil.


```objc
TmlLocalizedStringWithDescription(label, description)
```

Example:

```objc
TmlLocalizedStringWithDescription(@"Invite", @"Invite someone to join the group")
```

```objc
TmlLocalizedStringWithDescription(@"Invite", @"An invite received from a friend")
```

Unlike NSLocalizedString, where the second parameter is a comment for a translator, Tml uses the description to contextualize the key. So the above example would actually register two distinct keys, where each would have its own translations.


```objc
TmlLocalizedStringWithTokens(label, tokens)
```

Example: 

```objc
TmlLocalizedStringWithTokens(@"You have {count || message}.", @{@"count": @4})
TmlLocalizedStringWithTokens(@"Hello {user}.", @{@"user": @"Michael"})
```

```objc
User *user  = [[User alloc] initWithName: @"Michael" gender: @"male"];
// will use [user description] for substitution value
TmlLocalizedStringWithTokens(@"Hello {user}.", @{@"user": user})
// second parameter is used for substitution value
TmlLocalizedStringWithTokens(@"Hello {user}.", @{@"user": @[user, user.name]})
TmlLocalizedStringWithTokens(@"Hello {user}.", @{@"user": @[user, @"Mike"]})
```

```objc
NSDictionary *user = @{@"name": @"Michael", @"gender": @"male"};
// can be used for context rules, but not substitution value
TmlLocalizedStringWithTokens(@"{user | Born On}.", @{@"user": user})
TmlLocalizedStringWithTokens(@"Hello {user}.", @{
          @"user": @{@"object": user, @"property": @"name"}
})
TmlLocalizedStringWithTokens(@"Hello {user}.", @{
          @"user": @{@"object": user, @"value": @"Michael"}
})
```

Tokens can be passed in many different ways. If the token is passed as a primitive type, it would be used for both context rules and displayed value. If it is passed a class or a structure, you can separate the object being used for context rules and the value that would be substituted for the token.

```objc
TmlLocalizedStringWithDescriptionAndTokens(label, description, tokens)
```

Example: 

```objc
TmlLocalizedStringWithDescriptionAndTokens(
    @"Hello {user}",
    @"A greeting message",
    @{@"user": @"Michael"}
)
```

Same as the two examples above - allows you to provide both description and tokens.


```objc
TmlLocalizedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options)
```

Example: 

```objc
TmlLocalizedStringWithDescriptionAndTokensAndOptions(
    @"Hello {user}",
    @"A greeting message",
    @{@"user": @"Michael"},
    @{@"level": @5, @"max-length": @20}
)
```

Only translators of a specific rank are allowed to translate keys of a specific level. The constraint indicate that the translations of this key may not be longer than 20 chars. See wiki.translationexchage.com for more details.


```objc
TmlLocalizedStringWithTokensAndOptions(label, tokens, options)
```

Example: 

```objc
TmlLocalizedStringWithTokensAndOptions(
    @"You have {count || message}.",
    @{@"count": @4},
    @{@"max-length": @20}
)
```

Allows you to skip the description.


```objc
TmlLocalizedStringWithOptions(label, options)
```

Example: 

```objc
TmlLocalizedStringWithOptions(@"Hello World", @{@"max-length": @20})
```

Allows you to skip description and tokens.



All of the above macros assume that you are working with HTML and will return HTML markup for decorated tokens. For example:

```objc
TmlLocalizedStringWithTokens(
    @"You have completed [bold: {count || mile}] on your last run.",
    @{@"count": @4.2}
)
```

Will result in: 

```html
	"You have completed <strong>4.2 miles</strong> on your last run."
```

Unless you render it in a browser, you should not use decoration tokens with the above methods. Instead, you should use the Attributed String macros.



Default Tokens
======================

For tokens that you want to define in once and reuse throughout your application, you can pre-define them in Tml configuration, using the following approach:

```objc
[Tml configure:^(TmlConfiguration *config) {
  [config setDefaultTokenValue: @"<strong>{$0}</strong>"
                       forName: @"bold"
                          type: @"decoration"
                        format: @"html"];

  [config setDefaultTokenValue: @"<span style='color:green'>{$0}</span>"
                       forName: @"green"
                          type: @"decoration"
                        format: @"html"];

  [config setDefaultTokenValue: @{
                     @"font": @{
                        @"name": @"system",
                        @"size": @12,
                        @"type": @"italic"
                     },
                     @"color": @"blue"
                   }
                       forName: @"bold"
                          type: @"decoration"
                        format: @"attributed"];

  [config setDefaultTokenValue: @{
                     @"shadow": @{
                        @"offset": @1,1,
                        @"radius": @0.5,
                        @"color": @"grey"
                     },
                     @"color": @"black"
                                   }
                       forName: @"shadow"
                          type: @"decoration"
                        format: @"attributed"];

  [config setDefaultTokenValue: @"My App Name"
                       forName: @"app_name"
                          type: @"data"];
}];
```

Alternatively, you can provide token values inline, which would overwrite the default token definitions.

The following examples will use the above pre-defined tokens.


AttributedString Macros
======================

Attributed String macros are very similar to the above macros, but will always return an NSAttributedString instead of plain NSString.

```objc
TmlLocalizedAttributedString(label)
```

Examples:

```objc
TmlLocalizedAttributedString(@"Hello World")
TmlLocalizedAttributedString(@"Hello [bold: World]")
TmlLocalizedAttributedString(@"This [bold: technology is [shadow: very cool]].")
```

Notice that "very cool" will be bold and have a shadow. Nesting tokens inherits the parent token traits.


The other Attributed String macros are as follow:

```objc
TmlLocalizedAttributedStringWithDescription(label, description)
TmlLocalizedAttributedStringWithDescriptionAndTokens(label, description, tokens)
TmlLocalizedAttributedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options)
TmlLocalizedAttributedStringWithTokens(label, tokens)
TmlLocalizedAttributedStringWithTokensAndOptions(label, tokens, options)
TmlLocalizedAttributedStringWithOptions(label, options)
```

The previous example that used HTML as decoration can now be rewritten using the following method:

```objc
TmlLocalizedAttributedStringWithTokens(
    @"You have completed [bold: {count || mile}] on your last run.",
    @{@"count": @4.2}
)
```

This would result in and NSAttributedString with the following value:


  "You have completed **4.2 miles** on the last run."


NSAttributedString vs TmlLocalizedAttributedString
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
TmlLocalizedAttributedStringWithTokens(
    @"You have completed [bold: {count || mile}] on your last run.",
    @{@"count": @4.2}
)
```

Which is easily translated to Russian:

    "Вы пробежали [bold: {count || милю, мили, миль}] в вашем последнем забеге."


Since there are languages, like Hebrew, which depend on the gender of the viewing user, any time you refer to "You", you should always pass the viewing_user as a token.

```objc
TmlLocalizedAttributedStringWithTokens(@"You have completed [bold: {count || mile}] on your last run.", @{@"count": @4.2, @"viewing_user": currentUser})
```

Or better yet, set it in the configuration, and then you never have to pass it as a token:

```objc
[Tml configure:^(TmlConfiguration *config) {
    config.viewingUser = currentUser;
}];
```


Here is a more complicated example:

```objc
TmlLocalizedAttributedStringWithTokens(
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


Translating UIViews
==================

Tml can automatically translate views for you with one line of code. Consider the following example:

```objc
#import "UIViewController+Tml.h"

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector(localize)
               name: TmlLanguageChangedNotification
             object: self.view.window];

    [self localize];
}


- (void) localize {
    TmlLocalizeView(self.view);
}
```

The above code will translate your entire user interface every time a new language is selected.


Language Selector
==================


Tml SDK comes with a language selector that you can use in your application. To open the langugae selector from a view controller, use the following code:

```objc
#import "TmlLanguageSelectorViewController.h"

[TmlLanguageSelectorViewController changeLanguageFromController:self];
```

In-App Translator
==================


Tml comes with an In-App translator, so users of your app can sign up and translate your app from within your app. To open the in-app translator, use the following code:

```objc
#import "TmlTranslatorViewController.h"

[TmlTranslatorViewController translateFromController:self];
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

