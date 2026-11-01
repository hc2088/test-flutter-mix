import 'dart:async';

import 'package:flutter/material.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(details.exception, details.stack!);
  };

  runZonedGuarded(() {
    runApp(
      const MaterialApp(
        home: const HomePage(),
      ),
    );
  }, (Object error, StackTrace stackTrace) {
    print('捕获到未处理异常：$error');
  });
  // runApp(
  //   const MaterialApp(
  //     home: const HomePage(),
  //   ),
  // );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("首页")),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              child: const Text("打开 FutureBuilder 页面"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FutureBuilderDemo()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("打开 FutureBuilder 页面----普通的不处理"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyWidget(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FutureBuilderDemo extends StatefulWidget {
  const FutureBuilderDemo({super.key});

  @override
  State<FutureBuilderDemo> createState() => _FutureBuilderDemoState();
}

class _FutureBuilderDemoState extends State<FutureBuilderDemo> {
  Future<String> _loadData() async {
    await Future.delayed(const Duration(seconds: 10));
    print("数据加载完成并返回");
    return "数据加载完成";
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print("_FutureBuilderDemoState dispose");
  }

  @override
  Widget build(BuildContext context) {
    print("FutureBuilderDemo build");

    return Scaffold(
      appBar: AppBar(title: const Text("FutureBuilder 页面")),
      body: Center(
        // FutureBuilder 的内部实际上会通过 _activeCallbackIdentity（一个唯一的 ID）来绑定当前 future，确保：
        //
        //    1、如果 FutureBuilder 被重建（如页面 pop），则旧的 future 结果将被丢弃，不再触发 setState。
        //
        //    2、如果 State 已经被销毁（即 dispose() 调用过），则也不会触发 setState。
        child: FutureBuilder<String>(
          future: _loadData(),
          builder: (context, snapshot) {
            print("FutureBuilder snapshot: ${snapshot.connectionState}");
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("出错了: ${snapshot.error}");
            } else if (snapshot.hasData) {
              return Text(snapshot.data!);
            } else {
              return const Text("无数据");
            }
          },
        ),
      ),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool _isDisposed = false;
  String _data = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(Duration(seconds: 10));
    print("数据加载完成");
    //if (_isDisposed) return; // 避免更新已销毁的组件
    //if (!mounted) return;

    //推荐使用 mounted 而不是自己维护 _isDisposed 变量。
    setState(() {
      //不会崩溃，但是会产生UI异常
      //[ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: setState() called after dispose():
      // _MyWidgetState#3acc8(lifecycle state: defunct, not mounted)
      _data = "Data Loaded";
    });
  }

  @override
  void dispose() {
    print("_MyWidgetState dispose");
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("普通dipose测试 页面")),
      body: Center(child: Text(_data)),
    );
  }
}
