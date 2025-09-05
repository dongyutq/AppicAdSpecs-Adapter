# AppicAdSpecs-Adapter

AppicAdAdapter is the official adapter that connects AppicAd SDK with AppLovin MAX mediation.

## Installation

To use this adapter, you need to configure your Podfile with both the official CocoaPods specs repo and our private specs repo:

    source 'https://github.com/CocoaPods/Specs.git'

    source 'https://github.com/dongyutq/AppicAdSpecs.git'

    platform :ios, '11.0'

    target 'YourAppTarget' do
      pod 'ApplovinMediationAppidAdAdapter'
    end

Then run:

    pod install

## Notes
>• The AppicAdAdapter depends on both:
>
>>AppicAd-SDK (provided through the private specs repo above)
>>
>>AppLovinSDK (public CocoaPods repo)
>
>• Make sure to include the private specs source (AppicAdSpecs) in your Podfile, otherwise CocoaPods will not be able to resolve AppicAd-SDK.
