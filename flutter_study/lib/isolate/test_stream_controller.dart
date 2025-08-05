import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream 输入监听示例',
      home: InputStreamPage(),
    );
  }
}

class InputStreamPage extends StatefulWidget {
  @override
  _InputStreamPageState createState() => _InputStreamPageState();
}

//yield 是语法糖，用于 async* / sync* 函数中，帮助你像写普通代码一样“逐个发值”；
// 而 StreamController 是手动控制数据流的工具，用 .add() 发值，不需要 yield。
class _InputStreamPageState extends State<InputStreamPage> {
  //StreamController.add() 不是通过 yield 发数据，而是通过回调通知已注册的 listener，
  // 这就是“外部触发内部像 yield 一样发数据”的本质。
  final StreamController<String> _inputController =
      StreamController<String>.broadcast();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 监听输入流
    _inputController.stream.listen((input) {
      print("用户输入：$input");
    });
  }

  @override
  void dispose() {
    _inputController.close();
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    //添加数据的标准接口。
    //_inputController.sink.add(text); // 推送输入到 stream
    //语法糖，等价于 .sink.add()。
    _inputController.add(text); // 推送输入到 stream
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stream 输入监听')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              onChanged: _onTextChanged,
              decoration: InputDecoration(labelText: '请输入文字'),
            ),
            SizedBox(height: 20),
            StreamBuilder<String>(
              stream: _inputController.stream,
              builder: (context, snapshot) {
                return Text('你输入的是: ${snapshot.data ?? ""}');
              },
            )
          ],
        ),
      ),
    );
  }
}
