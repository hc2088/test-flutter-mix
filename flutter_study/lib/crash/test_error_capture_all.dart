import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter 异常与错误上报的统一学习示例。
///
/// 三个入口各有职责，不是三个对所有错误都生效的重复监听器：
/// - FlutterError.onError：接收通过 FlutterError.reportError 报告的错误。
///   包括 Flutter 框架捕获后报告的错误，也包括应用在 catch 中主动报告的错误。
/// - PlatformDispatcher.instance.onError：root isolate 的未处理错误入口。
///   只有错误未被 try-catch、Flutter 框架或负责它的 Zone 处理，并最终到达
///   root isolate 的未处理错误处理器时，才会调用它。
/// - runZonedGuarded.onError：处理受保护 error Zone 中未处理的异步错误，以及
///   body 同步抛出且未被捕获的错误。普通子 Zone 若与它共享 error Zone，
///   错误也可能由这个 handler 处理；嵌套的 runZonedGuarded 则通常由内层 handler 处理。
///
///
/// 三个入口最终都调用 _reportError。它们不会自动捕获已被 try/catch 处理的错误；
/// 子 isolate 也不会自动进入父 isolate 的 Zone。compute 会把错误放进调用方 Future，
/// 而 Isolate.spawn 需要通过 onError 端口把子 isolate 错误转回父 isolate。
/// 这些 Dart 处理器也不等于能捕获所有原生崩溃或进程被系统终止的情况。
void main() {
  // 在根 Zone 注册兜底处理器。应用代码放入 runZonedGuarded 后，
  // 这里可演示一个发生在 Zone.root 的错误如何到达 PlatformDispatcher。

  //在这里赋值onError，回调的 Zone.current是 ： flutter: Instance of '_RootZone'
  // PlatformDispatcher.instance.onError = _handlePlatformDispatcherError;

  runZonedGuarded<void>(() {
    // Binding 初始化和 runApp 必须处在同一个 Zone。
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = _handleFlutterError;

    //在这里赋值的，回调的Zone就是 这个子zone，flutter: Instance of '_CustomZone'
    PlatformDispatcher.instance.onError = _handlePlatformDispatcherError;
    runApp(const ErrorCaptureApp());
  }, _handleZoneError);
}

void _handleFlutterError(FlutterErrorDetails details) {
  // 自定义 FlutterError.onError 后，默认输出不会自动执行；显式保留它。
  // FlutterError.presentError(details);
  _reportError(
    source: 'FlutterError.onError',
    error: details.exception,
    stackTrace: details.stack ?? StackTrace.empty,
    // logToConsole: false,
  );
}

bool _handlePlatformDispatcherError(Object error, StackTrace stackTrace) {
  print(Zone.current);
  _reportError(
    source: 'PlatformDispatcher.instance.onError',
    error: error,
    stackTrace: stackTrace,
  );

  // 返回 true 表示错误已处理，避免再交给平台默认处理器输出。
  return true;
}

void _handleZoneError(Object error, StackTrace stackTrace) {
  _reportError(
    source: 'runZonedGuarded.onError',
    error: error,
    stackTrace: stackTrace,
  );
}

void _reportError({
  required String source,
  required Object error,
  required StackTrace stackTrace,
  bool fatal = true,
  bool logToConsole = true,
}) {
  if (logToConsole) {
    final severity = fatal ? 'fatal' : 'non-fatal';
    debugPrint('[$source][$severity] $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // 项目尚未配置 firebase_crashlytics。接入后可在这里统一上报，例如：
  // unawaited(FirebaseCrashlytics.instance.recordError(
  //   error,
  //   stackTrace,
  //   reason: source,
  //   fatal: fatal,
  // ));
}

Future<void> _throwFromCompute(String message) async {
  await Future<void>.delayed(Duration.zero);
  throw StateError('compute 子 isolate 错误：$message');
}

void _throwFromSpawnedIsolate(String message) {
  throw StateError('Isolate.spawn 子 isolate 错误：$message');
}

Future<void> _startSpawnedIsolateErrorDemo() async {
  late final RawReceivePort errorPort;
  errorPort = RawReceivePort((dynamic message) {
    errorPort.close();

    final pair = message as List<dynamic>;
    final errorText = pair[0] as String;
    final stackText = pair[1] as String?;
    final remoteError = RemoteError(errorText, stackText ?? '');

    _reportError(
      source: 'Isolate.spawn.onError',
      error: remoteError,
      stackTrace: remoteError.stackTrace,
    );
  });

  try {
    await Isolate.spawn<String>(
      _throwFromSpawnedIsolate,
      '未处理异常',
      onError: errorPort.sendPort,
    );
  } catch (error, stackTrace) {
    errorPort.close();
    _reportError(
      source: 'Isolate.spawn 启动失败',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class ErrorCaptureApp extends StatelessWidget {
  const ErrorCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter 错误捕获示例')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton(
              onPressed: () {
                // 模拟 Flutter 框架向 FlutterError.onError 报告错误。
                FlutterError.reportError(
                  FlutterErrorDetails(
                    exception: StateError('Flutter 框架错误示例'),
                    library: 'test_error_capture_all.dart',
                  ),
                );
              },
              child: const Text('FlutterError.onError'),
            ),
            ElevatedButton(
              onPressed: () {
                // 在根 Zone 中安排 Timer，演示 PlatformDispatcher 兜底入口。
                Zone.root.run(() {
                  Timer.run(
                    () => throw StateError('PlatformDispatcher 错误示例'),
                  );
                });
              },
              child: const Text('PlatformDispatcher.instance.onError'),
            ),
            ElevatedButton(
              onPressed: () {
                // 同步 body 错误由 runZonedGuarded 直接交给 onError。
                runZonedGuarded<void>(
                  () => throw StateError('Zone 同步错误示例'),
                  _handleZoneError,
                );
              },
              child: const Text('runZonedGuarded 同步错误'),
            ),
            ElevatedButton(
              onPressed: () {
                // Timer 在按钮回调所在的 Zone 中安排；未处理的回调错误进入 Zone onError。
                Timer.run(() => throw StateError('Zone Timer 错误示例'));
              },
              child: const Text('Zone 中的 Timer 错误'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 按钮不会等待这个 Future；未处理的 Future 错误进入当前 Zone。
                await Future<void>.delayed(Duration.zero);
                throw StateError('按钮异步回调错误示例');
              },
              child: const Text('Zone 中的 Future 错误'),
            ),
            ElevatedButton(
              onPressed: () {
                // 原生平台在子 isolate 运行；compute 把错误作为 Future 错误传回。
                // Web 平台在当前事件循环运行 callback。
                unawaited(compute<String, void>(_throwFromCompute, 'compute'));
              },
              child: const Text('compute 子 isolate 错误'),
            ),
            ElevatedButton(
              onPressed: () => unawaited(_startSpawnedIsolateErrorDemo()),
              child: const Text('Isolate.spawn 错误（显式错误端口）'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  throw StateError('已捕获的异常示例');
                } catch (error, stackTrace) {
                  // 已被 try/catch 捕获的异常不会自动进入全局处理器，需主动上报。
                  _reportError(
                    source: 'try/catch',
                    error: error,
                    stackTrace: stackTrace,
                    fatal: false,
                  );
                }
              },
              child: const Text('捕获后主动上报（non-fatal）'),
            ),
            ElevatedButton(
              onPressed: () async {
                const channel = MethodChannel('crashy-custom-channel');
                await channel.invokeMethod<void>('blah');
              },
              child: const Text('MethodChannel Future 错误'),
            ),
          ],
        ),
      ),
    );
  }
}
