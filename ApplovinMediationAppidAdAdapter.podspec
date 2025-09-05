Pod::Spec.new do |s|
  s.name             = 'ApplovinMediationAppidAdAdapter'
  s.version          = '1.0.0.0'
  s.summary          = 'AppicAd Adapter for AppLovin MAX'
  s.description      = 'AppicAd adapter for AppLovin MAX mediation.'
  s.homepage         = 'https://github.com/dongyutq/AppicAdSpecs-Adapter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'guo tianqi' => 'guotianqi@apicmob.com' }
  s.source           = { :git => 'https://github.com/dongyutq/AppicAdSpecs-Adapter.git', :tag => s.version }

  s.platform     = :ios, '11.0'
  s.swift_version = '5.0'

  s.source_files = 'Classes/**/*.{h,m}'

  s.dependency 'AppLovinSDK'
  s.dependency 'AppicAd-SDK'
  s.static_framework = true
end