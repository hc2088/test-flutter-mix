import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Page1());
  }
}

class Page1 extends StatefulWidget {
  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  // ScrollController不保留状态，返回时列表会滚动回顶部
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Page1 build'); // 用于观察build调用次数
    return Scaffold(
      appBar: AppBar(title: Text('Page1 列表')),
      body: ListView.builder(
        //类型相同、key相同、value相同
        key: PageStorageKey('page1ListView'),

        controller: _scrollController,
        itemCount: 100,
        itemBuilder: (_, index) {
          return ListTile(
            title: Text('Item $index'),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => Page2()));

              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (_) => Page2()),
              // );
            },
          );
        },
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page2')),
      body: Center(
        child: ElevatedButton(
          child: Text('返回'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
