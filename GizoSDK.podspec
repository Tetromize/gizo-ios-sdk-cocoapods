Pod::Spec.new do |s|
  s.name             = 'GizoSDK'
  s.version          = '1.0.10'
  s.swift_versions   = '5'
  s.summary          = 'A comprehensive SDK for integrating advanced functionalities provided by GIZO in iOS apps.'
  s.description      = <<-DESC
                        GizoSDK offers advanced features and integrations for iOS applications, including Mapbox Maps, Mapbox Navigation, and additional support for Python and NumPy operations within iOS environments. It leverages both binary and source targets to deliver a powerful toolset for developers.
                       DESC
  s.homepage         = 'https://github.com/artificient-ai/gizo-ios-sdk-cocoapods-alpha'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tech' => 'tech@artificient.de' }
  s.source           = { :http => "https://github.com/artificient-ai/gizo-ios-sdk-cocoapods-alpha/raw/#{s.version}/GizoSDK/#{s.version}/GizoSDK.zip" }
  s.platform = :ios, '13.0'
  s.vendored_frameworks = 'GizoSDK.xcframework'
end
