import 'package:flutter/material.dart';

void main() {
  runApp(
    Builder(
      builder: (context) {
        final mqBuilder = MediaQuery.of(context);
        print('Builder MediaQuery hash = ${mqBuilder.hashCode}');
        return MyApp(mediaQueryHashFromBuilder: mqBuilder.hashCode);
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  final int mediaQueryHashFromBuilder;

  const MyApp({super.key, required this.mediaQueryHashFromBuilder});

  @override
  Widget build(BuildContext context) {
    //从 Flutter 3.7.0-29.0.pre 起，MaterialApp 不再自行创建 MediaQuery，
    // 而是依赖 Flutter 框架底层的 View 组件 来提供 MediaQuery 数据。View 会在更底层对屏幕信息进行监听并注入 MediaQuery。

    //之前（旧版本）：
    // MaterialApp 会在内部包裹一个新的 MediaQuery。
    //
    // 这样你可能会在 runApp() 的外部 context 与 MaterialApp 内部获取两个不同的 MediaQuery。
    //
    // 现在（3.7+）：
    //
    // 统一由 View 控制，避免嵌套的 MediaQuery。
    //
    // 提高性能，也减少误用。
    return const MaterialApp(
      useInheritedMediaQuery: false,
      home: LayoutMetricsPage(),
    );
  }
}

class LayoutMetricsPage extends StatelessWidget {
  const LayoutMetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mqLayout = MediaQuery.of(context);
    print('LayoutMetricsPage MediaQuery hash = ${mqLayout.hashCode}');
    print('Are they identical? ${identical(mqLayout, MediaQuery.of(context))}');
    return Scaffold(
      appBar: AppBar(title: const Text('MediaQuery 对比')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Builder hash and layout hash printed in console'),
            Text('Hash layout: ${mqLayout.hashCode}'),
          ],
        ),
      ),
    );
  }
}
