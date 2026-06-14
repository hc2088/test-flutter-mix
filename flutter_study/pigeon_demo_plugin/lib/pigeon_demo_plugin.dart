import 'src/messages.g.dart';

export 'src/messages.g.dart'
    show CounterReply, CounterRequest, DeviceInfoReply, DeviceInfoRequest;

class PigeonDemoPlugin {
  PigeonDemoPlugin({NativeDemoApi? api}) : _api = api ?? NativeDemoApi();

  final NativeDemoApi _api;

  Future<DeviceInfoReply> getDeviceInfo({String prefix = 'Flutter'}) {
    return _api.getDeviceInfo(DeviceInfoRequest(prefix: prefix));
  }

  Future<CounterReply> increment(int value) {
    return _api.increment(CounterRequest(value: value));
  }
}
