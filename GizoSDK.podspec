Pod::Spec.new do |s|
  s.name             = 'GizoSDK'
  s.version          = '1.0.0'
  s.swift_versions   = '5'
  s.summary          = 'A comprehensive SDK for integrating advanced functionalities provided by GIZO in iOS apps.'
  s.description      = <<-DESC
                        GizoSDK offers advanced features and integrations for iOS applications, including Mapbox Maps, Mapbox Navigation, and additional support for Python and NumPy operations within iOS environments. It leverages both binary and source targets to deliver a powerful toolset for developers.
                       DESC
  s.homepage         = 'https://github.com/artificient-ai/gizo-ios-sdk-cocoapods-alpha'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tech' => 'tech@artificient.de' }
  s.source           = { :http => 'https://github.com/artificient-ai/gizo-ios-sdk-cocoapods-alpha/raw/1.0.0/GizoSDK/1.0.0/GizoSDK.zip' }
  s.platform = :ios, '13.0'
  s.dependency 'MapboxMaps', '10.12.3'
  s.dependency 'MapboxNavigation', '2.12.0'
  s.dependency 'SnapKit', '5.6.0'
  s.libraries        = 'z', 'bz2', 'sqlite3'
  s.frameworks       = 'CoreML', 'SystemConfiguration'
end
