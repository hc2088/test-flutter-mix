import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route vs Dialog Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RootPage(),
    );
  }
}

// 根容器，包含 BottomNavigationBar 和 IndexedStack
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SecondTabPage(), // 另一个 Tab 页面
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: '下载'),
        ],
      ),
    );
  }
}

// 另一个 tab 页
class SecondTabPage extends StatelessWidget {
  const SecondTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    print("📥 SecondTabPage build");
    return Scaffold(
      appBar: AppBar(title: const Text('下载页')),
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          ),
          child: const Text('This is another page'),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    print("🏠 _HomePageState initState");
  }
//  什么是「依赖的 InheritedWidget」？
//  并不是你上层树中有 InheritedWidget，就一定是“依赖”它。
//
//  只有在你调用了：
//

//  SomeInheritedWidget.of(context)
//  或者用了 context.dependOnInheritedWidgetOfExactType<SomeInheritedWidget>()，你才 依赖 它。
//
//  Flutter 会记录这个依赖关系。一旦这个被依赖的 InheritedWidget 更新了，
//  它就会通知所有依赖它的 widget 去调用 didChangeDependencies。
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    //真实用途
    //它的主要用途是获取 InheritedWidget（例如 Theme.of(context)、Localizations.of(context) 等）
    print("_HomePageState: didChangeDependencies");
  }

  @override
  Widget build(BuildContext context) {
    print("🏠 _HomePageState build");
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Counter: $counter', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showDialog,
              child: const Text('Show Dialog'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecondPage()),
                );
              },
              child: const Text('Go to New Page'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => counter++),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDialog() {
    //弹窗（Dialog）本质上是使用 Navigator.of(context).overlay.insert(...) 创建的一个 OverlayEntry。
    //Dialog 不在你当前页面的 widget 树上，但它仍然属于当前的 Navigator 管理的 overlay 栈。
    //这里的 Overlay 指的是：Navigator 内部全局维护的那个 Overlay。
    showDialog(
      context: context,
      builder: (ctx) {
        print("🪟 Dialog builder");
        return AlertDialog(
          title: const Text('Dialog Title'),
          content: const Text('This is a dialog'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    print("📄 SecondPage build");
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          ),
          child: const Text('This is another page'),
        ),
      ),
    );
  }
}
