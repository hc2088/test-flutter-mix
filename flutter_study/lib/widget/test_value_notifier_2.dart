import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// 应用入口
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestPage(),
    );
  }
}

// 页面 Widget
class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  // 使用 ValueNotifier 管理局部状态
  //值通知器
  final ValueNotifier<String> _text1 = ValueNotifier('');
  final ValueNotifier<String> _text2 = ValueNotifier('');

  @override
  void dispose() {
    _text1.dispose();
    _text2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("局部刷新示例")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(labelText: '输入框1'),
            onChanged: (value) => _text1.value = value,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: '输入框2'),
            onChanged: (value) => _text2.value = value,
          ),
          const SizedBox(height: 16),

          // 只监听 text1
          ValueListenableBuilder<String>(
            valueListenable: _text1,
            builder: (context, value, _) {
              print("刷新文本1");
              return Text('文本1: $value');
            },
          ),
          const SizedBox(height: 16),

          // 只监听 text2
          ValueListenableBuilder<String>(
            valueListenable: _text2,
            builder: (context, value, _) {
              print("刷新文本2");
              return Text('文本2: $value');
            },
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {},
            child: const Text("其他组件"),
          ),
        ],
      ),
    );
  }
}
