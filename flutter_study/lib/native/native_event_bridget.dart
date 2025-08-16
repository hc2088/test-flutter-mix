import 'package:flutter/services.dart';

class NativeEventBridge {
  static const EventChannel _eventChannel =
  EventChannel("com.example/native_event_channel");

  /// 监听来自 iOS 的事件流
  static Stream<dynamic> get events => _eventChannel.receiveBroadcastStream();
}
