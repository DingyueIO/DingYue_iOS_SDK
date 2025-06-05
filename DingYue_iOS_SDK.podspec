Pod::Spec.new do |s|
  s.name             = 'DingYue_iOS_SDK'
  s.version          = '0.3.15'
  s.summary          = 'DingYue_iOS_SDK: manage your purchase process and collect data to analyze data conveniently.'

  s.description      = <<-DESC
DingYue_iOS_SDK: This SDK helps manage the purchase process and provides tools to collect and analyze data.
DESC

  s.homepage         = 'https://github.com/DingYueIO/DingYue_iOS_SDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DingYueIO' => 'support@dingyue.io' }
  s.source           = { :git => 'https://github.com/DingYueIO/DingYue_iOS_SDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  # Source files and resources
  s.source_files     = 'DingYue_iOS_SDK/Classes/**/*.{h,m,swift}'
  s.vendored_frameworks = 'DingYue_iOS_SDK/Libs/Lua/DingYueLua.xcframework'
  s.resource_bundle = { 'DingYue_iOS_SDK' => 'DingYue_iOS_SDK/Assets/Resources/Purchase/*' }

  # Swift version and framework dependencies
  s.swift_version    = '4.0'

  s.dependency 'FCUUID', '~> 1.3.1'
  s.dependency 'AnyCodable-FlightSchool', '~> 0.6.7'
  s.dependency 'SSZipArchive', '~> 2.4.3'
  s.dependency 'NVActivityIndicatorView', '~> 5.2.0'

  # Frameworks and system libraries
  s.frameworks = 'Foundation', 'StoreKit'
  s.ios.framework = 'UIKit', 'iAd', 'AdSupport', 'AppTrackingTransparency'
  s.ios.weak_frameworks = 'AdServices'
  s.osx.frameworks = 'AppKit'
  s.osx.weak_frameworks = 'AdSupport', 'AdServices'
end
