Pod::Spec.new do |s|
  s.name                      = "TMLKit"
  s.version                   = "1.0.11"
  s.summary                   = "Translation Markup Language for Objective C."
  s.homepage                  = "https://github.com/translationexchange/tml-objc"

  s.license                   = 'MIT'
  s.author                    = { "Michael Berkovich" => "michael@translationexchnage.com" }
  s.source                    = { :git => "https://github.com/translationexchange/tml-objc.git", :tag => s.version.to_s }
  s.social_media_url          = 'https://twitter.com/translationx'

  s.platform                  = :ios
  s.ios.deployment_target     = '8.0'
  s.requires_arc              = true

  s.resources                 = 'Assets/**/*'

  #s.public_header_files       = 'Classes/**/*.h', 'TMLKit/TMLKit/**/*.h'
  s.prefix_header_file	      = 'TMLKit/TMLKit/TMLKit-Prefix.pch'
  s.source_files              = 'Classes/**/*.{h,m}', 'TMLKit/TMLKit/**/*.{h,m}'

  s.dependency 'MPColorTools', '>= 1.6'
  s.dependency 'MBProgressHUD'
  s.dependency 'SSZipArchive'
  s.dependency 'NVHTarGzip'
  s.dependency 'SAMKeychain'

  s.description               = <<-DESC
Tml for Objective C is the most advanced translation solution for iOS applications.

It reduces the number of steps required for translating an app to the absolute minimum. All you need to do is to include the Tml header file in your app, initialize the SDK and use the various translation macros to internationalize your content.

The SDK comes with its own language selector, where users can switch languages. Or you can use the language set by the OS.

It also comes with In-App Translator - where you can ask your users to help translate your app right from within your app.

Tml SDK integrates with TranslationExchange.com service, where you can manage the entire translation process - add new languages, invite translators, manage phrases, and much more.

Once the translations are done, they will be automatically downloaded and installed by the SDK in your app. Everything is done real-time - you DO NOT need to submit a new application to the App Store. You can simply enable a new language on TranslationExchange and it will immediately be available in your application.

You can learn more about the SDK by visiting the project's GitHub page:
    
    https://github.com/translationexchange/tml-objc

or running sample applications:

Demo app that comes with the SDK:

    https://github.com/translationexchange/tml-objc/tree/master/Project

“Wammer” application that shows how the SDK can be integrated into a messaging app:

    https://github.com/translationexchange/tml-objc-samples-wammer

DESC


end
