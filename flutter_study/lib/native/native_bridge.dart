import 'package:flutter/services.dart';

typedef MessageHandler = void Function(String message);

class NativeBridge {
  static const _channel = MethodChannel("com.example/native_channel");

  static MessageHandler? _onMessage;

  /// 初始化，通知 iOS Flutter 已经 ready，并设置消息回调
  static Future<void> init({MessageHandler? onMessage}) async {
    _onMessage = onMessage;

    // Dart isolate 准备好，通知 iOS
    await _channel.invokeMethod("markFlutterReady");

    // 设置 iOS → Flutter 的消息监听
    _channel.setMethodCallHandler((call) async {
      if (call.method == "sendMessageToFlutter") {
        final msg = call.arguments?.toString() ?? "";
        _onMessage?.call(msg);
      }
    });
  }

  /// Flutter 主动调 iOS
  static Future<String?> getNativeMessage() async {
    try {
      final result = await _channel.invokeMethod<String>("getNativeMessage");
      return result;
    } catch (e) {
      return "调用失败: $e";
    }
  }
}
