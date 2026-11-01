import 'package:flutter/material.dart';

/// 1. 创建 InheritedWidget
class CounterInheritedWidget extends InheritedWidget {
  final int count;
  final void Function() increment;

  const CounterInheritedWidget({
    super.key,
    required this.count,
    required this.increment,
    required Widget child,
  }) : super(child: child);

  static CounterInheritedWidget of(BuildContext context) {
    final CounterInheritedWidget? result =
        context.dependOnInheritedWidgetOfExactType<CounterInheritedWidget>();
    assert(result != null, 'No CounterInheritedWidget found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(CounterInheritedWidget oldWidget) {
    // 当 count 变化时，子组件需要重新 build
    return count != oldWidget.count;
    // return false;
  }
}

/// 2. 外部容器 + 状态管理
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _count = 0;

  void _increment() => setState(() => _count++);

  @override
  Widget build(BuildContext context) {
    return CounterInheritedWidget(
      count: _count,
      increment: _increment,
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }
}

/// 3. 页面组件
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

int i = 0;

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final inherited = CounterInheritedWidget.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('InheritedWidget 示例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CounterDisplay(),
            //注意加const和去掉const区别，didupdateWidget：
            //didChangeDependencies总是会调，以为依赖修改了，CounterInheritedWidget调用了updateShouldNotify
            //添加 const，不会调用 didupdatewidget，去掉const 调用 didupdatewidget
            //用const：element superclass相同，widget相同（const常量 是同一个对象），直接用。所以无需调用didupdatewidget
            // element superclass相同，runtimeType相同，key相同（都为null）-》复用element、state，但是会调用 child.update(newWidget);即didupdatewidget
            CounterDisplayFullwidget(
              data: '$i',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: inherited.increment,
              child: const Text('增加'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  i++;
                });
              },
              child: const Text('增加--不改依赖组件'),
            ),
          ],
        ),
      ),
    );
  }
}

class CounterDisplayFullwidget extends StatefulWidget {
  String data;

  CounterDisplayFullwidget({super.key, required this.data});

  @override
  State<CounterDisplayFullwidget> createState() =>
      _CounterDisplayFullwidgetState();
}

// didChangeDependencies 比较适合监听 InheritedWidget 的变化；
//
// didUpdateWidget 更适合监听构造函数传参的变化；
//
// build() 是你访问最新数据的地方，但不要在里面做副作用（比如 setState）；
//
// 若组件没有用 of(context) 获取 InheritedWidget，则其不会触发 didChangeDependencies。
class _CounterDisplayFullwidgetState extends State<CounterDisplayFullwidget> {
  String? stateData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("_CounterDisplayFullwidgetState initState");
  }

  //依赖的 InheritedWidget 发生变化时会调用（即 of(context) 获取的依赖触发了 updateShouldNotify）
  //当需要根据 InheritedWidget 的变化做一些副作用或更新状态，比如获取新的依赖数据
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    var count = CounterInheritedWidget.of(context).count;
    print("_CounterDisplayFullwidgetState:didChangeDependencies:$count");
  }

  //父 Widget rebuild，导致当前 widget 被更新时（类型一致，key 一致，元素复用）
  //当你需要比较新旧 widget，做一些逻辑迁移，比如老值和新值不一样时更新 state
  @override
  void didUpdateWidget(covariant CounterDisplayFullwidget oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    print("_CounterDisplayFullwidgetState:didUpdateWidget");
    stateData = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    final count = CounterInheritedWidget.of(context).count;
    print('CounterDisplayFullwidget build 被调用了，count: $count');
    return Column(
      children: [
        Text(
          '当前计数：$count',
          style: const TextStyle(fontSize: 24),
        ),
        Text('widget.data=${widget.data}'),
        Text('state.data=${stateData}')
      ],
    );
  }
}

/// 4. 子组件，响应状态变化
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final count = CounterInheritedWidget.of(context).count;
    print('CounterDisplay build 被调用了，count: $count');
    return Text(
      '当前计数：$count',
      style: const TextStyle(fontSize: 24),
    );
  }
}
