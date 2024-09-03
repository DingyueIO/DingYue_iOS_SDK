#
# Be sure to run `pod lib lint DingYue_iOS_SDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DingYue_iOS_SDK'
  s.version          = '0.3.12'
  s.summary          = 'DingYue_iOS_SDK podspec file .'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: DingYue_iOS_SDK: manage your purchase process and collect data to analyze data conveniently
                       DESC

  s.homepage         = 'https://github.com/DingYueIO/DingYue_iOS_SDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DingYueIO' => 'support@dingyue.io' }
  s.source           = { :git => 'https://github.com/DingYueIO/DingYue_iOS_SDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'
  
  s.source_files = 'DingYue_iOS_SDK/Classes/**/*','DingYue_iOS_SDK/Libs/**/*.{h,m,swift}'
  s.vendored_libraries = 'DingYue_iOS_SDK/Libs/**/*.a'
  s.public_header_files = 'DingYue_iOS_SDK/Libs/**/*.h'
#  s.source_files = 'DingYue_iOS_SDK/Classes/**/*'
  
   s.resource_bundle = {
     'DingYue_iOS_SDK' => 'DingYue_iOS_SDK/Assets/Resources/Purchase/*'
   }

  s.swift_version = '4.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'FCUUID','~> 1.3.1'
  s.dependency 'AnyCodable-FlightSchool', '~> 0.6.1'
  s.dependency 'SSZipArchive', '~> 2.2.3'
#  s.dependency 'ActivityIndicatorView','~> 1.1.1'
  s.dependency 'NVActivityIndicatorView','~> 5.2.0'
  s.frameworks = 'Foundation', 'StoreKit'
  s.ios.framework = 'UIKit', 'iAd', 'AdSupport','AppTrackingTransparency'
  s.ios.weak_frameworks = 'AdServices'
  s.osx.frameworks = 'AppKit'
  s.osx.weak_frameworks = 'AdSupport', 'AdServices'
end
