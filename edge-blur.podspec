#
# Be sure to run `pod lib lint edge-blur.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'edge-blur'
  s.version          = '0.1.0'
  s.summary          = 'Variable and AlphaMask modifiers for SwiftUI.'
  
  s.description      = 'Variable and AlphaMask modifiers for SwiftUI. (https://github.com/Aemi-Studio/AemiSDR)'
  
  s.homepage         = 'https://github.com/gtokman/edge-blur'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Gary Tokman' => 'yo@garytokman.com' }
  s.source           = { :git => 'https://github.com/gtokman/edge-blur.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/f6ary'
  s.ios.deployment_target = '18.0'
  
  s.source_files = 'edge-blur/Classes/**/*'
  
  s.resource_bundles = {
    'edge-blur' => [
    'edge-blur/Classes/Resources/AemiSDR.metallib',
    'edge-blur/Classes/Shaders/AemiSDR.ci'
    ]
  }
end
