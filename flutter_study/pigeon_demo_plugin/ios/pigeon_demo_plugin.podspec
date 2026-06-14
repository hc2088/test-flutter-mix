Pod::Spec.new do |s|
  s.name             = 'pigeon_demo_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A small Flutter plugin demo that uses Pigeon.'
  s.description      = <<-DESC
A small Flutter plugin demo that uses Pigeon for type-safe platform channels.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Demo' => 'demo@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.resource_bundles = { 'pigeon_demo_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
