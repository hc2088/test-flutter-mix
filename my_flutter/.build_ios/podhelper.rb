# frozen_string_literal: true

require 'json'

def install_all_flutter_pods
  install_flutter_engine_pod
  install_flutter_plugin_pods
  install_flutter_application_pod
end

def install_flutter_engine_pod
  current_directory = File.expand_path(__dir__)

  fdebug = 'framework/Debug/Flutter.podspec'
  frelease = 'framework/Release/Flutter.podspec'

  engine_dir = Pathname.new File.expand_path(ENV['build_mode'] == 'debug' ? fdebug : frelease, current_directory)

  relative = engine_dir.relative_path_from defined_in_file.dirname
  
  puts "relative is " + relative.to_s

  pod 'Flutter', podspec: relative.to_s, inhibit_warnings: true
end

def install_flutter_plugin_pods
  current_directory = File.expand_path(__dir__)
  symlinks_dir = File.join(current_directory, 'plugins')

  plugins_file = File.expand_path('flutter-plugins-dependencies', current_directory)

  plugin_pods = flutter_parse_dependencies_file_for_ios_plugin(plugins_file)

  plugin_pods.each do |plugin_hash|
    plugin_name = plugin_hash['name']
    plugin_path = plugin_hash['path']

    next unless plugin_name && plugin_path

    symlink = Pathname.new File.join(symlinks_dir, plugin_name, 'ios')

    relative = symlink.relative_path_from defined_in_file.dirname
    puts relative

    pod plugin_name, path: relative.to_s, inhibit_warnings: true
  end

  flutterPluginRegistrantpath = Pathname.new File.join(current_directory, 'FlutterPluginRegistrant')
  relative = flutterPluginRegistrantpath.relative_path_from defined_in_file.dirname

  puts "relative is " + relative.to_s

  pod 'FlutterPluginRegistrant', path: relative.to_s, inhibit_warnings: true
end

def install_flutter_application_pod
  current_directory_pathname = Pathname.new File.expand_path(__dir__)

  project_directory_pathname = defined_in_file.dirname

  relative = current_directory_pathname.relative_path_from project_directory_pathname

  puts "relative is " + relative.to_s

  pod 'TestFlutterModule', path: relative.to_s, inhibit_warnings: true
end

def flutter_parse_dependencies_file_for_ios_plugin(file)
  file_path = File.expand_path(file)
  return [] unless File.exist? file_path

  dependencies_file = File.read(file)
  dependencies_hash = JSON.parse(dependencies_file)

  return [] unless dependencies_hash.key?('plugins')
  return [] unless dependencies_hash['plugins'].key?('ios')

  dependencies_hash['plugins']['ios'] || []
end
