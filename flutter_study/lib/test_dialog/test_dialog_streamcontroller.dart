import 'dart:async';

import 'package:flutter/material.dart';
//Dialog 是在 Navigator 上新开了一个路由（OverlayEntry），不会导致 HomePage 的依赖变化或状态更新，
// 因此它不会触发 didChangeDependencies()。
// Flutter 的 Dialog 是通过 Navigator.push 插入到新的 Route 中。
//
// 如果要刷新 Dialog 内部状态，可以使用 StatefulBuilder 提供 setState，局部更新。
//
// 也可以使用外部状态管理（比如 ValueNotifier / StreamBuilder）。
//
// 典型场景如“加载进度”、“结果提示”、“确认流程”等需要实时更新内容。
void main() {
  runApp(MyApp());
}

// 全局共享的 StreamController，广播流，方便多监听
final StreamController<int> counterStreamController =
    StreamController<int>.broadcast();

int counter = 0; // 计数器状态，手动维护

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream 跨组件刷新示例',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  // _HomePageState.didChangeDependencies() 不会在打开或关闭 Dialog 时触发，因为：
  //
  // Dialog 是在 Navigator 上新开了一个路由（OverlayEntry），不会导致 HomePage 的依赖变化或状态更新，
  // 因此它不会触发 didChangeDependencies()。

  // didChangeDependencies() 是 Flutter 为了响应 依赖于 InheritedWidget 的变化 提供的生命周期钩子，
  // 比如 MediaQuery.of(context)、Theme.of(context)、Localizations.of(context)。
  //
  // 而 Dialog 的打开不会修改依赖上下文，也不会 rebuild 当前页面的 Widget Tree，因此它不会触发。

  // | 场景                        | 是否调用       |
  // | ------------------------- | ---------- |
  // | Widget 第一次插入到树中           | ✅ 会调用一次    |
  // | `InheritedWidget` 相关依赖更新时 | ✅ 会再次调用    |
  // | 打开 / 关闭 Dialog（Overlay）   | ❌ **不会调用** |
  // | 调用 `setState`             | ❌ 不会调用     |
  // | 父 Widget rebuild 且依赖变化    | ✅ 有可能调用    |

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print("_HomePageState: didChangeDependencies");
  }

  void _showCounterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // 这里用 StreamBuilder 监听全局流，实现弹窗UI刷新
        return StreamBuilder<int>(
          stream: counterStreamController.stream,
          initialData: counter,
          builder: (context, snapshot) {
            final value = snapshot.data ?? 0;
            return AlertDialog(
              title: Text('Counter Dialog'),
              content: Text('Counter value: $value'),
              actions: [
                TextButton(
                  onPressed: () {
                    counter++;
                    counterStreamController.sink.add(counter);
                  },
                  child: Text('Increment'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('HomePage build');
    return Scaffold(
      appBar: AppBar(
        title: Text('Stream 跨组件刷新示例'),
      ),
      body: Center(
        child: StreamBuilder<int>(
          stream: counterStreamController.stream,
          initialData: counter,
          builder: (context, snapshot) {
            final value = snapshot.data ?? 0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Counter value in main page: $value',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showCounterDialog(context),
                  child: Text('Show Counter Dialog'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    counter++;
                    counterStreamController.sink.add(counter);
                  },
                  child: Text('Increment from main page'),
                ),
                ElevatedButton(
                  onPressed: () {
                    showRefreshableDialog(context);
                  },
                  child: Text('showRefreshableDialog-StatefulBuilder'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void showRefreshableDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isDone = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('任务处理'),
              content: isDone
                  ? Text('任务已完成 ✅')
                  : Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('处理中...'),
                      ],
                    ),
              actions: [
                if (!isDone)
                  TextButton(
                    child: Text('完成任务'),
                    onPressed: () {
                      // 模拟异步任务完成
                      Future.delayed(Duration(seconds: 1), () {
                        setState(() {
                          isDone = true;
                        });
                      });
                    },
                  ),
                if (isDone)
                  TextButton(
                    child: Text('关闭'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
