import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('ValueNotifier 示例')),
        body: Center(
          child: ValueListenableBuilder<int>(
            valueListenable: counter,
            builder: (context, value, child) {
              return Text('当前计数：$value', style: TextStyle(fontSize: 24));
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => counter.value++,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
