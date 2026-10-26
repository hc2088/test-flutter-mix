import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Dart 并发与事件循环：
// - async/Future/Timer 不会创建 isolate；主 isolate 上的同步耗时计算仍会卡住 UI。
// - Isolate.spawn 自建 worker 并用端口通信；Isolate.run 和 compute 用于一次性计算；spawnUri 从 Dart 文件启动。
//   compute 在原生平台运行于新 isolate，在 Web 上仍运行于当前 event loop。
// - 每个 isolate 有自己的内存和事件循环：同步代码 → 清空微任务 → 处理下一个 event。
//   微任务：scheduleMicrotask、Future.microtask、已完成 Future 的 then 回调。
//   Future.sync 的计算函数立即执行，不属于微任务；Future(computation)、Timer.run、I/O 和 UI 输入走 event。

RawReceivePort? _currentIsolateErrorPort;

// 声明在各 isolate 中都可见；late 的值彼此独立，子 isolate 读取前也要自己赋值。
late String str;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter 框架捕获的错误（如 build、layout、paint）从这里输出并上报。
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack ?? StackTrace.empty);
  };
  str = 'aaa'; // 这是主 isolate 的值。
  // 未处理的 Future 异常由此入口上报；当前注释时不会调用 _reportError。
  PlatformDispatcher.instance.onError = _reportError;

  // 启动时自动注册当前 isolate 的错误端口，不需要用户操作。
  _registerCurrentIsolateErrorListener();

  runApp(const MyApp());
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
    _reportIsolateError(message);
  });

  _currentIsolateErrorPort = port;
  // 向 VM 注册当前 isolate 的错误端口；该 isolate 的未捕获错误会发到此 port。
  Isolate.current.addErrorListener(port.sendPort);
}

void _reportIsolateError(dynamic message) {
  // VM 消息包含错误文本和堆栈文本；RawReceivePort handler 在 Zone.root 中运行。
  final pair = message as List<dynamic>;
  final errorText = pair[0] as String;
  final stackText = pair[1] as String?;
  final remoteError = RemoteError(errorText, stackText ?? '');
  _reportError(remoteError, remoteError.stackTrace);
}

Future<void> _startChildIsolateErrorDemo() async {
  late final RawReceivePort errorPort;
  errorPort = RawReceivePort((dynamic message) {
    _reportIsolateError(message);
    errorPort.close();
  });

  try {
    // 子 isolate 不会自动转到根 isolate；每次 spawn 都要单独传 onError。
    await Isolate.spawn<String>(
      _simulateChildIsolateBusinessError,
      '子 isolate 业务异常',
      onError: errorPort.sendPort,
    );
  } catch (error, stackTrace) {
    errorPort.close();
    _reportError(error, stackTrace);
  }
}

void _simulateChildIsolateBusinessError(String message) {
  // 模拟子 isolate 执行业务逻辑时发生未捕获异常，由 spawn 的 onError 转回父 isolate。
  debugPrint(
      str); //这里确实会发生异常了:LateInitializationError: Field 'str' has not been initialized.
  str = '123123'; //执行不到这里， 这是子 isolate 自己的值，不会改动主 isolate 的 str。
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
                  // 启用 PlatformDispatcher 注册后，此 Future 错误才会调用 _reportError。
                  await Future<void>.delayed(Duration.zero);
                  throw StateError('异步回调错误示例');
                },
                child: const Text('Future 未捕获异常（PlatformDispatcher）'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Timer 回调异常由当前 isolate 的 VM 错误端口收到。
                  Timer.run(() => throw StateError('Timer 错误示例'));
                },
                child: const Text('触发 Isolate.current 监听（Timer）'),
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    throw StateError('已捕获的异常示例');
                  } catch (error, stackTrace) {
                    // try/catch 捕获的异常需主动上报。
                    _reportError(error, stackTrace);
                  }
                },
                child: const Text('触发并上报已捕获异常'),
              ),
              ElevatedButton(
                onPressed: () => unawaited(_startChildIsolateErrorDemo()),
                child: const Text('触发子 isolate 错误'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*

1、上报未捕获异常： FlutterError.onError ，  自动捕获 Flutter 框架中抛出的所有“致命”错误

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };


2、Flutter 框架不会捕获异步错误，要捕获这类错误，可以使用 PlatformDispatcher.instance.onError 处理器：

    // 将未被 Flutter 框架处理的未捕获异步错误交给 Crashlytics。
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };


3、Flutter 上下文之外的错误： 要捕获 Flutter 上下文之外发生的错误，可以为当前 Isolate 注册错误监听器：

    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      await FirebaseCrashlytics.instance.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last,
        fatal: true,
      );
    }).sendPort);


 */
