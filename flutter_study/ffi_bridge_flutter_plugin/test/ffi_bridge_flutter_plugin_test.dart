import 'package:flutter_test/flutter_test.dart';
import 'package:ffi_bridge_flutter_plugin/ffi_bridge_flutter_plugin.dart';
import 'package:ffi_bridge_flutter_plugin/ffi_bridge_flutter_plugin_platform_interface.dart';
import 'package:ffi_bridge_flutter_plugin/ffi_bridge_flutter_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFfiBridgeFlutterPluginPlatform
    with MockPlatformInterfaceMixin
    implements FfiBridgeFlutterPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FfiBridgeFlutterPluginPlatform initialPlatform = FfiBridgeFlutterPluginPlatform.instance;

  test('$MethodChannelFfiBridgeFlutterPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFfiBridgeFlutterPlugin>());
  });

  test('getPlatformVersion', () async {
    FfiBridgeFlutterPlugin ffiBridgeFlutterPlugin = FfiBridgeFlutterPlugin();
    MockFfiBridgeFlutterPluginPlatform fakePlatform = MockFfiBridgeFlutterPluginPlatform();
    FfiBridgeFlutterPluginPlatform.instance = fakePlatform;

    expect(await ffiBridgeFlutterPlugin.getPlatformVersion(), '42');
  });
}
