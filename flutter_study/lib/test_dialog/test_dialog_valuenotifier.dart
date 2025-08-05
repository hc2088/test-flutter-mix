import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

// 全局共享的 ValueNotifier
final ValueNotifier<int> counterNotifier = ValueNotifier<int>(0);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValueNotifier 跨组件示例',
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
        // StatefulBuilder 用于局部刷新 Dialog 内部状态
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Counter Dialog'),
              content: ValueListenableBuilder<int>(
                valueListenable: counterNotifier,
                builder: (context, value, child) {
                  return Text('Counter value: $value');
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // 这里演示在 dialog 里修改 ValueNotifier 的值
                    counterNotifier.value++;
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
        title: Text('ValueNotifier 跨组件 + Dialog 示例'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ValueListenableBuilder<int>(
              valueListenable: counterNotifier,
              builder: (context, value, child) {
                return Text(
                  'Counter value in main page: $value',
                  style: TextStyle(fontSize: 20),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showCounterDialog(context),
              child: Text('Show Counter Dialog'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 外部页面也能修改共享的 counter
                counterNotifier.value++;
              },
              child: Text('Increment from main page'),
            ),
          ],
        ),
      ),
    );
  }
}
