import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  //未被捕获的异常 ,无法被 try-catch 捕获的错误处理。
  //捕获 Dart 中同步和部分异步代码

  //在 Dart 中，runZonedGuarded 只能捕获当前 Isolate 中未捕获的异常，
  // 无法捕获其他 Isolate（如通过 compute 创建的）中的异常，
  // 因为 Dart 的每个 Isolate 是完全独立的内存和执行上下文。
  runZonedGuarded(() {
    runApp(MyApp());

    // 异步 Future 中的错误，能被捕获
    Future.delayed(Duration(seconds: 1), () {
      throw Exception("异步 Future 抛出的异常");
    });

    // 同步错误，也能被捕获
    throw Exception("同步异常");
  }, (error, stackTrace) {
    print("捕获异常：$error");
  });
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
