import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // compute 所在的包
// compute 本质是开启一个新的 Isolate，异常不会被外层 runZonedGuarded 捕获。
//
// 要捕获 compute 内部的异常，需要用 try-catch 包住 await compute(...)。
//
// runZonedGuarded 主要用于捕获当前 Isolate 中未被捕获的异步异常。
void main() {
  runZonedGuarded(() async {
    print("启动 runZonedGuarded");

    try {
      await compute(crashInIsolate, '参数'); // 调用子 isolate
    } catch (e, stack) {
      print('main isolate 捕获 compute 抛出的异常: $e');
    }

    print('main isolate 继续运行');
  }, (error, stack) {
    print('runZonedGuarded 捕获异常: $error');
  });
}

Future<void> crashInIsolate(String message) async {
  // 模拟子 isolate 中的异步异常
  throw Exception("子 isolate 抛出的异常: $message");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(),
      ),
    );
  }
}
