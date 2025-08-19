import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. 创建一个状态管理类，继承 ChangeNotifier
class SharedData with ChangeNotifier {
  String _data = '初始状态';

  String get data => _data;

  // 更新状态并通知依赖的 Widget
  void updateData(String newData) {
    _data = newData;
    notifyListeners();
  }
}

void main() {
  runApp(
    // 2. 使用 ChangeNotifierProvider 来提供共享状态
    ChangeNotifierProvider(
      create: (context) => SharedData(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Page1(),
    );
  }
}

class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 3. 使用 Provider 获取共享状态
    final sharedData = Provider.of<SharedData>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Page 1")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('共享数据: ${sharedData.data}'),
            ElevatedButton(
              onPressed: () {
                // 在 Page1 更新共享数据
                sharedData.updateData('Page1 最新的数据');
              },
              child: const Text('更新共享数据'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Page2()),
                );
              },
              child: const Text('跳转到 Page 2'),
            ),
          ],
        ),
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 4. 使用 Provider 获取共享状态
    final sharedData = Provider.of<SharedData>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Page 2")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onChanged: (value) {
                // 在 Page2 修改共享数据
                sharedData.updateData(value);
              },
              decoration: const InputDecoration(labelText: '输入新数据'),
            ),
            ElevatedButton(
              onPressed: () {
                // 返回到 Page1
                Navigator.pop(context);
              },
              child: const Text('返回到 Page 1'),
            ),
            Text('当前输入的数据: ${sharedData.data}'),
          ],
        ),
      ),
    );
  }
}
