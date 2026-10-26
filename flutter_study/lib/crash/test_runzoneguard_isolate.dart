import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

late String str;
RawReceivePort? _currentIsolateErrorPort;

// 本例子中， 有了 runZonedGuarded 的errorback ，
// PlatformDispatcher.instance.onError
// 和Isolate.current.addErrorListener 就是多余的，根本不调用
// FlutterError.onError 这玩意只有我们手动调用 FlutterError.reportError才有用。
// 框架层调用 FlutterError.reportError，不需要我们手动设置FlutterError.onError，就能调用了，此时也是多余。
void main() {
  runZonedGuarded(() async {
    // Flutter binding 初始化和 runApp 放在同一个 Zone 中。
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Flutter 框架捕获的错误通过 FlutterError.onError 上报。
    FlutterError.onError = (FlutterErrorDetails details) {
      _reportError(details.exception, details.stack ?? StackTrace.empty);
    };

    // 2. 当前 isolate 中未被 Flutter 框架捕获的错误通过 PlatformDispatcher 上报。
    PlatformDispatcher.instance.onError =
        (Object exception, StackTrace stackTrace) {
      _reportError(exception, stackTrace);
      return true;
    };

    // 3. 注册当前 isolate 的 VM 错误端口，处理未被 Zone 等机制捕获的 isolate 错误。
    _registerCurrentIsolateErrorListener();

    print("启动 runZonedGuarded");

    str = "1231231";
    runApp(const MyApp());
    // 回调在当前 Zone 中执行；未处理的 Future 错误会交给 Zone 的错误处理器。
    Future.delayed(Duration(seconds: 1), () {
      throw Exception("异步 Future 抛出的异常");
    });

    // async 函数中的 throw 会让返回的 Future 以错误结束；未处理时由当前 Zone 捕获。
    compute(crashInIsolate, '参数'); // 原生平台使用子 isolate；Web 平台在当前事件循环执行。

    throw Exception("同步异常");
  }, (error, stack) {
    // Zone 中未处理的错误也统一交给同一个上报入口。
    _reportError(error, stack);
  });
}

bool _reportError(Object error, StackTrace stackTrace) {
  // 本项目尚未配置 firebase_crashlytics；接入后在此调用 recordError。
  // 目前返回 false，让 Flutter 保留默认错误输出。
  debugPrint(error.toString());
  debugPrintStack(stackTrace: stackTrace);
  return false;
}

void _registerCurrentIsolateErrorListener() {
  if (_currentIsolateErrorPort != null) return;

  final port = RawReceivePort((dynamic message) {
    final pair = message as List<dynamic>;
    final errorText = pair[0] as String;
    final stackText = pair[1] as String?;
    final remoteError = RemoteError(errorText, stackText ?? '');
    _reportError(remoteError, remoteError.stackTrace);
  });

  _currentIsolateErrorPort = port;
  Isolate.current.addErrorListener(port.sendPort);
}

Future<void> crashInIsolate(String message) async {
  print(str);
  // 模拟子 isolate 中的异步异常
  throw Exception("子 isolate 抛出的异常: $message");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter 异常捕获示例')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  // 模拟框架主动调用 FlutterError.reportError。
                  FlutterError.reportError(
                    FlutterErrorDetails(
                      exception: StateError('Flutter 框架错误示例'),
                      library: 'test_error.dart',
                    ),
                  );
                },
                child: const Text('触发 FlutterError.onError'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // onPressed 不会等待这个 Future；await 后抛出的错误未处理时会交给当前 Zone。
                  await Future<void>.delayed(Duration.zero);
                  throw StateError('异步回调错误示例');
                },
                child: const Text('Future 未捕获异常'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Timer 在当前 Zone 中安排；回调抛出的未处理错误会交给 Zone 的错误处理器。
                  Timer.run(() => throw StateError('Timer 错误示例'));
                },
                child: const Text('触发 Timer 回调错误'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
