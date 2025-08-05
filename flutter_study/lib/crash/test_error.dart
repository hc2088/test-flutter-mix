import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  // runApp(MyApp());

  //空指针、未捕获异常、类型错误等
  //未捕获异常是指：
  //UI 层异常 → FlutterError.onError 处理
  //
  //         build() 方法里抛的异常
  //
  //        setState() 内抛出的异常
  //
  //        Widget 生命周期方法中的异常
  //
  //
  // 如果不设置，Flutter 默认会打印异常并闪退，但不一定能上报。
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(details.exception, details.stack!);
  };

  //这里的未捕获异常是指：
  // 用于捕获当前 Dart Isolate 中未被捕获的同步或异步异常，包括：
  //
  //      Future 里未处理的异常
  //
  //      Stream 里的异常
  //

  //

  runZonedGuarded(() {
    runApp(MyApp());
  }, (Object error, StackTrace stackTrace) {
    print('捕获到未处理异常：$error');
  });

  //Dart 层异步异常 → runZonedGuarded 处理
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
/*
*release环境flutter会崩溃吗？ 如果没有native插件相关的报错的话，
* 只是flutter framework层和isolate底层的异常的话，比如framework层的空指针
* ，类型错误等， 我指的是抛开使用到flutter插件中natvie层发生的崩溃
*
* release 环境下 Flutter 应用如果没有涉及 native 插件相关的崩溃，
* 且崩溃仅来自 Flutter framework 层（Dart 层）或 isolate 层的异常，比如空指针、类型错误等，
* 通常 不会导致进程直接崩溃（crash），而是会表现为异常抛出、应用逻辑错误或 UI 不正常，但进程仍然存活。

  详细说明：
  1、Dart 层异常的表现

  Flutter framework 层（如空指针、类型错误等）抛出的异常会被 Dart VM 捕获，
  默认会触发异常回调（如 FlutterError.onError）并打印错误信息。

      如果没有被捕获，异常会沿调用栈向上传播，最终导致对应的 Future 或事件回调失败。

      但这类异常不会直接导致 APP 进程崩溃（native crash），而是 Dart 层的异常机制处理。

  2、Isolate 层异常

  如果 isolate 内部异常未捕获，也不会导致整个 app 崩溃。

      isolate 会自行终止，但主 isolate 继续运行。

      Dart isolate 是相互隔离的，单个 isolate 异常不会传递成 native 崩溃。

  对比 native crash

      native 层崩溃（如段错误 SIGSEGV、野指针访问等）才会导致 APP 进程崩溃并退出。

      这通常发生在调用第三方插件 native 代码或底层系统调用时。
* */
