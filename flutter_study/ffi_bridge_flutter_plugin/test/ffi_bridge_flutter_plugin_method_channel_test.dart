import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ffi_bridge_flutter_plugin/ffi_bridge_flutter_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFfiBridgeFlutterPlugin platform = MethodChannelFfiBridgeFlutterPlugin();
  const MethodChannel channel = MethodChannel('ffi_bridge_flutter_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
