import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

final DynamicLibrary dl = Platform.isAndroid
    ? DynamicLibrary.open('libfairflutter.so')
    : DynamicLibrary.open('FFIDynamicFlutter.framework/FFIDynamicFlutter');

class FfiBridgeFlutterPlugin {
  Pointer<Utf8> Function(Pointer<Utf8>) invokeJSCommonFuncSync = dl
      .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>(
          'invokeCommonFuncSync')
      .asFunction();

  // static const MethodChannel methodChannel =
  //     const MethodChannel('ffi_bridge_flutter_plugin');
  //
  // Future<String?> getPlatformVersion() async {
  //   final version =
  //       await methodChannel.invokeMethod<String>('getPlatformVersion');
  //   return version;
  // }

  //  sendCommonMessageSync(jsonEncode(from));
  //实际调用时，必须转成 String
  //如果你传进来 dynamic 类型的 msg 不是 String，代码就会抛异常。
  // dynamic sendCommonMessageSync(dynamic msg) =>
  //     FairUtf8.fromUtf8(invokeJSCommonFuncSync.call(FairUtf8.toUtf8(msg)));

  dynamic sendCommonMessageSync(dynamic msg) {
    String str;
    if (msg is String) {
      str = msg;
    } else {
      // 其它类型转成 JSON 字符串
      str = jsonEncode(msg);
    }
    return FairUtf8.fromUtf8(invokeJSCommonFuncSync.call(FairUtf8.toUtf8(str)));
  }
}

class FairUtf8 {
  static String fromUtf8(Pointer<Utf8> data) {
    return data.toDartString();
  }

  //实际调用时，必须转成 String
  static dynamic toUtf8(String data) {
    return data.toNativeUtf8();
  }
}
