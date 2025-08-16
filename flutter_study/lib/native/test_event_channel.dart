import 'package:flutter/material.dart';

import 'native_bridge.dart';
import 'native_event_bridget.dart';
/*
*
*
* 设计思路总结

MethodChannel

  适合 请求-响应模式

  Flutter 主动 → Native 执行 → 返回结果

  举例：获取电池电量、拍照、打开相机、获取文件路径

EventChannel

  适合 订阅事件流

  Native 主动 → Flutter 订阅 → 响应事件

  举例：加速度传感器数据、地理位置更新、网络状态变化、下载进度

组合使用场景

    Flutter 发送请求给 Native 开始某个操作（MethodChannel）

    Native 在操作过程中持续推送状态给 Flutter（EventChannel）


Tip：EventChannel 的流是 持续的、异步的，不要用它来做单次请求，否则 MethodChannel 更直观。
* **/
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NativeChannelDemo Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: EventChannelDemo(),
    );
  }
}

class EventChannelDemo extends StatefulWidget {
  const EventChannelDemo({super.key});

  @override
  State<EventChannelDemo> createState() => _EventChannelDemoState();
}

class _EventChannelDemoState extends State<EventChannelDemo> {
  String _lastEvent = "还没有收到 Native 事件";

  @override
  void initState() {
    super.initState();
    NativeEventBridge.events.listen((event) {
      setState(() {
        _lastEvent = event.toString();
      });
    }, onError: (error) {
      setState(() {
        _lastEvent = "发生错误: $error";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EventChannel Demo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("来自 iOS 的实时事件流:"),
            const SizedBox(height: 12),
            Text(
              _lastEvent,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            const ElevatedButton(
              onPressed: _sendMessageToNative,
              child: Text('发送消息给Native'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _sendMessageToNative() async {
  final result = await NativeBridge.getNativeMessage();
  print('Native返回: $result');
}
