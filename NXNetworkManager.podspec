Pod::Spec.new do |s|
s.name         = 'NXNetworkManager'
s.version      = '0.1.3'
s.summary      = 'NXNetworkManager base on AFNetwroking'
s.homepage     = 'https://github.com/qufeng33/NXNetworkManager'
s.license      = 'MIT'
s.author       = { 'nightx' => 'qufeng33@hotmail.com' }
s.platform     = :ios, '7.0'
s.source       = { :git => 'https://github.com/qufeng33/NXNetworkManager.git', :tag => s.version.to_s }
s.source_files = 'NXNetworkManager/**/*'
s.requires_arc = true
s.frameworks   = 'UIKit'
s.dependency "AFNetworking", "~> 3.1.0"
s.dependency "CocoaLumberjack", "~> 2.3.0"
end