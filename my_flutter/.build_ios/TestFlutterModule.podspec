Pod::Spec.new do |s|
  s.name                  = 'TestFlutterModule'
  s.version               = '0.0.1'
  s.summary               = 'Flutter module'
  s.description           = 'Flutter module - flutter_commercial'
  s.homepage              = 'https://flutter.dev'
  s.license               = { :type => 'BSD' }
  s.author                = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source                = { :path => '.' }
  s.ios.deployment_target = '9.0'

  fdebug = 'framework/Debug/App.xcframework'
  frelease = 'framework/Release/App.xcframework'
  s.exclude_files =           ENV['build_mode'] == 'debug' ?  frelease : fdebug
  s.ios.vendored_frameworks = ENV['build_mode'] == 'debug' ?  fdebug : frelease

  s.dependency 'Flutter'
end
