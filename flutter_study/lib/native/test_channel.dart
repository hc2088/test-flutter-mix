import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NativeBridge.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NativeChannelDemo Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NativeChannelDemo(),
    );
  }
}

class NativeChannelDemo extends StatefulWidget {
  const NativeChannelDemo({super.key});

  @override
  State<NativeChannelDemo> createState() => _NativeChannelDemoState();
}

class _NativeChannelDemoState extends State<NativeChannelDemo> {
  String _nativeMessage = "还没有收到 iOS 消息";

  @override
  void initState() {
    super.initState();
    NativeBridge.init(onMessage: (msg) {
      setState(() {
        _nativeMessage = msg;
      });
    });
  }

  Future<void> _requestNativeMessage() async {
    final msg = await NativeBridge.getNativeMessage();
    setState(() {
      _nativeMessage = msg ?? "Native 返回空消息";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NativeBridge Demo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("来自 Native 的消息：",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              _nativeMessage,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestNativeMessage,
              child: const Text("向 iOS 请求消息"),
            ),
          ],
        ),
      ),
    );
  }
}
