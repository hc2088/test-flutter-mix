import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// 定义一个 State 对象，用于给 GlobalKey 标记
class CounterItem extends StatefulWidget {
  const CounterItem({super.key, required this.index});

  final int index;

  @override
  State<CounterItem> createState() => _CounterItemState();
}

class _CounterItemState extends State<CounterItem> {
  int _count = 0;

  /// 公开一个方法，用于外部调用更新 UI
  void increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Item ${widget.index}'),
      subtitle: Text('Count: $_count'),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 创建 GlobalKey 列表，管理每个 item 的 state
  static final List<GlobalKey<_CounterItemState>> _itemKeys = List.generate(
    10,
    (_) => GlobalKey<_CounterItemState>(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('控制特定 ListView Item')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // 点击按钮后，只更新第 3 个 item（索引为 2）
              _itemKeys[2].currentState?.increment();
            },
            child: const Text('更新第 3 个 Item'),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _itemKeys.length,
              itemBuilder: (context, index) {
                return CounterItem(
                  key: _itemKeys[index], // 将 key 传入每个 item
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
