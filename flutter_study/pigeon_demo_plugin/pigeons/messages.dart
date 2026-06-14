import 'package:pigeon/pigeon.dart';

/// Request object for asking the host platform to describe itself.
class DeviceInfoRequest {
  String? prefix;
}

/// Reply object returned by the host platform.
class DeviceInfoReply {
  String? platform;
  String? osVersion;
  String? model;
  String? message;
}

/// Request object for a tiny native calculation.
class CounterRequest {
  int? value;
}

/// Reply object for the native calculation.
class CounterReply {
  int? value;
  String? message;
}

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  dartOptions: DartOptions(),
  objcHeaderOut: 'ios/Classes/messages.g.h',
  objcSourceOut: 'ios/Classes/messages.g.m',
  objcOptions: ObjcOptions(
    prefix: 'PGN',
    headerIncludePath: 'messages.g.h',
  ),
  kotlinOut:
      'android/src/main/kotlin/com/example/pigeon_demo_plugin/Messages.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.example.pigeon_demo_plugin',
    errorClassName: 'PigeonDemoFlutterError',
  ),
))
@HostApi()
abstract class NativeDemoApi {
  DeviceInfoReply getDeviceInfo(DeviceInfoRequest request);

  CounterReply increment(CounterRequest request);
}
