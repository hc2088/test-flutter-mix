import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// 1. 创建一个继承自 InheritedWidget 的类
class MyInheritedWidget extends InheritedWidget {
  final String sharedData;
  final ValueChanged<String> onUpdate;

  MyInheritedWidget({
    Key? key,
    required this.sharedData,
    required this.onUpdate,
    required Widget child,
  }) : super(key: key, child: child);

  // 2. 用一个静态方法获取共享的数据
  static MyInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyInheritedWidget>();
  }

  @override
  bool updateShouldNotify(MyInheritedWidget oldWidget) {
    return sharedData != oldWidget.sharedData;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String sharedData = '初始状态';

  // 更新共享数据
  void updateSharedData(String newData) {
    setState(() {
      sharedData = newData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MyInheritedWidget(
        sharedData: sharedData,
        onUpdate: updateSharedData,
        child: MaterialApp(home: Page1()));
  }
}

class Page1 extends StatefulWidget {
  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  // ScrollController不保留状态，返回时列表会滚动回顶部
  final ScrollController _scrollController = ScrollController();
  String? _lastReturnedData;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print("_pagedidChangeDependencies:_Page1State ");
  }

  @override
  Widget build(BuildContext context) {
    print('Page1 build'); // 用于观察build调用次数

    final inheritedWidget = MyInheritedWidget.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Page1 列表')),
      body: Column(
        children: [
          if (_lastReturnedData != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Page2 返回数据: $_lastReturnedData'),
            ),
          Text('共享数据: ${inheritedWidget?.sharedData}'),
          ElevatedButton(
            onPressed: () {
              // 在 Page1 更新共享数据
              inheritedWidget?.onUpdate('Page1 最新的数据');
            },
            child: const Text('更新共享数据'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Page3()),
              );
            },
            child: const Text('跳转到 Page 3'),
          ),
          Expanded(
            child: ListView.builder(
              key: const PageStorageKey('page1ListView'),
              controller: _scrollController,
              itemCount: 100,
              itemBuilder: (_, index) {
                return ListTile(
                  title: Text('Item $index'),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Page2(data: '来自 Page1 的数据 $index'),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _lastReturnedData = result;
                      });
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  final String data;

  const Page2({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page2')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('收到 Page1 数据: $data'),
            const SizedBox(height: 20),

            // 1️⃣ Dialog
            ElevatedButton(
              child: const Text('显示 Dialog'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Dialog 示例'),
                    content: const Text('这是一个 Dialog 弹窗'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // 2️⃣ PopupMenu
            PopupMenuButton<String>(
              child: const ElevatedButton(
                  child: Text('显示 PopupMenu'), onPressed: null),
              onSelected: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('选择了 $value')),
                );
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: '选项1', child: Text('选项1')),
                const PopupMenuItem(value: '选项2', child: Text('选项2')),
              ],
            ),
            const SizedBox(height: 10),

            // 3️⃣ Tooltip
            Tooltip(
              message: '这是一个 Tooltip 提示',
              preferBelow: false,
              child: ElevatedButton(
                  child: const Text('长按显示 Tooltip'), onPressed: () {}),
            ),
            const SizedBox(height: 10),

            // 4️⃣ SnackBar
            ElevatedButton(
              child: const Text('显示 SnackBar'),
              onPressed: () {


              /*

              为什么它们用不同的 State?
                  Dialog → 全局路由层控制，由 Navigator 管理。
                  SnackBar → 页面 UI 控制，由 ScaffoldMessenger 管理。
              这种分离是 Flutter 设计的一部分：
                  Navigator 负责页面和弹窗级别的堆叠。
                  ScaffoldMessenger 负责 Scaffold 内部短暂提示（SnackBar、MaterialBanner 等）。
                */
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('这是一个 SnackBar')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Page3 extends StatefulWidget {
  @override
  _Page3State createState() => _Page3State();
}

class _Page3State extends State<Page3> {
  String newData = '';

  @override
  Widget build(BuildContext context) {
    final inheritedWidget = MyInheritedWidget.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Page 3")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  newData = value;
                });
              },
              decoration: const InputDecoration(labelText: '输入新数据'),
            ),
            ElevatedButton(
              onPressed: () {
                inheritedWidget?.onUpdate(newData);
                Navigator.pop(context); // 返回 Page1
              },
              child: const Text('更新数据并返回 Page1'),
            ),
            Text('当前输入的数据: $newData'),
          ],
        ),
      ),
    );
  }
}
