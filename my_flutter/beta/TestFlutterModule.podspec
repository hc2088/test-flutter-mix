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

  # === 路径定义 ===
  fdebug = 'framework/Debug/App.xcframework'
  frelease = 'framework/Release/App.xcframework'

  # === 打印当前 build_mode ===
  build_mode = ENV['build_mode'] || 'release'
  puts "[TestFlutterModule.podspec] 当前 build_mode = #{build_mode}"

  # === 校验文件是否存在 ===
  selected_path = build_mode == 'debug' ? fdebug : frelease
  unless File.exist?(File.join(__dir__, selected_path))
    puts "⚠️  警告: 选择的 xcframework 不存在: #{selected_path}"
  else
    puts "✅  使用的 xcframework: #{selected_path}"
  end

  # === 配置 vendored_frameworks ===
  s.exclude_files = build_mode == 'debug' ? frelease : fdebug
  s.ios.vendored_frameworks = selected_path

  # === 依赖 Flutter 引擎 ===
  s.dependency 'Flutter'
end
