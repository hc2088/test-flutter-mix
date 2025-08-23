import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: const HomePage(), // 首页：用于跳转详情页
      getPages: [
        // 配置命名路由：两个详情页共用同一路由名和页面类
        GetPage(name: '/detail', page: () => const DetailPage()),
      ],
    );
  }
}

// 首页：跳转到详情页的入口
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Get.toNamed('/detail', arguments: {'id': 1}),
          // 跳转到第一个详情页
          child: const Text('打开详情页1'),
        ),
      ),
    );
  }
}

// 详情页：包含计数器组件，两个详情页共用这个类
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map; // 获取路由参数（区分不同详情页）
    return Scaffold(
      appBar: AppBar(title: Text('详情页${args['id']}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CounterWidget(), // 计数器组件（关键：未设置key）
            const SizedBox(height: 20),
            // 跳转到第二个详情页的按钮（仅在第一个详情页显示）
            // if (args['id'] == 1)
            ElevatedButton(
              onPressed: () => Get.toNamed('/detail',
                  arguments: {'id': 2}, preventDuplicates: false),
              child: const Text('跳转到详情页2'),
            ),


            //使用offNamed 和  toNamed 都没有发现 CounterWidget element复用的现象
            ElevatedButton(
              onPressed: () => Get.offNamed('/detail',
                  arguments: {'id': 2}, preventDuplicates: false),
              child: const Text('跳转到详情页2--offnamed'),
            ),
          ],
        ),
      ),
    );
  }
}

// 计数器组件：未设置key，导致状态可能被复用
class CounterWidget extends StatefulWidget {
  // 注意：这里没有设置key，是状态污染的核心原因
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0; // 计数器状态
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("_CounterWidgetState initState");
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print("_CounterWidgetState didChangeDependencies");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('计数器：$_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++), // 点击递增
          child: const Text('+1'),
        ),
      ],
    );
  }
}
